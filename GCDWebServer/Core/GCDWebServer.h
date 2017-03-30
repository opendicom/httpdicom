#import "GCDWebServerRequest.h"
#import "GCDWebServerResponse.h"
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


/**
 *  The GCDWebServerMatchBlock is called for every handler added to the
 *  GCDWebServer whenever a new HTTP request has started (i.e. HTTP headers have
 *  been received). The block is passed the basic info for the request (HTTP method,
 *  URL, headers...) and must decide if it wants to handle it or not.
 *
 *  If the handler can handle the request, the block must return a new
 *  GCDWebServerRequest instance created with the same basic info.
 *  Otherwise, it simply returns nil.
 */
typedef GCDWebServerRequest* (^GCDWebServerMatchBlock)(NSString* requestMethod, NSURL* requestURL, NSDictionary* requestHeaders, NSString* urlPath, NSDictionary* urlQuery);

/**
 *  The GCDWebServerProcessBlock is called after the HTTP request has been fully
 *  received (i.e. the entire HTTP body has been read). The block is passed the
 *  GCDWebServerRequest created at the previous step by the GCDWebServerMatchBlock.
 *
 *  The block must return a GCDWebServerResponse or nil on error, which will
 *  result in a 500 HTTP status code returned to the client. It's however
 *  recommended to return a GCDWebServerErrorResponse on error so more useful
 *  information can be returned to the client.
 */
typedef GCDWebServerResponse* (^GCDWebServerProcessBlock)(__kindof GCDWebServerRequest* request);

/**
 *  The GCDWebServerAsynchronousProcessBlock works like the GCDWebServerProcessBlock
 *  except the GCDWebServerResponse can be returned to the server at a later time
 *  allowing for asynchronous generation of the response.
 *
 *  The block must eventually call "completionBlock" passing a GCDWebServerResponse
 *  or nil on error, which will result in a 500 HTTP status code returned to the client.
 *  It's however recommended to return a GCDWebServerErrorResponse on error so more
 *  useful information can be returned to the client.
 */
typedef void (^GCDWebServerCompletionBlock)(GCDWebServerResponse* response);
typedef void (^GCDWebServerAsyncProcessBlock)(__kindof GCDWebServerRequest* request, GCDWebServerCompletionBlock completionBlock);


/**
 *  The GCDWebServer class listens for incoming HTTP requests on a given port,
 *  then passes each one to a "handler" capable of generating an HTTP response
 *  for it, which is then sent back to the client.
 *
 *  GCDWebServer instances can be created and used from any thread but it's
 *  recommended to have the main thread's runloop be running so internal callbacks
 *  can be handled e.g. for Bonjour registration.
 *
 *  See the README.md file for more information about the architecture of GCDWebServer.
 */
@interface GCDWebServer : NSObject
@property(nonatomic, readonly) NSUInteger port;

- (instancetype)init;//designated initializer
//Returns NO if the server failed to start and sets "error" argument if not NULL.
- (BOOL)startWithPort:(NSUInteger)port maxPendingConnections:(NSUInteger)maxPendingConnections error:(NSError**)error;
@end

@interface GCDWebServer ()
@property(nonatomic, readonly) NSArray* handlers;
@property(nonatomic, readonly) NSString* serverName;
@property(nonatomic, readonly) NSString* authenticationRealm;
@property(nonatomic, readonly) NSDictionary* authenticationBasicAccounts;
@property(nonatomic, readonly) NSDictionary* authenticationDigestAccounts;
@end

@interface GCDWebServer (Handlers)

#pragma mark synchronous
- (void)addDefaultHandlerForMethod:(NSString*)method requestClass:(Class)aClass processBlock:(GCDWebServerProcessBlock)processBlock;
//specific case-insensitive path
- (void)addHandlerForMethod:(NSString*)method path:(NSString*)path requestClass:(Class)aClass processBlock:(GCDWebServerProcessBlock)processBlock;
/**
 * NSRegularExpression* pathRegularExpression = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:NULL];
 * may be initiated only once for every aplication of the pattern
 */
- (void)addHandlerForMethod:(NSString*)method pathRegularExpression:(NSRegularExpression*)pathRegularExpression requestClass:(Class)aClass processBlock:(GCDWebServerProcessBlock)processBlock;


#pragma mark asynchronous
- (void)addHandlerWithMatchBlock:(GCDWebServerMatchBlock)matchBlock asyncProcessBlock:(GCDWebServerAsyncProcessBlock)processBlock;
- (void)addDefaultHandlerForMethod:(NSString*)method requestClass:(Class)aClass asyncProcessBlock:(GCDWebServerAsyncProcessBlock)block;
//specific case-insensitive path
- (void)addHandlerForMethod:(NSString*)method path:(NSString*)path requestClass:(Class)aClass asyncProcessBlock:(GCDWebServerAsyncProcessBlock)block;
/**
 * NSRegularExpression* pathRegularExpression = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:NULL];
 * may be initiated only once por every aplication of the pattern
 */
- (void)addHandlerForMethod:(NSString*)method pathRegularExpression:(NSRegularExpression*)pathRegularExpression requestClass:(Class)aClass asyncProcessBlock:(GCDWebServerAsyncProcessBlock)block;


- (void)removeAllHandlers;

@end

@interface GCDWebServer (GETHandlers)

/**
 *  Adds a handler to the server to respond to incoming "GET" HTTP requests
 *  with a specific case-insensitive path with in-memory data.
 */
- (void)addGETHandlerForPath:(NSString*)path staticData:(NSData*)staticData contentType:(NSString*)contentType cacheAge:(NSUInteger)cacheAge;

/**
 *  Adds a handler to the server to respond to incoming "GET" HTTP requests
 *  with a specific case-insensitive path with a file.
 */
- (void)addGETHandlerForPath:(NSString*)path filePath:(NSString*)filePath isAttachment:(BOOL)isAttachment cacheAge:(NSUInteger)cacheAge allowRangeRequests:(BOOL)allowRangeRequests;

@end

@interface GCDWebServerHandler : NSObject
@property(nonatomic, readonly) GCDWebServerMatchBlock matchBlock;
@property(nonatomic, readonly) GCDWebServerAsyncProcessBlock asyncProcessBlock;
@end
