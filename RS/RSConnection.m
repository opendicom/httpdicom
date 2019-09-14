#import "RSConnection.h"

#import <netdb.h>
#import "RFC822.h"
#import "ODLog.h"
#import "NSString+PCS.h"

#define kHeadersReadCapacity (1 * 1024)
#define kBodyReadCapacity (256 * 1024)

static NSData* _CRLFData = nil;
static NSData* _CRLFCRLFData = nil;
static NSData* _continueData = nil;
static NSData* _lastChunkData = nil;
static NSArray *_handlers = nil;

@implementation RSConnection

//@synthesize server=_server;
@synthesize localAddressData=_localAddress;
@synthesize remoteAddressData=_remoteAddress;
//@synthesize totalBytesRead=_bytesRead;
//@synthesize totalBytesWritten=_bytesWritten;

#pragma mark -

+ (void)initialize {
  if (_CRLFData == nil) {
    _CRLFData = [[NSData alloc] initWithBytes:"\r\n" length:2];
  }
  if (_CRLFCRLFData == nil) {
    _CRLFCRLFData = [[NSData alloc] initWithBytes:"\r\n\r\n" length:4];
  }
  if (_continueData == nil) {
    CFHTTPMessageRef message = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 100, NULL, kCFHTTPVersion1_1);
    _continueData = CFBridgingRelease(CFHTTPMessageCopySerializedMessage(message));
    CFRelease(message);
  }
  if (_lastChunkData == nil) {
    _lastChunkData = [[NSData alloc] initWithBytes:"0\r\n\r\n" length:5];
  }
}

+ (void)setHandlers:(NSArray*)handlers
{
    _handlers=handlers;
}

#pragma mark -

- (void)_startProcessingRequest {
    // https://tools.ietf.org/html/rfc2617
    
    LOG_VERBOSE(@"Connection on socket %i processing request \"%@ %@\" with %lu bytes body", _socket, _request.method, _request.path, (unsigned long)_bytesRead);
    @try {
          _handler.processBlock(
            _request,
            [^(RSResponse* processResponse){[self _finishProcessingRequest:processResponse];} copy]
          );
    }
    @catch (NSException* exception) {
        LOG_EXCEPTION(exception);
    }
 }

// http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
- (void)_finishProcessingRequest:(RSResponse*)response {
  BOOL hasBody = NO;
  
  if (response) {
    if ([response hasBody]) {
      [response prepareForReading];
      hasBody = YES;
    }
    NSError* error = nil;
    if (hasBody && ![response performOpen:&error]) {
      LOG_ERROR(@"Failed opening response body for socket %i: %@", _socket, error);
    } else {
      _response = response;
    }
  }
  
  if (_response) {
       _statusCode = _response.statusCode;
      _responseMessage = CFHTTPMessageCreateResponse(kCFAllocatorDefault, _statusCode, NULL, kCFHTTPVersion1_1);
      CFHTTPMessageSetHeaderFieldValue(_responseMessage, CFSTR("Connection"), CFSTR("Close"));
      CFHTTPMessageSetHeaderFieldValue(_responseMessage, CFSTR("Server"), CFSTR("httpdicom"));
      CFHTTPMessageSetHeaderFieldValue(_responseMessage, CFSTR("Date"), (__bridge CFStringRef)[RFC822 stringFromDate:[NSDate date]]);

    if (_response.lastModifiedDate) {
      CFHTTPMessageSetHeaderFieldValue(_responseMessage, CFSTR("Last-Modified"), (__bridge CFStringRef)[RFC822 stringFromDate:_response.lastModifiedDate]);
    }
    if (_response.eTag) {
      CFHTTPMessageSetHeaderFieldValue(_responseMessage, CFSTR("ETag"), (__bridge CFStringRef)_response.eTag);
    }
    if ((_response.statusCode >= 200) && (_response.statusCode < 300)) {
      if (_response.cacheControlMaxAge > 0) {
        CFHTTPMessageSetHeaderFieldValue(_responseMessage, CFSTR("Cache-Control"), (__bridge CFStringRef)[NSString stringWithFormat:@"max-age=%i, public", (int)_response.cacheControlMaxAge]);
      } else {
        CFHTTPMessageSetHeaderFieldValue(_responseMessage, CFSTR("Cache-Control"), CFSTR("no-cache"));
      }
    }
    if (_response.contentType != nil) {
      CFHTTPMessageSetHeaderFieldValue(_responseMessage, CFSTR("Content-Type"), (__bridge CFStringRef)[_response.contentType normalizeHeaderValue]);
    }
    if (_response.contentLength != NSUIntegerMax) {
      CFHTTPMessageSetHeaderFieldValue(_responseMessage, CFSTR("Content-Length"), (__bridge CFStringRef)[NSString stringWithFormat:@"%lu", (unsigned long)_response.contentLength]);
    }
    if (_response.usesChunkedTransferEncoding) {
      CFHTTPMessageSetHeaderFieldValue(_responseMessage, CFSTR("Transfer-Encoding"), CFSTR("chunked"));
    }
    [_response.additionalHeaders enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
      CFHTTPMessageSetHeaderFieldValue(_responseMessage, (__bridge CFStringRef)key, (__bridge CFStringRef)obj);
    }];
    [self _writeHeadersWithCompletionBlock:^(BOOL success) {
      
      if (success) {
        if (hasBody) {
          [self _writeBodyWithCompletionBlock:^(BOOL successInner) {
            
            [self->_response performClose];  // TODO: There's nothing we can do on failure as headers have already been sent
            
          }];
        }
      } else if (hasBody) {
        [self->_response performClose];
      }
      
    }];
  } else {
    [self abortRequest:_request withStatusCode:500];//InternalServerError
  }
  
}


- (void)abortRequest:(RSRequest*)request withStatusCode:(NSInteger)statusCode
{
    _statusCode = _response.statusCode;
    _responseMessage = CFHTTPMessageCreateResponse(kCFAllocatorDefault, _statusCode, NULL, kCFHTTPVersion1_1);
    CFHTTPMessageSetHeaderFieldValue(_responseMessage, CFSTR("Connection"), CFSTR("Close"));
    CFHTTPMessageSetHeaderFieldValue(_responseMessage, CFSTR("Server"), CFSTR("httpdicom"));
    CFHTTPMessageSetHeaderFieldValue(_responseMessage, CFSTR("Date"), (__bridge CFStringRef)[RFC822 stringFromDate:[NSDate date]]);
    
    [self _writeHeadersWithCompletionBlock:^(BOOL success) {
        ;  // Nothing more to do
    }];
    LOG_DEBUG(@"Connection aborted with status code %i on socket %i", (int)statusCode, _socket);
}

- (void)dealloc {
    int result = close(_socket);
    if (result != 0) {
        LOG_ERROR(@"Failed closing socket %i for connection: %s (%i)", _socket, strerror(errno), errno);
    } else {
        LOG_DEBUG(@"Did close connection on socket %i", _socket);
    }
    if (_request) {
        LOG_VERBOSE(@"[%@] %@ %i \"%@ %@\" (%lu | %lu)", self.localAddressString, self.remoteAddressString, (int)_statusCode, _request.method, _request.path, (unsigned long)_bytesRead, (unsigned long)_bytesWritten);
    } else {
        LOG_VERBOSE(@"[%@] %@ %i \"(invalid request)\" (%lu | %lu)", self.localAddressString, self.remoteAddressString, (int)_statusCode, (unsigned long)_bytesRead, (unsigned long)_bytesWritten);
    }
    
    if (_requestMessage) {
        CFRelease(_requestMessage);
    }
    
    if (_responseMessage) {
        CFRelease(_responseMessage);
    }
}

#pragma mark -

- (void)_readBodyWithLength:(NSUInteger)length initialData:(NSData*)initialData {
  NSError* error = nil;
  if (![_request performOpen:&error]) {
    LOG_ERROR(@"Failed opening request body for socket %i: %@", _socket, error);
    [self abortRequest:_request withStatusCode:500];//InternalServerError
    return;
  }
  
  if (initialData.length) {
    if (![_request performWriteData:initialData error:&error]) {
      LOG_ERROR(@"Failed writing request body on socket %i: %@", _socket, error);
      if (![_request performClose:&error]) {
        LOG_ERROR(@"Failed closing request body for socket %i: %@", _socket, error);
      }
      [self abortRequest:_request withStatusCode:500];//InternalServerError
      return;
    }
    length -= initialData.length;
  }
  
  if (length) {
    [self _readBodyWithRemainingLength:length completionBlock:^(BOOL success) {
      
      NSError* localError = nil;
      if ([self->_request performClose:&localError]) {
        [self _startProcessingRequest];
      } else {
        LOG_ERROR(@"Failed closing request body for socket %i: %@", self->_socket, error);
        [self abortRequest:self->_request withStatusCode:500];//InternalServerError
      }
      
    }];
  } else {
    if ([_request performClose:&error]) {
      [self _startProcessingRequest];
    } else {
      LOG_ERROR(@"Failed closing request body for socket %i: %@", _socket, error);
      [self abortRequest:_request withStatusCode:500];//InternalServerError
    }
  }
}

- (void)_readChunkedBodyWithInitialData:(NSData*)initialData {
  NSError* error = nil;
  if (![_request performOpen:&error]) {
    LOG_ERROR(@"Failed opening request body for socket %i: %@", _socket, error);
    [self abortRequest:_request withStatusCode:500];//InternalServerError
    return;
  }
  
  NSMutableData* chunkData = [[NSMutableData alloc] initWithData:initialData];
  [self _readNextBodyChunk:chunkData completionBlock:^(BOOL success) {
  
    NSError* localError = nil;
    if ([self->_request performClose:&localError]) {
      [self _startProcessingRequest];
    } else {
      LOG_ERROR(@"Failed closing request body for socket %i: %@", self->_socket, error);
      [self abortRequest:self->_request withStatusCode:500];//InternalServerError
    }
    
  }];
}

- (void)_readRequestHeaders {

  _requestMessage = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, true);
  NSMutableData* headersData = [[NSMutableData alloc] initWithCapacity:kHeadersReadCapacity];
  [self _readHeaders:headersData withCompletionBlock:^(NSData* extraData) {
    
    if (extraData) {
      NSString* requestMethod = CFBridgingRelease(CFHTTPMessageCopyRequestMethod(self->_requestMessage));  // Method verbs are case-sensitive and uppercase
      NSDictionary* requestHeaders = CFBridgingRelease(CFHTTPMessageCopyAllHeaderFields(self->_requestMessage));  // Header names are case-insensitive but CFHTTPMessageCopyAllHeaderFields() will standardize the common ones
      NSURL* requestURL = CFBridgingRelease(CFHTTPMessageCopyRequestURL(self->_requestMessage));
//JF path (strips the ending slash) instead of absoluteString (which keeps host and port)
      NSString* requestPath = [[requestURL path] stringByRemovingPercentEncoding];
      NSString* queryString = requestURL ? CFBridgingRelease(CFURLCopyQueryString((CFURLRef)requestURL, NULL)) : nil;  // Don't use -[NSURL query] to make sure query is not unescaped;
        
        /**
         *  Extracts the unescaped names and values from an
         *  "application/x-www-form-urlencoded" form.
         *  http://www.w3.org/TR/html401/interact/forms.html#h-17.13.4.1
         */

        NSDictionary* requestQuery = nil;
        if (!queryString || ![queryString length]) requestQuery = @{};
        else
        {
            NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
            NSScanner* scanner = [[NSScanner alloc] initWithString:queryString];
            [scanner setCharactersToBeSkipped:nil];
            while (1) {
                NSString* key = nil;
                if (![scanner scanUpToString:@"=" intoString:&key] || [scanner isAtEnd]) {
                    break;
                }
                [scanner setScanLocation:([scanner scanLocation] + 1)];
                
                NSString* value = nil;
                [scanner scanUpToString:@"&" intoString:&value];
                if (value == nil) {
                    value = @"";
                }
                
                key = [key stringByReplacingOccurrencesOfString:@"+" withString:@" "];
                NSString* unescapedKey = [key stringByRemovingPercentEncoding];
                value = [value stringByReplacingOccurrencesOfString:@"+" withString:@" "];
                NSString* unescapedValue = [value stringByRemovingPercentEncoding];
                if (unescapedKey && unescapedValue) {
                    [parameters setObject:unescapedValue forKey:unescapedKey];
                } else {
                    LOG_WARNING(@"Failed parsing URL encoded form for key \"%@\" and value \"%@\"", key, value);
                }
                
                if ([scanner isAtEnd]) {
                    break;
                }
                [scanner setScanLocation:([scanner scanLocation] + 1)];
            }
            requestQuery=[NSDictionary dictionaryWithDictionary:parameters];
        }

        
//JF where the blocks in main are called from Connection
      if (requestMethod && requestURL && requestHeaders && requestPath && requestQuery && self.localAddressString && self.remoteAddressString){
        for (self->_handler in _handlers) {
            self->_request = self->_handler.matchBlock(requestMethod, requestURL, requestHeaders, requestPath, requestQuery, self.localAddressString, self.remoteAddressString);
          if (self->_request) break;
        }
        if (self->_request) {
          if ([self->_request hasBody]) {
            [self->_request prepareForWriting];
            if (self->_request.usesChunkedTransferEncoding || (extraData.length <= self->_request.contentLength)) {
              NSString* expectHeader = [requestHeaders objectForKey:@"Expect"];
              if (expectHeader) {
                if ([expectHeader caseInsensitiveCompare:@"100-continue"] == NSOrderedSame) {  // TODO: Actually validate request before continuing
                  [self _writeData:_continueData withCompletionBlock:^(BOOL success) {
                    
                    if (success) {
                      if (self->_request.usesChunkedTransferEncoding) {
                        [self _readChunkedBodyWithInitialData:extraData];
                      } else {
                        [self _readBodyWithLength:self->_request.contentLength initialData:extraData];
                      }
                    }
                    
                  }];
                } else {
                  LOG_ERROR(@"Unsupported 'Expect' / 'Content-Length' header combination on socket %i", self->_socket);
                    [self abortRequest:self->_request withStatusCode:417];//ExpectationFailed
                }
              } else {
                if (self->_request.usesChunkedTransferEncoding) {
                  [self _readChunkedBodyWithInitialData:extraData];
                } else {
                  [self _readBodyWithLength:self->_request.contentLength initialData:extraData];
                }
              }
            } else {
              LOG_ERROR(@"Unexpected 'Content-Length' header value on socket %i", self->_socket);
                [self abortRequest:self->_request withStatusCode:400];//BadRequest
            }
          } else {
            [self _startProcessingRequest];
          }
        } else {

          self->_request = [[RSRequest alloc] initWithMethod:requestMethod
                                                   url:requestURL
                                               headers:requestHeaders
                                                  path:requestPath
                                                 query:requestQuery
                                                 local:self.localAddressString
                                                remote:self.remoteAddressString
                      ];
          [self abortRequest:self->_request withStatusCode:405];//MethodNotAllowed
        }
      } else {
        [self abortRequest:nil withStatusCode:500];//InternalServerError
      }
    } else {
      [self abortRequest:nil withStatusCode:500];//InternalServerError
    }
    
  }];
}

- (id)initWithLocalAddress:(NSData*)localAddress
             remoteAddress:(NSData*)remoteAddress
                    socket:(CFSocketNativeHandle)socket
{
  if ((self = [super init])) {
    _localAddress = localAddress;
    _remoteAddress = remoteAddress;
    _socket = socket;
    LOG_DEBUG(@"Did open connection on socket %i", _socket);
    [self _readRequestHeaders];
  }
  return self;
}

- (NSString*)localAddressString {
    return [NSString stringFromSockAddr:_localAddress.bytes includeService:YES];
}

- (NSString*)remoteAddressString {
    return [NSString stringFromSockAddr:_remoteAddress.bytes includeService:YES];
}

#pragma mark -

- (void)_readData:(NSMutableData*)data withLength:(NSUInteger)length completionBlock:(ReadDataCompletionBlock)block {
    dispatch_read(_socket, length, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(dispatch_data_t buffer, int error) {
        
        @autoreleasepool {
            if (error == 0) {
                size_t size = dispatch_data_get_size(buffer);
                if (size > 0) {
                    NSUInteger originalLength = data.length;
                    dispatch_data_apply(buffer, ^bool(dispatch_data_t region, size_t chunkOffset, const void* chunkBytes, size_t chunkSize) {
                        [data appendBytes:chunkBytes length:chunkSize];
                        return true;
                    });
                    LOG_DEBUG(@"Connection received %lu bytes on socket %i", (unsigned long)(data.length - originalLength), self->_socket);
                    self->_bytesRead += (data.length - originalLength);
                    block(YES);
                } else {
                    if (self->_bytesRead > 0) {
                        LOG_ERROR(@"No more data available on socket %i", self->_socket);
                    } else {
                        LOG_WARNING(@"No data received from socket %i", self->_socket);
                    }
                    block(NO);
                }
            } else {
                LOG_ERROR(@"Error while reading from socket %i: %s (%i)", self->_socket, strerror(error), error);
                block(NO);
            }
        }
        
    });
}

- (void)_readHeaders:(NSMutableData*)headersData withCompletionBlock:(ReadHeadersCompletionBlock)block {
    [self _readData:headersData withLength:NSUIntegerMax completionBlock:^(BOOL success) {
        
        if (success) {
            NSRange range = [headersData rangeOfData:_CRLFCRLFData options:0 range:NSMakeRange(0, headersData.length)];
            if (range.location == NSNotFound) {
                [self _readHeaders:headersData withCompletionBlock:block];
            } else {
                NSUInteger length = range.location + range.length;
                if (CFHTTPMessageAppendBytes(self->_requestMessage, headersData.bytes, length)) {
                    if (CFHTTPMessageIsHeaderComplete(self->_requestMessage)) {
                        block([headersData subdataWithRange:NSMakeRange(length, headersData.length - length)]);
                    } else {
                        LOG_ERROR(@"Failed parsing request headers from socket %i", self->_socket);
                        block(nil);
                    }
                } else {
                    LOG_ERROR(@"Failed appending request headers data from socket %i", self->_socket);
                    block(nil);
                }
            }
        } else {
            block(nil);
        }
        
    }];
}

- (void)_readBodyWithRemainingLength:(NSUInteger)length completionBlock:(ReadBodyCompletionBlock)block {
    NSMutableData* bodyData = [[NSMutableData alloc] initWithCapacity:kBodyReadCapacity];
    [self _readData:bodyData withLength:length completionBlock:^(BOOL success) {
        
        if (success) {
            if (bodyData.length <= length) {
                NSError* error = nil;
                if ([self->_request performWriteData:bodyData error:&error]) {
                    NSUInteger remainingLength = length - bodyData.length;
                    if (remainingLength) {
                        [self _readBodyWithRemainingLength:remainingLength completionBlock:block];
                    } else {
                        block(YES);
                    }
                } else {
                    LOG_ERROR(@"Failed writing request body on socket %i: %@", self->_socket, error);
                    block(NO);
                }
            } else {
                LOG_ERROR(@"Unexpected extra content reading request body on socket %i", self->_socket);
                block(NO);
            }
        } else {
            block(NO);
        }
        
    }];
}

static inline NSUInteger _ScanHexNumber(const void* bytes, NSUInteger size) {
    char buffer[size + 1];
    bcopy(bytes, buffer, size);
    buffer[size] = 0;
    char* end = NULL;
    long result = strtol(buffer, &end, 16);
    return ((end != NULL) && (*end == 0) && (result >= 0) ? result : NSNotFound);
}

- (void)_readNextBodyChunk:(NSMutableData*)chunkData completionBlock:(ReadBodyCompletionBlock)block {
    
    while (1) {
        NSRange range = [chunkData rangeOfData:_CRLFData options:0 range:NSMakeRange(0, chunkData.length)];
        if (range.location == NSNotFound) {
            break;
        }
        NSRange extensionRange = [chunkData rangeOfData:[NSData dataWithBytes:";" length:1] options:0 range:NSMakeRange(0, range.location)];  // Ignore chunk extensions
        NSUInteger length = _ScanHexNumber((char*)chunkData.bytes, extensionRange.location != NSNotFound ? extensionRange.location : range.location);
        if (length != NSNotFound) {
            if (length) {
                if (chunkData.length < range.location + range.length + length + 2) {
                    break;
                }
                const char* ptr = (char*)chunkData.bytes + range.location + range.length + length;
                if ((*ptr == '\r') && (*(ptr + 1) == '\n')) {
                    NSError* error = nil;
                    if ([_request performWriteData:[chunkData subdataWithRange:NSMakeRange(range.location + range.length, length)] error:&error]) {
                        [chunkData replaceBytesInRange:NSMakeRange(0, range.location + range.length + length + 2) withBytes:NULL length:0];
                    } else {
                        LOG_ERROR(@"Failed writing request body on socket %i: %@", _socket, error);
                        block(NO);
                        return;
                    }
                } else {
                    LOG_ERROR(@"Missing terminating CRLF sequence for chunk reading request body on socket %i", _socket);
                    block(NO);
                    return;
                }
            } else {
                NSRange trailerRange = [chunkData rangeOfData:_CRLFCRLFData options:0 range:NSMakeRange(range.location, chunkData.length - range.location)];  // Ignore trailers
                if (trailerRange.location != NSNotFound) {
                    block(YES);
                    return;
                }
            }
        } else {
            LOG_ERROR(@"Invalid chunk length reading request body on socket %i", _socket);
            block(NO);
            return;
        }
    }
    
    [self _readData:chunkData withLength:NSUIntegerMax completionBlock:^(BOOL success) {
        
        if (success) {
            [self _readNextBodyChunk:chunkData completionBlock:block];
        } else {
            block(NO);
        }
        
    }];
}

#pragma mark - JF avoid Protocol wrong type for socket (41)
//http://erickt.github.io/blog/2014/11/19/adventures-in-debugging-a-potential-osx-kernel-bug/
//https://stackoverflow.com/questions/17948903/dispatch-write-and-dispatch-read-usage
//https://developer.apple.com/documentation/dispatch/1388969-dispatch_write
//old code below the new one

-  (void)_writeData:(NSData*)data
withCompletionBlock:(WriteDataCompletionBlock)block
{
   dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
   dispatch_data_t buffer = dispatch_data_create(
    data.bytes,
    data.length,
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    ^{ dispatch_semaphore_signal(sem); }
    );

   dispatch_write(
    _socket,
    buffer,
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    ^(dispatch_data_t remainingData, int error)
     {
         if (dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW,100000))!=0)
         {
            //Returns zero on success, or non-zero if the timeout in nanoseconds (10^9) occurred.
            //Decrement the counting semaphore. If the resulting value is less than zero, this function waits for a signal to occur before returning.
            LOG_DEBUG(@"%i:dispatch_write wait 100000 nanosec",self->_socket);
            if (dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW,1000000))!=0)
            {
               LOG_VERBOSE(@"%i:dispatch_write wait 1 milisec",self->_socket);
               if (dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW,100000000))!=0)
               {
                     LOG_INFO(@"%i:dispatch_write wait 1 sec",self->_socket);
                     if (dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW,500000000))!=0)
                     {
                        LOG_WARNING(@"%i:dispatch_write wait 0.5 sec",self->_socket);

                        if (dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW,1000000000))!=0)
                        {
                           LOG_ERROR(@"%i:dispatch_write wait 1.6 sec",self->_socket);
                        }
                     }
               }
            }

         }
         if (error==0)
         {
            LOG_DEBUG(@"%i: %lu",
                      self->_socket,
                      (unsigned long)data.length
                      );
            self->_bytesWritten += data.length;
            block(YES);
         }
         else
         {
            LOG_ERROR(@"%i: %s (%i)",
                      self->_socket,
                      strerror(error),
                      error
                      );
            block(NO);
         }
      }
   );
}


/*
 - (void)_writeData:(NSData*)data withCompletionBlock:(WriteDataCompletionBlock)block {
    
     dispatch_data_t buffer =
      dispatch_data_create(
       data.bytes,
       data.length,
       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
       ^{
         [data self];  // Keeps ARC from releasing data too early
       }
      );
    
     dispatch_write(
      _socket,
      buffer,
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
      ^(dispatch_data_t remainingData, int error)
       {
         @autoreleasepool {
             if (error == 0) {
                 LOG_DEBUG(@"Connection sent %lu bytes on socket %i", (unsigned long)data.length, _socket);
                 _bytesWritten += data.length;
                 block(YES);
             } else {
                 LOG_ERROR(@"Error while writing to socket %i: %s (%i)", _socket, strerror(error), error);
                 block(NO);
             }
         }
       }
    );
 }

 */
- (void)_writeHeadersWithCompletionBlock:(WriteHeadersCompletionBlock)block {
    CFDataRef data = CFHTTPMessageCopySerializedMessage(_responseMessage);
    [self _writeData:(__bridge NSData*)data withCompletionBlock:block];
    CFRelease(data);
}

- (void)_writeBodyWithCompletionBlock:(WriteBodyCompletionBlock)block {
    [_response performReadDataWithCompletion:^(NSData* data, NSError* error) {
        
        if (data) {
            if (data.length) {
                if (self->_response.usesChunkedTransferEncoding) {
                    const char* hexString = [[NSString stringWithFormat:@"%lx", (unsigned long)data.length] UTF8String];
                    size_t hexLength = strlen(hexString);
                    NSData* chunk = [NSMutableData dataWithLength:(hexLength + 2 + data.length + 2)];
                    if (chunk == nil) {
                        LOG_ERROR(@"Failed allocating memory for response body chunk for socket %i: %@", self->_socket, error);
                        block(NO);
                        return;
                    }
                    char* ptr = (char*)[(NSMutableData*)chunk mutableBytes];
                    bcopy(hexString, ptr, hexLength);
                    ptr += hexLength;
                    *ptr++ = '\r';
                    *ptr++ = '\n';
                    bcopy(data.bytes, ptr, data.length);
                    ptr += data.length;
                    *ptr++ = '\r';
                    *ptr = '\n';
                    data = chunk;
                }
                [self _writeData:data withCompletionBlock:^(BOOL success) {
                    
                    if (success) {
                        [self _writeBodyWithCompletionBlock:block];
                    } else {
                        block(NO);
                    }
                    
                }];
            } else {
                if (self->_response.usesChunkedTransferEncoding) {
                    [self _writeData:_lastChunkData withCompletionBlock:^(BOOL success) {
                        
                        block(success);
                        
                    }];
                } else {
                    block(YES);
                }
            }
        } else {
            LOG_ERROR(@"Failed reading response body for socket %i: %@", self->_socket, error);
            block(NO);
        }
        
    }];
}

@end
