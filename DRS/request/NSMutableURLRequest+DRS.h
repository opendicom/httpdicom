#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NSTimeInterval const defaultTimeout=10;


@interface NSMutableURLRequest (core)

//to be used by all categories once the URL part of the request is defined, so that default cachePolicy and timeout are set if necesary
//contentType and accept refer to media-type
//contentType is of the request
//accept is what is expected from the response
//in the case of WADOURI, leave contentType nil and put the value for the eventual parameter "contentType" into accept
//cachePolicy 0 defaults to NSURLRequestReloadIgnoringCacheData
//timeout 0 defaults to 10 seconds (look at const here above)

+(NSMutableURLRequest*)DRSRequestPacs:(NSDictionary*)pacs
                            URLString:(NSMutableString*)URLString
                               method:(NSString*)method
                          contentType:(NSString*)contentType
                             bodyData:(NSData*)bodyData
                               accept:(NSString*)accept
;

@end

NS_ASSUME_NONNULL_END
