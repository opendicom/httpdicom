#import <netinet/in.h>
#import <dns_sd.h>

#import "GCDWebServerPrivate.h"
#import "Log.h"

/*
 Copyright (c) 2012-2015, Pierre-Olivier Latour
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * The name of Pierre-Olivier Latour may not be used to endorse
 or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL PIERRE-OLIVIER LATOUR BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#define kBonjourResolutionTimeout 5.0

NSString* const GCDWebServerOption_Port = @"Port";
NSString* const GCDWebServerOption_BonjourName = @"BonjourName";
NSString* const GCDWebServerOption_BonjourType = @"BonjourType";
NSString* const GCDWebServerOption_RequestNATPortMapping = @"RequestNATPortMapping";
NSString* const GCDWebServerOption_BindToLocalhost = @"BindToLocalhost";
NSString* const GCDWebServerOption_MaxPendingConnections = @"MaxPendingConnections";
NSString* const GCDWebServerOption_ServerName = @"ServerName";
NSString* const GCDWebServerOption_AuthenticationMethod = @"AuthenticationMethod";
NSString* const GCDWebServerOption_AuthenticationRealm = @"AuthenticationRealm";
NSString* const GCDWebServerOption_AuthenticationAccounts = @"AuthenticationAccounts";
NSString* const GCDWebServerOption_ConnectionClass = @"ConnectionClass";
NSString* const GCDWebServerOption_AutomaticallyMapHEADToGET = @"AutomaticallyMapHEADToGET";
NSString* const GCDWebServerOption_ConnectedStateCoalescingInterval = @"ConnectedStateCoalescingInterval";

NSString* const GCDWebServerAuthenticationMethod_Basic = @"Basic";
NSString* const GCDWebServerAuthenticationMethod_DigestAccess = @"DigestAccess";


static BOOL _run;

static void _SignalHandler(int signal) {
  _run = NO;
  printf("\n");
}


// This utility function is used to ensure scheduled callbacks on the main thread are called when running the server synchronously
// https://developer.apple.com/library/mac/documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationQueues/OperationQueues.html
// The main queue works with the application’s run loop to interleave the execution of queued tasks with the execution of other event sources attached to the run loop
// TODO: Ensure all scheduled blocks on the main queue are also executed
static void _ExecuteMainThreadRunLoopSources() {
  SInt32 result;
  do {
    result = CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.0, true);
  } while (result == kCFRunLoopRunHandledSource);
}


@interface GCDWebServerHandler () {
@private
  GCDWebServerMatchBlock _matchBlock;
  GCDWebServerAsyncProcessBlock _asyncProcessBlock;
}
@end

@implementation GCDWebServerHandler

@synthesize matchBlock=_matchBlock, asyncProcessBlock=_asyncProcessBlock;

- (id)initWithMatchBlock:(GCDWebServerMatchBlock)matchBlock asyncProcessBlock:(GCDWebServerAsyncProcessBlock)processBlock {
  if ((self = [super init])) {
    _matchBlock = [matchBlock copy];
    _asyncProcessBlock = [processBlock copy];
  }
  return self;
}

@end

@interface GCDWebServer () {
@private
  id<GCDWebServerDelegate> __unsafe_unretained _delegate;
  dispatch_queue_t _syncQueue;
  dispatch_group_t _sourceGroup;
  NSMutableArray* _handlers;
  NSInteger _activeConnections;  // Accessed through _syncQueue only
  BOOL _connected;  // Accessed on main thread only
  CFRunLoopTimerRef _disconnectTimer;  // Accessed on main thread only
  
  NSDictionary* _options;
  NSString* _serverName;
  NSString* _authenticationRealm;
  NSMutableDictionary* _authenticationBasicAccounts;
  NSMutableDictionary* _authenticationDigestAccounts;
  Class _connectionClass;
  BOOL _mapHEADToGET;
  CFTimeInterval _disconnectDelay;
  NSUInteger _port;
  dispatch_source_t _source4;
  dispatch_source_t _source6;
  CFNetServiceRef _registrationService;
  CFNetServiceRef _resolutionService;
  DNSServiceRef _dnsService;
  CFSocketRef _dnsSocket;
  CFRunLoopSourceRef _dnsSource;
  NSString* _dnsAddress;
  NSUInteger _dnsPort;
  BOOL _bindToLocalhost;
}
@end

@implementation GCDWebServer

@synthesize delegate=_delegate, handlers=_handlers, port=_port, serverName=_serverName, authenticationRealm=_authenticationRealm,
            authenticationBasicAccounts=_authenticationBasicAccounts, authenticationDigestAccounts=_authenticationDigestAccounts,
            shouldAutomaticallyMapHEADToGET=_mapHEADToGET;

+ (void)initialize {
  GCDWebServerInitializeFunctions();
}

- (instancetype)init {
  if ((self = [super init])) {
    _syncQueue = dispatch_queue_create([NSStringFromClass([self class]) UTF8String], DISPATCH_QUEUE_SERIAL);
    _sourceGroup = dispatch_group_create();
    _handlers = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc {
  // The server can never be dealloc'ed while running because of the retain-cycle with the dispatch source
  // The server can never be dealloc'ed while the disconnect timer is pending because of the retain-cycle
  
#if !OS_OBJECT_USE_OBJC_RETAIN_RELEASE
  dispatch_release(_sourceGroup);
  dispatch_release(_syncQueue);
#endif
}


// Always called on main thread
- (void)_didConnect {
  _connected = YES;
  LOG_DEBUG(@"Did connect");
  if ([_delegate respondsToSelector:@selector(webServerDidConnect:)]) {
    [_delegate webServerDidConnect:self];
  }
}

- (void)willStartConnection:(GCDWebServerConnection*)connection {
  dispatch_sync(_syncQueue, ^{
    
    if (_activeConnections == 0) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (_disconnectTimer) {
          CFRunLoopTimerInvalidate(_disconnectTimer);
          CFRelease(_disconnectTimer);
          _disconnectTimer = NULL;
        }
        if (_connected == NO) {
          [self _didConnect];
        }
      });
    }
    _activeConnections += 1;
    
  });
}


// Always called on main thread
- (void)_didDisconnect {
  _connected = NO;
  LOG_DEBUG(@"Did disconnect");
  if ([_delegate respondsToSelector:@selector(webServerDidDisconnect:)]) {
    [_delegate webServerDidDisconnect:self];
  }
}

- (void)didEndConnection:(GCDWebServerConnection*)connection {
  dispatch_sync(_syncQueue, ^{
    _activeConnections -= 1;
    if (_activeConnections == 0) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if ((_disconnectDelay > 0.0) && (_source4 != NULL)) {
          if (_disconnectTimer) {
            CFRunLoopTimerInvalidate(_disconnectTimer);
            CFRelease(_disconnectTimer);
          }
          _disconnectTimer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent() + _disconnectDelay, 0.0, 0, 0, ^(CFRunLoopTimerRef timer) {
            [self _didDisconnect];
            CFRelease(_disconnectTimer);
            _disconnectTimer = NULL;
          });
          CFRunLoopAddTimer(CFRunLoopGetMain(), _disconnectTimer, kCFRunLoopCommonModes);
        } else {
          [self _didDisconnect];
        }
      });
    }
  });
}

- (NSString*)bonjourName {
  CFStringRef name = _resolutionService ? CFNetServiceGetName(_resolutionService) : NULL;
  return name && CFStringGetLength(name) ? CFBridgingRelease(CFStringCreateCopy(kCFAllocatorDefault, name)) : nil;
}

- (NSString*)bonjourType {
  CFStringRef type = _resolutionService ? CFNetServiceGetType(_resolutionService) : NULL;
  return type && CFStringGetLength(type) ? CFBridgingRelease(CFStringCreateCopy(kCFAllocatorDefault, type)) : nil;
}
- (NSURL*)serverURL {
    if (_source4) {
        NSString* ipAddress = _bindToLocalhost ? @"localhost" : GCDWebServerGetPrimaryIPAddress(NO);  // We can't really use IPv6 anyway as it doesn't work great with HTTP URLs in practice
        if (ipAddress) {
            if (_port != 80) {
                return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%i/", ipAddress, (int)_port]];
            } else {
                return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/", ipAddress]];
            }
        }
    }
    return nil;
}

- (NSURL*)bonjourServerURL {
    if (_source4 && _resolutionService) {
        NSString* name = (__bridge NSString*)CFNetServiceGetTargetHost(_resolutionService);
        if (name.length) {
            name = [name substringToIndex:(name.length - 1)];  // Strip trailing period at end of domain
            if (_port != 80) {
                return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%i/", name, (int)_port]];
            } else {
                return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/", name]];
            }
        }
    }
    return nil;
}

- (NSURL*)publicServerURL {
    if (_source4 && _dnsService && _dnsAddress && _dnsPort) {
        if (_dnsPort != 80) {
            return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%i/", _dnsAddress, (int)_dnsPort]];
        } else {
            return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/", _dnsAddress]];
        }
    }
    return nil;
}

#pragma mark handlers

static void _NetServiceRegisterCallBack(CFNetServiceRef service, CFStreamError* error, void* info) {
  @autoreleasepool {
    if (error->error) {
      LOG_ERROR(@"Bonjour registration error %i (domain %i)", (int)error->error, (int)error->domain);
    } else {
      GCDWebServer* server = (__bridge GCDWebServer*)info;
      LOG_VERBOSE(@"Bonjour registration complete for %@", [server class]);
      if (!CFNetServiceResolveWithTimeout(server->_resolutionService, kBonjourResolutionTimeout, NULL)) {
        LOG_ERROR(@"Failed starting Bonjour resolution");
      }
    }
  }
}

static void _NetServiceResolveCallBack(CFNetServiceRef service, CFStreamError* error, void* info) {
  @autoreleasepool {
    if (error->error) {
      if ((error->domain != kCFStreamErrorDomainNetServices) && (error->error != kCFNetServicesErrorTimeout)) {
        LOG_ERROR(@"Bonjour resolution error %i (domain %i)", (int)error->error, (int)error->domain);
      }
    } else {
      GCDWebServer* server = (__bridge GCDWebServer*)info;
      LOG_INFO(@"%@ now locally reachable at %@", [server class], server.bonjourServerURL);
      if ([server.delegate respondsToSelector:@selector(webServerDidCompleteBonjourRegistration:)]) {
        [server.delegate webServerDidCompleteBonjourRegistration:server];
      }
    }
  }
}

static void _DNSServiceCallBack(DNSServiceRef sdRef, DNSServiceFlags flags, uint32_t interfaceIndex, DNSServiceErrorType errorCode, uint32_t externalAddress, DNSServiceProtocol protocol, uint16_t internalPort, uint16_t externalPort, uint32_t ttl, void* context) {
  @autoreleasepool {
    GCDWebServer* server = (__bridge GCDWebServer*)context;
    if ((errorCode == kDNSServiceErr_NoError) || (errorCode == kDNSServiceErr_DoubleNAT)) {
      struct sockaddr_in addr4;
      bzero(&addr4, sizeof(addr4));
      addr4.sin_len = sizeof(addr4);
      addr4.sin_family = AF_INET;
      addr4.sin_addr.s_addr = externalAddress;  // Already in network byte order
      server->_dnsAddress = GCDWebServerStringFromSockAddr((const struct sockaddr*)&addr4, NO);
      server->_dnsPort = ntohs(externalPort);
      LOG_INFO(@"%@ now publicly reachable at %@", [server class], server.publicServerURL);
    } else {
      LOG_ERROR(@"DNS service error %i", errorCode);
      server->_dnsAddress = nil;
      server->_dnsPort = 0;
    }
    if ([server.delegate respondsToSelector:@selector(webServerDidUpdateNATPortMapping:)]) {
      [server.delegate webServerDidUpdateNATPortMapping:server];
    }
  }
}

static void _SocketCallBack(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void* data, void* info) {
  @autoreleasepool {
    GCDWebServer* server = (__bridge GCDWebServer*)info;
    DNSServiceErrorType status = DNSServiceProcessResult(server->_dnsService);
    if (status != kDNSServiceErr_NoError) {
      LOG_ERROR(@"DNS service error %i", status);
    }
  }
}

static inline id _GetOption(NSDictionary* options, NSString* key, id defaultValue) {
  id value = [options objectForKey:key];
  return value ? value : defaultValue;
}

static inline NSString* _EncodeBase64(NSString* string) {
  NSData* data = [string dataUsingEncoding:NSUTF8StringEncoding];
  return [[NSString alloc] initWithData:[data base64EncodedDataWithOptions:0] encoding:NSASCIIStringEncoding];
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
          *error = GCDWebServerMakePosixError(errno);
        }
        LOG_ERROR(@"Failed starting %s listening socket: %s (%i)", useIPv6 ? "IPv6" : "IPv4", strerror(errno), errno);
        close(listeningSocket);
      }
    } else {
      if (error) {
        *error = GCDWebServerMakePosixError(errno);
      }
      LOG_ERROR(@"Failed binding %s listening socket: %s (%i)", useIPv6 ? "IPv6" : "IPv4", strerror(errno), errno);
      close(listeningSocket);
    }
    
  } else {
    if (error) {
      *error = GCDWebServerMakePosixError(errno);
    }
    LOG_ERROR(@"Failed creating %s listening socket: %s (%i)", useIPv6 ? "IPv6" : "IPv4", strerror(errno), errno);
  }
  return -1;
}

- (dispatch_source_t)_createDispatchSourceWithListeningSocket:(int)listeningSocket isIPv6:(BOOL)isIPv6 {
  dispatch_group_enter(_sourceGroup);
  dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, listeningSocket, 0, kGCDWebServerGCDQueue);
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
        
        GCDWebServerConnection* connection = [[_connectionClass alloc] initWithServer:self localAddress:localAddress remoteAddress:remoteAddress socket:socket];  // Connection will automatically retain itself while opened
        [connection self];  // Prevent compiler from complaining about unused variable / useless statement
      } else {
        LOG_ERROR(@"Failed accepting %s socket: %s (%i)", isIPv6 ? "IPv6" : "IPv4", strerror(errno), errno);
      }
    }
    
  });
  return source;
}

- (BOOL)_start:(NSError**)error {
  
  NSUInteger port = [_GetOption(_options, GCDWebServerOption_Port, @0) unsignedIntegerValue];
  BOOL bindToLocalhost = [_GetOption(_options, GCDWebServerOption_BindToLocalhost, @NO) boolValue];
  NSUInteger maxPendingConnections = [_GetOption(_options, GCDWebServerOption_MaxPendingConnections, @16) unsignedIntegerValue];
  
  struct sockaddr_in addr4;
  bzero(&addr4, sizeof(addr4));
  addr4.sin_len = sizeof(addr4);
  addr4.sin_family = AF_INET;
  addr4.sin_port = htons(port);
  addr4.sin_addr.s_addr = bindToLocalhost ? htonl(INADDR_LOOPBACK) : htonl(INADDR_ANY);
  int listeningSocket4 = [self _createListeningSocket:NO localAddress:&addr4 length:sizeof(addr4) maxPendingConnections:maxPendingConnections error:error];
  if (listeningSocket4 <= 0) {
    return NO;
  }
  if (port == 0) {
    struct sockaddr_in addr;
    socklen_t addrlen = sizeof(addr);
    if (getsockname(listeningSocket4, (struct sockaddr*)&addr, &addrlen) == 0) {
      port = ntohs(addr.sin_port);
    } else {
      LOG_ERROR(@"Failed retrieving socket address: %s (%i)", strerror(errno), errno);
    }
  }
  
  struct sockaddr_in6 addr6;
  bzero(&addr6, sizeof(addr6));
  addr6.sin6_len = sizeof(addr6);
  addr6.sin6_family = AF_INET6;
  addr6.sin6_port = htons(port);
  addr6.sin6_addr = bindToLocalhost ? in6addr_loopback : in6addr_any;
  int listeningSocket6 = [self _createListeningSocket:YES localAddress:&addr6 length:sizeof(addr6) maxPendingConnections:maxPendingConnections error:error];
  if (listeningSocket6 <= 0) {
    close(listeningSocket4);
    return NO;
  }
  
  _serverName = [_GetOption(_options, GCDWebServerOption_ServerName, NSStringFromClass([self class])) copy];
  NSString* authenticationMethod = _GetOption(_options, GCDWebServerOption_AuthenticationMethod, nil);
  if ([authenticationMethod isEqualToString:GCDWebServerAuthenticationMethod_Basic]) {
    _authenticationRealm = [_GetOption(_options, GCDWebServerOption_AuthenticationRealm, _serverName) copy];
    _authenticationBasicAccounts = [[NSMutableDictionary alloc] init];
    NSDictionary* accounts = _GetOption(_options, GCDWebServerOption_AuthenticationAccounts, @{});
    [accounts enumerateKeysAndObjectsUsingBlock:^(NSString* username, NSString* password, BOOL* stop) {
      [_authenticationBasicAccounts setObject:_EncodeBase64([NSString stringWithFormat:@"%@:%@", username, password]) forKey:username];
    }];
  } else if ([authenticationMethod isEqualToString:GCDWebServerAuthenticationMethod_DigestAccess]) {
    _authenticationRealm = [_GetOption(_options, GCDWebServerOption_AuthenticationRealm, _serverName) copy];
    _authenticationDigestAccounts = [[NSMutableDictionary alloc] init];
    NSDictionary* accounts = _GetOption(_options, GCDWebServerOption_AuthenticationAccounts, @{});
    [accounts enumerateKeysAndObjectsUsingBlock:^(NSString* username, NSString* password, BOOL* stop) {
      [_authenticationDigestAccounts setObject:GCDWebServerComputeMD5Digest(@"%@:%@:%@", username, _authenticationRealm, password) forKey:username];
    }];
  }
  _connectionClass = _GetOption(_options, GCDWebServerOption_ConnectionClass, [GCDWebServerConnection class]);
  _mapHEADToGET = [_GetOption(_options, GCDWebServerOption_AutomaticallyMapHEADToGET, @YES) boolValue];
  _disconnectDelay = [_GetOption(_options, GCDWebServerOption_ConnectedStateCoalescingInterval, @1.0) doubleValue];
  
  _source4 = [self _createDispatchSourceWithListeningSocket:listeningSocket4 isIPv6:NO];
  _source6 = [self _createDispatchSourceWithListeningSocket:listeningSocket6 isIPv6:YES];
  _port = port;
  _bindToLocalhost = bindToLocalhost;
  
  NSString* bonjourName = _GetOption(_options, GCDWebServerOption_BonjourName, nil);
  NSString* bonjourType = _GetOption(_options, GCDWebServerOption_BonjourType, @"_http._tcp");
  if (bonjourName) {
    _registrationService = CFNetServiceCreate(kCFAllocatorDefault, CFSTR("local."), (__bridge CFStringRef)bonjourType, (__bridge CFStringRef)(bonjourName.length ? bonjourName : _serverName), (SInt32)_port);
    if (_registrationService) {
      CFNetServiceClientContext context = {0, (__bridge void*)self, NULL, NULL, NULL};
      
      CFNetServiceSetClient(_registrationService, _NetServiceRegisterCallBack, &context);
      CFNetServiceScheduleWithRunLoop(_registrationService, CFRunLoopGetMain(), kCFRunLoopCommonModes);
      CFStreamError streamError = {0};
      CFNetServiceRegisterWithOptions(_registrationService, 0, &streamError);
      
      _resolutionService = CFNetServiceCreateCopy(kCFAllocatorDefault, _registrationService);
      if (_resolutionService) {
        CFNetServiceSetClient(_resolutionService, _NetServiceResolveCallBack, &context);
        CFNetServiceScheduleWithRunLoop(_resolutionService, CFRunLoopGetMain(), kCFRunLoopCommonModes);
      } else {
        LOG_ERROR(@"Failed creating CFNetService for resolution");
      }
    } else {
      LOG_ERROR(@"Failed creating CFNetService for registration");
    }
  }
  
  if ([_GetOption(_options, GCDWebServerOption_RequestNATPortMapping, @NO) boolValue]) {
    DNSServiceErrorType status = DNSServiceNATPortMappingCreate(&_dnsService, 0, 0, kDNSServiceProtocol_TCP, htons(port), htons(port), 0, _DNSServiceCallBack, (__bridge void*)self);
    if (status == kDNSServiceErr_NoError) {
      CFSocketContext context = {0, (__bridge void*)self, NULL, NULL, NULL};
      _dnsSocket = CFSocketCreateWithNative(kCFAllocatorDefault, DNSServiceRefSockFD(_dnsService), kCFSocketReadCallBack, _SocketCallBack, &context);
      if (_dnsSocket) {
        CFSocketSetSocketFlags(_dnsSocket, CFSocketGetSocketFlags(_dnsSocket) & ~kCFSocketCloseOnInvalidate);
        _dnsSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _dnsSocket, 0);
        if (_dnsSource) {
          CFRunLoopAddSource(CFRunLoopGetMain(), _dnsSource, kCFRunLoopCommonModes);
        } else {
          LOG_ERROR(@"Failed creating CFRunLoopSource");
        }
      } else {
        LOG_ERROR(@"Failed creating CFSocket");
      }
    } else {
      LOG_ERROR(@"Failed creating NAT port mapping (%i)", status);
    }
  }
  
  dispatch_resume(_source4);
  dispatch_resume(_source6);
  LOG_INFO(@"%@ started on port %i and reachable at %@", [self class], (int)_port, self.serverURL);
  if ([_delegate respondsToSelector:@selector(webServerDidStart:)]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [_delegate webServerDidStart:self];
    });
  }
  
  return YES;
}

- (void)_stop {
  
  if (_dnsService) {
    _dnsAddress = nil;
    _dnsPort = 0;
    if (_dnsSource) {
      CFRunLoopSourceInvalidate(_dnsSource);
      CFRelease(_dnsSource);
      _dnsSource = NULL;
    }
    if (_dnsSocket) {
      CFRelease(_dnsSocket);
      _dnsSocket = NULL;
    }
    DNSServiceRefDeallocate(_dnsService);
    _dnsService = NULL;
  }
  
  if (_registrationService) {
    if (_resolutionService) {
      CFNetServiceUnscheduleFromRunLoop(_resolutionService, CFRunLoopGetMain(), kCFRunLoopCommonModes);
      CFNetServiceSetClient(_resolutionService, NULL, NULL);
      CFNetServiceCancel(_resolutionService);
      CFRelease(_resolutionService);
      _resolutionService = NULL;
    }
    CFNetServiceUnscheduleFromRunLoop(_registrationService, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    CFNetServiceSetClient(_registrationService, NULL, NULL);
    CFNetServiceCancel(_registrationService);
    CFRelease(_registrationService);
    _registrationService = NULL;
  }
  
  dispatch_source_cancel(_source6);
  dispatch_source_cancel(_source4);
  dispatch_group_wait(_sourceGroup, DISPATCH_TIME_FOREVER);  // Wait until the cancellation handlers have been called which guarantees the listening sockets are closed
#if !OS_OBJECT_USE_OBJC_RETAIN_RELEASE
  dispatch_release(_source6);
#endif
  _source6 = NULL;
#if !OS_OBJECT_USE_OBJC_RETAIN_RELEASE
  dispatch_release(_source4);
#endif
  _source4 = NULL;
  _port = 0;
  _bindToLocalhost = NO;
  
  _serverName = nil;
  _authenticationRealm = nil;
  _authenticationBasicAccounts = nil;
  _authenticationDigestAccounts = nil;
  
  dispatch_async(dispatch_get_main_queue(), ^{
    if (_disconnectTimer) {
      CFRunLoopTimerInvalidate(_disconnectTimer);
      CFRelease(_disconnectTimer);
      _disconnectTimer = NULL;
      [self _didDisconnect];
    }
  });
  
  LOG_INFO(@"%@ stopped", [self class]);
  if ([_delegate respondsToSelector:@selector(webServerDidStop:)]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [_delegate webServerDidStop:self];
    });
  }
}

- (BOOL)startWithOptions:(NSDictionary*)options error:(NSError**)error {
  if (_options == nil) {
    _options = options ? [options copy] : @{};
    if (![self _start:error])
    {
      _options = nil;
      return NO;
    }
    return YES;
  }
  return NO;
}


- (BOOL)startWithPort:(NSUInteger)port bonjourName:(NSString*)name {
    NSMutableDictionary* options = [NSMutableDictionary dictionary];
    [options setObject:[NSNumber numberWithInteger:port] forKey:GCDWebServerOption_Port];
    [options setValue:name forKey:GCDWebServerOption_BonjourName];
    return [self startWithOptions:options error:NULL];
}

- (BOOL)runWithPort:(NSUInteger)port bonjourName:(NSString*)name {
    NSMutableDictionary* options = [NSMutableDictionary dictionary];
    [options setObject:[NSNumber numberWithInteger:port] forKey:GCDWebServerOption_Port];
    [options setValue:name forKey:GCDWebServerOption_BonjourName];
    return [self runWithOptions:options error:NULL];
}

- (BOOL)runWithOptions:(NSDictionary*)options error:(NSError**)error {
    BOOL success = NO;
    _run = YES;
    void (*termHandler)(int) = signal(SIGTERM, _SignalHandler);
    void (*intHandler)(int) = signal(SIGINT, _SignalHandler);
    if ((termHandler != SIG_ERR) && (intHandler != SIG_ERR)) {
        if ([self startWithOptions:options error:error]) {
            while (_run) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, true);
            }
            [self stop];
            success = YES;
        }
        _ExecuteMainThreadRunLoopSources();
        signal(SIGINT, intHandler);
        signal(SIGTERM, termHandler);
    }
    return success;
}

- (BOOL)isRunning {
  return (_options ? YES : NO);
}

- (void)stop {
  if (_options) {
    if (_source4) {
      [self _stop];
    }
    _options = nil;
  }
}

@end

@implementation GCDWebServer (Handlers)

#pragma mark synchronous

- (void)addHandlerWithMatchBlock:(GCDWebServerMatchBlock)matchBlock processBlock:(GCDWebServerProcessBlock)processBlock {
    [self addHandlerWithMatchBlock:matchBlock asyncProcessBlock:^(GCDWebServerRequest* request, GCDWebServerCompletionBlock completionBlock) {
        completionBlock(processBlock(request));
    }];
}
- (void)addDefaultHandlerForMethod:(NSString*)method requestClass:(Class)aClass processBlock:(GCDWebServerProcessBlock)block {
    [self addDefaultHandlerForMethod:method requestClass:aClass asyncProcessBlock:^(GCDWebServerRequest* request, GCDWebServerCompletionBlock completionBlock) {
        completionBlock(block(request));
    }];
}
- (void)addHandlerForMethod:(NSString*)method path:(NSString*)path requestClass:(Class)aClass processBlock:(GCDWebServerProcessBlock)block {
    [self addHandlerForMethod:method path:path requestClass:aClass asyncProcessBlock:^(GCDWebServerRequest* request, GCDWebServerCompletionBlock completionBlock) {
        completionBlock(block(request));
    }];
}

- (void)addHandlerForMethod:(NSString*)method pathRegex:(NSString*)regex requestClass:(Class)aClass processBlock:(GCDWebServerProcessBlock)block {
    [self addHandlerForMethod:method pathRegex:regex requestClass:aClass asyncProcessBlock:^(GCDWebServerRequest* request, GCDWebServerCompletionBlock completionBlock) {
        completionBlock(block(request));
    }];
}

//JF version of the last methods with NSRegularExpression parameter.
- (void)addHandlerForMethod:(NSString*)method pathRegularExpression:(NSRegularExpression*)pathRegularExpression requestClass:(Class)aClass processBlock:(GCDWebServerProcessBlock)block {
    [self addHandlerForMethod:method pathRegularExpression:pathRegularExpression requestClass:aClass asyncProcessBlock:^(GCDWebServerRequest* request, GCDWebServerCompletionBlock completionBlock) {
        completionBlock(block(request));
    }];
}

#pragma mark asynchronous

- (void)addHandlerWithMatchBlock:(GCDWebServerMatchBlock)matchBlock asyncProcessBlock:(GCDWebServerAsyncProcessBlock)processBlock {
    GCDWebServerHandler* handler = [[GCDWebServerHandler alloc] initWithMatchBlock:matchBlock asyncProcessBlock:processBlock];
    [_handlers insertObject:handler atIndex:0];
}
- (void)addDefaultHandlerForMethod:(NSString*)method requestClass:(Class)aClass asyncProcessBlock:(GCDWebServerAsyncProcessBlock)block {
    [self addHandlerWithMatchBlock:^GCDWebServerRequest *(NSString* requestMethod, NSURL* requestURL, NSDictionary* requestHeaders, NSString* urlPath, NSDictionary* urlQuery) {
        
        if (![requestMethod isEqualToString:method]) {
            return nil;
        }
        return [[aClass alloc] initWithMethod:requestMethod url:requestURL headers:requestHeaders path:urlPath query:urlQuery];
        
    } asyncProcessBlock:block];
}

- (void)addHandlerForMethod:(NSString*)method path:(NSString*)path requestClass:(Class)aClass asyncProcessBlock:(GCDWebServerAsyncProcessBlock)block {
    if ([path hasPrefix:@"/"] && [aClass isSubclassOfClass:[GCDWebServerRequest class]]) {
        [self addHandlerWithMatchBlock:^GCDWebServerRequest *(NSString* requestMethod, NSURL* requestURL, NSDictionary* requestHeaders, NSString* urlPath, NSDictionary* urlQuery) {
            
            if (![requestMethod isEqualToString:method]) {
                return nil;
            }
            if ([urlPath caseInsensitiveCompare:path] != NSOrderedSame) {
                return nil;
            }
            return [[aClass alloc] initWithMethod:requestMethod url:requestURL headers:requestHeaders path:urlPath query:urlQuery];
            
        } asyncProcessBlock:block];
    }
}

- (void)addHandlerForMethod:(NSString*)method pathRegex:(NSString*)regex requestClass:(Class)aClass asyncProcessBlock:(GCDWebServerAsyncProcessBlock)block {
    NSRegularExpression* expression = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:NULL];
    if (expression && [aClass isSubclassOfClass:[GCDWebServerRequest class]]) {
        [self addHandlerWithMatchBlock:^GCDWebServerRequest *(NSString* requestMethod, NSURL* requestURL, NSDictionary* requestHeaders, NSString* urlPath, NSDictionary* urlQuery) {
            
            if (![requestMethod isEqualToString:method]) {
                return nil;
            }
            
            NSArray* matches = [expression matchesInString:urlPath options:0 range:NSMakeRange(0, urlPath.length)];
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
            
            GCDWebServerRequest* request = [[aClass alloc] initWithMethod:requestMethod url:requestURL headers:requestHeaders path:urlPath query:urlQuery];
            [request setAttribute:captures forKey:GCDWebServerRequestAttribute_RegexCaptures];
            return request;
            
        } asyncProcessBlock:block];
    }
}

//JF version of the last methods with NSRegularExpression parameter.
- (void)addHandlerForMethod:(NSString*)method pathRegularExpression:(NSRegularExpression*)pathRegularExpression requestClass:(Class)aClass asyncProcessBlock:(GCDWebServerAsyncProcessBlock)block {
    if (pathRegularExpression && [aClass isSubclassOfClass:[GCDWebServerRequest class]]) {
        [self addHandlerWithMatchBlock:^GCDWebServerRequest *(NSString* requestMethod, NSURL* requestURL, NSDictionary* requestHeaders, NSString* urlPath, NSDictionary* urlQuery) {
            
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
            
            GCDWebServerRequest* request = [[aClass alloc] initWithMethod:requestMethod url:requestURL headers:requestHeaders path:urlPath query:urlQuery];
            [request setAttribute:captures forKey:GCDWebServerRequestAttribute_RegexCaptures];
            return request;
            
        } asyncProcessBlock:block];
    }
}


- (void)removeAllHandlers {
    [_handlers removeAllObjects];
}

@end

@implementation GCDWebServer (GETHandlers)

- (void)addGETHandlerForPath:(NSString*)path staticData:(NSData*)staticData contentType:(NSString*)contentType cacheAge:(NSUInteger)cacheAge {
  [self addHandlerForMethod:@"GET" path:path requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
    
    GCDWebServerResponse* response = [GCDWebServerDataResponse responseWithData:staticData contentType:contentType];
    response.cacheControlMaxAge = cacheAge;
    return response;
    
  }];
}

- (void)addGETHandlerForPath:(NSString*)path filePath:(NSString*)filePath isAttachment:(BOOL)isAttachment cacheAge:(NSUInteger)cacheAge allowRangeRequests:(BOOL)allowRangeRequests {
  [self addHandlerForMethod:@"GET" path:path requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
    
    GCDWebServerResponse* response = nil;
    if (allowRangeRequests) {
      response = [GCDWebServerFileResponse responseWithFile:filePath byteRange:request.byteRange isAttachment:isAttachment];
      [response setValue:@"bytes" forAdditionalHeader:@"Accept-Ranges"];
    } else {
      response = [GCDWebServerFileResponse responseWithFile:filePath isAttachment:isAttachment];
    }
    response.cacheControlMaxAge = cacheAge;
    return response;
    
  }];
}

- (GCDWebServerResponse*)_responseWithContentsOfDirectory:(NSString*)path {
  NSDirectoryEnumerator* enumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
  if (enumerator == nil) {
    return nil;
  }
  NSMutableString* html = [NSMutableString string];
  [html appendString:@"<!DOCTYPE html>\n"];
  [html appendString:@"<html><head><meta charset=\"utf-8\"></head><body>\n"];
  [html appendString:@"<ul>\n"];
  for (NSString* file in enumerator) {
    if (![file hasPrefix:@"."]) {
      NSString* type = [[enumerator fileAttributes] objectForKey:NSFileType];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
      NSString* escapedFile = [file stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#pragma clang diagnostic pop
      if ([type isEqualToString:NSFileTypeRegular]) {
        [html appendFormat:@"<li><a href=\"%@\">%@</a></li>\n", escapedFile, file];
      } else if ([type isEqualToString:NSFileTypeDirectory]) {
        [html appendFormat:@"<li><a href=\"%@/\">%@/</a></li>\n", escapedFile, file];
      }
    }
    [enumerator skipDescendents];
  }
  [html appendString:@"</ul>\n"];
  [html appendString:@"</body></html>\n"];
  return [GCDWebServerDataResponse responseWithHTML:html];
}

- (void)addGETHandlerForBasePath:(NSString*)basePath directoryPath:(NSString*)directoryPath indexFilename:(NSString*)indexFilename cacheAge:(NSUInteger)cacheAge allowRangeRequests:(BOOL)allowRangeRequests {
  if ([basePath hasPrefix:@"/"] && [basePath hasSuffix:@"/"]) {
    GCDWebServer* __unsafe_unretained server = self;
    [self addHandlerWithMatchBlock:^GCDWebServerRequest *(NSString* requestMethod, NSURL* requestURL, NSDictionary* requestHeaders, NSString* urlPath, NSDictionary* urlQuery) {
      
      if (![requestMethod isEqualToString:@"GET"]) {
        return nil;
      }
      if (![urlPath hasPrefix:basePath]) {
        return nil;
      }
      return [[GCDWebServerRequest alloc] initWithMethod:requestMethod url:requestURL headers:requestHeaders path:urlPath query:urlQuery];
      
    } processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
      
      GCDWebServerResponse* response = nil;
      NSString* filePath = [directoryPath stringByAppendingPathComponent:[request.path substringFromIndex:basePath.length]];
      NSString* fileType = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL] fileType];
      if (fileType) {
        if ([fileType isEqualToString:NSFileTypeDirectory]) {
          if (indexFilename) {
            NSString* indexPath = [filePath stringByAppendingPathComponent:indexFilename];
            NSString* indexType = [[[NSFileManager defaultManager] attributesOfItemAtPath:indexPath error:NULL] fileType];
            if ([indexType isEqualToString:NSFileTypeRegular]) {
              return [GCDWebServerFileResponse responseWithFile:indexPath];
            }
          }
          response = [server _responseWithContentsOfDirectory:filePath];
        } else if ([fileType isEqualToString:NSFileTypeRegular]) {
          if (allowRangeRequests) {
            response = [GCDWebServerFileResponse responseWithFile:filePath byteRange:request.byteRange];
            [response setValue:@"bytes" forAdditionalHeader:@"Accept-Ranges"];
          } else {
            response = [GCDWebServerFileResponse responseWithFile:filePath];
          }
        }
      }
      if (response) {
        response.cacheControlMaxAge = cacheAge;
      } else {
          response = [GCDWebServerResponse responseWithStatusCode:404];//NotFound
      }
      return response;
      
    }];
  }
}

@end
