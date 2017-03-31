#import "RSRequest.h"
#import "RSResponse.h"

typedef void (^RSCompletionBlock)(RSResponse* response);
typedef void (^RSAsyncProcessBlock)(RSRequest* request, RSCompletionBlock completionBlock);

/*
 The RSMatchBlock is called for every handler added to the RS whenever a new HTTP request has started. The block is passed the basic info for the request and must decide if it wants to handle it or not.
 If the handler can handle the request, the block must return a new RSRequest instance created with the same basic info.
 Otherwise, it simply returns nil.
 */
typedef RSRequest* (^RSMatchBlock)(NSString* requestMethod, NSURL* requestURL, NSDictionary* requestHeaders, NSString* urlPath, NSDictionary* urlQuery);

/**
 *  The RSProcessBlock is called after the HTTP request has been fully
 *  received (i.e. the entire HTTP body has been read). The block is passed the
 *  RSRequest created at the previous step by the RSMatchBlock.
 *
 *  The block must return a RSResponse or nil on error, which will
 *  result in a 500 HTTP status code returned to the client. It's however
 *  recommended to return a RSErrorResponse on error so more useful
 *  information can be returned to the client.
 */
typedef RSResponse* (^RSProcessBlock)(RSRequest* request);


@interface RSHandler : NSObject
{
    @private
    RSMatchBlock _matchBlock;
    RSAsyncProcessBlock _asyncProcessBlock;
}

@property(nonatomic, readonly) RSMatchBlock matchBlock;
@property(nonatomic, readonly) RSAsyncProcessBlock asyncProcessBlock;

- (id)initWithMatchBlock:(RSMatchBlock)matchBlock
       asyncProcessBlock:(RSAsyncProcessBlock)processBlock;

@end
