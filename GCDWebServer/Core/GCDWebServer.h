#import "GCDWebServerHandler.h"
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
{
    @private
    dispatch_queue_t _syncQueue;
    dispatch_group_t _sourceGroup;
    NSMutableArray* _handlers;
    NSInteger _activeConnections;  // Accessed through _syncQueue only
    BOOL _connected;  // Accessed on main thread only
    
    NSDictionary* _options;
    NSString* _serverName;
    NSString* _authenticationRealm;
    NSMutableDictionary* _authenticationBasicAccounts;
    NSMutableDictionary* _authenticationDigestAccounts;
    Class _connectionClass;
    NSUInteger _port;
    dispatch_source_t _source4;
    dispatch_source_t _source6;
}

@property(nonatomic, readonly) NSUInteger port;
@property(nonatomic, readonly) NSArray* handlers;
@property(nonatomic, readonly) NSString* serverName;

- (instancetype)init;//designated initializer
//Returns NO if the server failed to start and sets "error" argument if not NULL.
- (BOOL)startWithPort:(NSUInteger)port maxPendingConnections:(NSUInteger)maxPendingConnections error:(NSError**)error;

#pragma mark asynchronous

- (void)addDefaultHandlerForMethod:(NSString*)method
                 asyncProcessBlock:(GCDWebServerAsyncProcessBlock)block;


- (void)addHandlerForMethod:(NSString*)method
                       path:(NSString*)path
          asyncProcessBlock:(GCDWebServerAsyncProcessBlock)block;


- (void)addHandlerForMethod:(NSString*)method
      pathRegularExpression:(NSRegularExpression*)pathRegularExpression asyncProcessBlock:(GCDWebServerAsyncProcessBlock)block;


#pragma mark root method invoked by asynchronous

- (void)addHandlerWithMatchBlock:(GCDWebServerMatchBlock)matchBlock
               asyncProcessBlock:(GCDWebServerAsyncProcessBlock)processBlock;

@end

