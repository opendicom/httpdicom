#import "GCDWebServerRequest.h"
#import "GCDWebServerResponse.h"

typedef void (^GCDWebServerCompletionBlock)(GCDWebServerResponse* response);
typedef void (^GCDWebServerAsyncProcessBlock)(GCDWebServerRequest* request, GCDWebServerCompletionBlock completionBlock);

/*
 The GCDWebServerMatchBlock is called for every handler added to the GCDWebServer whenever a new HTTP request has started. The block is passed the basic info for the request and must decide if it wants to handle it or not.
 If the handler can handle the request, the block must return a new GCDWebServerRequest instance created with the same basic info.
 Otherwise, it simply returns nil.
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


@interface GCDWebServerHandler : NSObject
{
    @private
    GCDWebServerMatchBlock _matchBlock;
    GCDWebServerAsyncProcessBlock _asyncProcessBlock;
}

@property(nonatomic, readonly) GCDWebServerMatchBlock matchBlock;
@property(nonatomic, readonly) GCDWebServerAsyncProcessBlock asyncProcessBlock;

- (id)initWithMatchBlock:(GCDWebServerMatchBlock)matchBlock
       asyncProcessBlock:(GCDWebServerAsyncProcessBlock)processBlock;

@end
