#import <netinet/in.h>

#import "RSConnection.h"

#import "RS.h"
#import "RSErrorResponse.h"
#import "RSFileResponse.h"

#import "NSString+PCS.h"

#import "ODLog.h"


@implementation RS

@synthesize handlers=_handlers;
- (instancetype)init {
  if ((self = [super init])) {
    _syncQueue = dispatch_queue_create([NSStringFromClass([self class]) UTF8String], DISPATCH_QUEUE_SERIAL);
    _sourceGroup = dispatch_group_create();
    _handlers = [[NSMutableArray alloc] init];
  }
  return self;
}

- (int)_createListeningSocket:(BOOL)useIPv6
                 localAddress:(const void*)address
                       length:(socklen_t)length
        maxPendingConnections:(NSUInteger)maxPendingConnections
                        error:(NSError**)error {
  int listeningSocket = socket(useIPv6 ? PF_INET6 : PF_INET, SOCK_STREAM, IPPROTO_TCP);
  if (listeningSocket > 0) {
    int yes = 1;
    setsockopt(listeningSocket, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));
    
    if (bind(listeningSocket, address, length) == 0) {
      if (listen(listeningSocket, (int)maxPendingConnections) == 0) {
        LOG_DEBUG(@"Did open %s listening socket %i", useIPv6 ? "IPv6" : "IPv4", listeningSocket);
        return listeningSocket;
      } else {
        if (error) {
          *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithUTF8String:strerror(errno)]}];
        }
        LOG_ERROR(@"Failed starting %s listening socket: %s (%i)", useIPv6 ? "IPv6" : "IPv4", strerror(errno), errno);
        close(listeningSocket);
      }
    } else {
      if (error) {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithUTF8String:strerror(errno)]}];
      }
      LOG_ERROR(@"Failed binding %s listening socket: %s (%i)", useIPv6 ? "IPv6" : "IPv4", strerror(errno), errno);
      close(listeningSocket);
    }
    
  } else {
    if (error) {
      *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithUTF8String:strerror(errno)]}];
    }
    LOG_ERROR(@"Failed creating %s listening socket: %s (%i)", useIPv6 ? "IPv6" : "IPv4", strerror(errno), errno);
  }
  return -1;
}

#pragma mark starts listening and calling RSConnection for each new connection
- (dispatch_source_t)_createDispatchSourceWithListeningSocket:(int)listeningSocket isIPv6:(BOOL)isIPv6 {
  dispatch_group_enter(_sourceGroup);
  dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, listeningSocket, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
  dispatch_source_set_cancel_handler(source, ^{
    
    @autoreleasepool {
      int result = close(listeningSocket);
      if (result != 0) {
        LOG_ERROR(@"Failed closing %s listening socket: %s (%i)", isIPv6 ? "IPv6" : "IPv4", strerror(errno), errno);
      } else {
        LOG_DEBUG(@"Did close %s listening socket %i", isIPv6 ? "IPv6" : "IPv4", listeningSocket);
      }
    }
    dispatch_group_leave(_sourceGroup);
    
  });
  dispatch_source_set_event_handler(source, ^{
    
    @autoreleasepool {
      struct sockaddr_storage remoteSockAddr;
      socklen_t remoteAddrLen = sizeof(remoteSockAddr);
      int socket = accept(listeningSocket, (struct sockaddr*)&remoteSockAddr, &remoteAddrLen);
      if (socket > 0) {
        NSData* remoteAddress = [NSData dataWithBytes:&remoteSockAddr length:remoteAddrLen];
        
        struct sockaddr_storage localSockAddr;
        socklen_t localAddrLen = sizeof(localSockAddr);
        NSData* localAddress = nil;
        if (getsockname(socket, (struct sockaddr*)&localSockAddr, &localAddrLen) == 0) {
          localAddress = [NSData dataWithBytes:&localSockAddr length:localAddrLen];
        }
        int noSigPipe = 1;
        setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe, sizeof(noSigPipe));  // Make sure this socket cannot generate SIG_PIPE
        
        RSConnection* connection = [[RSConnection alloc] initWithServer:self localAddress:localAddress remoteAddress:remoteAddress socket:socket];  // Connection will automatically retain itself while opened
        [connection self];  // Prevent compiler from complaining about unused variable / useless statement
      } else {
        LOG_ERROR(@"Failed accepting %s socket: %s (%i)", isIPv6 ? "IPv6" : "IPv4", strerror(errno), errno);
      }
    }
    
  });
  return source;
}

- (BOOL)startWithPort:(NSUInteger)port maxPendingConnections:(NSUInteger)maxPendingConnections error:(NSError**)error {
    
    struct sockaddr_in addr4;
    bzero(&addr4, sizeof(addr4));
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_port = htons(port);
    addr4.sin_addr.s_addr = htonl(INADDR_ANY);
    int listeningSocket4 = [self _createListeningSocket:NO localAddress:&addr4 length:sizeof(addr4) maxPendingConnections:maxPendingConnections error:error];
    if (listeningSocket4 <= 0) {
        return NO;
    }
    
    struct sockaddr_in6 addr6;
    bzero(&addr6, sizeof(addr6));
    addr6.sin6_len = sizeof(addr6);
    addr6.sin6_family = AF_INET6;
    addr6.sin6_port = htons(port);
    addr6.sin6_addr = in6addr_any;
    int listeningSocket6 = [self _createListeningSocket:YES localAddress:&addr6 length:sizeof(addr6) maxPendingConnections:maxPendingConnections error:error];
    if (listeningSocket6 <= 0) {
        close(listeningSocket4);
        return NO;
    }
    
    _source4 = [self _createDispatchSourceWithListeningSocket:listeningSocket4 isIPv6:NO];
    _source6 = [self _createDispatchSourceWithListeningSocket:listeningSocket6 isIPv6:YES];
    dispatch_resume(_source4);
    dispatch_resume(_source6);
    LOG_INFO(@"httpdicom started on port %i", (int)port);
    
    return YES;
}

- (void)addHandler:(NSString*)method
             regex:(NSRegularExpression*)pathRegularExpression
             block:(RSAsyncProcessBlock)block {
    
    [self addHandlerWithMatchBlock:
     ^RSRequest *(NSString* requestMethod, NSURL* requestURL, NSDictionary* requestHeaders, NSString* urlPath, NSDictionary* urlQuery)
    {
        
        if (![requestMethod isEqualToString:method]) {
            return nil;
        }
        
        NSArray* matches = [pathRegularExpression matchesInString:urlPath options:0 range:NSMakeRange(0, urlPath.length)];
        if (matches.count == 0) {
            return nil;
        }
        
        NSMutableArray* captures = [NSMutableArray array];
        for (NSTextCheckingResult* result in matches) {
            // Start at 1; index 0 is the whole string
            for (NSUInteger i = 1; i < result.numberOfRanges; i++) {
                NSRange range = [result rangeAtIndex:i];
                // range is {NSNotFound, 0} "if one of the capture groups did not participate in this particular match"
                // see discussion in -[NSRegularExpression firstMatchInString:options:range:]
                if (range.location != NSNotFound) {
                    [captures addObject:[urlPath substringWithRange:range]];
                }
            }
        }
        
        RSRequest* request = [[RSRequest alloc] initWithMethod:requestMethod url:requestURL headers:requestHeaders path:urlPath query:urlQuery];
        /**
         *  Attribute key asociated to an NSArray containing NSStrings from a RSRequest with the contents of any regular expression captures done on the request path.
         @warning This attribute will only be set on the request if adding a handler using  -addHandlerForMethod:pathRegex:requestClass:processBlock:.
         */
        [request setAttribute:captures forKey:@"RSRequestAttribute_RegexCaptures"];
        return request;
        
    }
                      processBlock:block];
}


#pragma mark root handler with matchBlock and asyncProcessBlock

- (void)addHandlerWithMatchBlock:(RSMatchBlock)matchBlock
                    processBlock:(RSAsyncProcessBlock)processBlock {
    
    RSHandler* handler = [[RSHandler alloc] initWithMatchBlock:matchBlock
                                                  processBlock:processBlock];
    [_handlers insertObject:handler atIndex:0];
}

@end
