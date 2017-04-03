#import "RSRequest.h"
#import "RSGZipDecoder.h"
#import "ODLog.h"
#import "RFC822.h"
#import "NSString+PCS.h"

@implementation RSRequest : NSObject

@synthesize method=_method;
@synthesize URL=_url;
@synthesize headers=_headers;
@synthesize path=_path;
@synthesize query=_query;
@synthesize contentType=_type;
@synthesize contentLength=_length;
@synthesize ifModifiedSince=_modifiedSince;
@synthesize ifNoneMatch=_noneMatch;
@synthesize byteRange=_range;
@synthesize acceptsGzipContentEncoding=_gzipAccepted;
@synthesize usesChunkedTransferEncoding=_chunked;
@synthesize localAddressString=_localAddressString;
@synthesize remoteAddressString=_remoteAddressString;

- (instancetype)initWithMethod:(NSString*)method
                           url:(NSURL*)url
                       headers:(NSDictionary*)headers
                          path:(NSString*)path
                         query:(NSDictionary*)query
                         local:(NSString*)localAddressString
                        remote:(NSString*)remoteAddressString;
{
  if ((self = [super init])) {
    _method = [method copy];
    _url = url;
    _headers = headers;
    _path = [path copy];
    _query = query;
    _localAddressString = localAddressString;
    _remoteAddressString = remoteAddressString;
      
    _type = [[_headers objectForKey:@"Content-Type"] normalizeHeaderValue];
    _chunked = [[[_headers objectForKey:@"Transfer-Encoding"] normalizeHeaderValue] isEqualToString:@"chunked"];
    NSString* lengthHeader = [_headers objectForKey:@"Content-Length"];
    if (lengthHeader) {
      NSInteger length = [lengthHeader integerValue];
      if (_chunked || (length < 0)) {
        LOG_WARNING(@"Invalid 'Content-Length' header '%@' for '%@' request on \"%@\"", lengthHeader, _method, _url);
        return nil;
      }
      _length = length;
      if (_type == nil) {
        _type = @"application/octet-stream";
      }
    } else if (_chunked) {
      if (_type == nil) {
        _type = @"application/octet-stream";
      }
      _length = NSUIntegerMax;
    } else {
      if (_type) {
        LOG_WARNING(@"Ignoring 'Content-Type' header for '%@' request on \"%@\"", _method, _url);
        _type = nil;  // Content-Type without Content-Length or chunked-encoding doesn't make sense
      }
      _length = NSUIntegerMax;
    }
    
    NSString* modifiedHeader = [_headers objectForKey:@"If-Modified-Since"];
    if (modifiedHeader) _modifiedSince = [[RFC822 dateFromString:modifiedHeader] copy];
    _noneMatch = [_headers objectForKey:@"If-None-Match"];
    
    _range = NSMakeRange(NSUIntegerMax, 0);
    NSString* rangeHeader = [[_headers objectForKey:@"Range"] normalizeHeaderValue];
    if (rangeHeader) {
      if ([rangeHeader hasPrefix:@"bytes="]) {
        NSArray* components = [[rangeHeader substringFromIndex:6] componentsSeparatedByString:@","];
        if (components.count == 1) {
          components = [[components firstObject] componentsSeparatedByString:@"-"];
          if (components.count == 2) {
            NSString* startString = [components objectAtIndex:0];
            NSInteger startValue = [startString integerValue];
            NSString* endString = [components objectAtIndex:1];
            NSInteger endValue = [endString integerValue];
            if (startString.length && (startValue >= 0) && endString.length && (endValue >= startValue)) {  // The second 500 bytes: "500-999"
              _range.location = startValue;
              _range.length = endValue - startValue + 1;
            } else if (startString.length && (startValue >= 0)) {  // The bytes after 9500 bytes: "9500-"
              _range.location = startValue;
              _range.length = NSUIntegerMax;
            } else if (endString.length && (endValue > 0)) {  // The final 500 bytes: "-500"
              _range.location = NSUIntegerMax;
              _range.length = endValue;
            }
          }
        }
      }
      if ((_range.location == NSUIntegerMax) && (_range.length == 0)) {  // Ignore "Range" header if syntactically invalid
        LOG_WARNING(@"Failed to parse 'Range' header \"%@\" for url: %@", rangeHeader, url);
      }
    }
    
    if ([[_headers objectForKey:@"Accept-Encoding"] rangeOfString:@"gzip"].location != NSNotFound) {
      _gzipAccepted = YES;
    }
    
    _decoders = [[NSMutableArray alloc] init];
    _attributes = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (BOOL)hasBody {
  return _type ? YES : NO;
}

- (BOOL)hasByteRange {
  return ((_range.location != NSUIntegerMax) || (_range.length > 0));
}

- (id)attributeForKey:(NSString*)key {
  return [_attributes objectForKey:key];
}

- (BOOL)open:(NSError**)error {
  return YES;
}

- (BOOL)writeData:(NSData*)data error:(NSError**)error {
  return YES;
}

- (BOOL)close:(NSError**)error {
  return YES;
}

- (void)prepareForWriting {
  _writer = self;
  if ([[[self.headers objectForKey:@"Content-Encoding"] normalizeHeaderValue] isEqualToString:@"gzip"]) {
    RSGZipDecoder* decoder = [[RSGZipDecoder alloc] initWithRequest:self writer:_writer];
    [_decoders addObject:decoder];
    _writer = decoder;
  }
}

- (BOOL)performOpen:(NSError**)error {
  if (_opened) {
    return NO;
  }
  _opened = YES;
  return [_writer open:error];
}

- (BOOL)performWriteData:(NSData*)data error:(NSError**)error {
  return [_writer writeData:data error:error];
}

- (BOOL)performClose:(NSError**)error {
  return [_writer close:error];
}

- (void)setAttribute:(id)attribute forKey:(NSString*)key {
  [_attributes setValue:attribute forKey:key];
}
/*
- (NSString*)localAddressString {
    return _localAddressString;
}

- (NSString*)remoteAddressString {
    return _localAddressString;
}
*/
- (NSString*)description {
  NSMutableString* description = [NSMutableString stringWithFormat:@"%@ %@", _method, _path];
  for (NSString* argument in [[_query allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
    [description appendFormat:@"\n  %@ = %@", argument, [_query objectForKey:argument]];
  }
  [description appendString:@"\n"];
  for (NSString* header in [[_headers allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
    [description appendFormat:@"\n%@: %@", header, [_headers objectForKey:header]];
  }
  return description;
}

@end
