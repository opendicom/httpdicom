#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface NSMutableURLRequest (core)

//completes requests with cachePolicy and timeout

//contentType and accept refer to media-type
//   contentType is of the request
//   accept is what is expected from the response

//in the case of WADOURI,
//   leave contentType empty (@"") and
//   put the value for the eventual parameter "contentType" into accept

//cachePolicy 0 defaults to NSURLRequestReloadIgnoringCacheData

//timeout 0 defaults to 10 seconds (look at const here above)

typedef NS_ENUM(NSUInteger, HTTPRequestMethod) {
   GET = 0,
   HEAD,
   POST,
   PUT,
   DELETE,
   CONNECT,
   OPTIONS,
   TRACE,
   PATCH
};

+(NSMutableURLRequest*)DRSRequestPacs:(NSDictionary*)pacs
                            URLString:(NSMutableString*)URLString
                               method:(HTTPRequestMethod)method
                          contentType:(NSString*)contentType
                             bodyData:(NSData*)bodyData
                               accept:(NSString*)accept
;


+(NSMutableURLRequest*)DRSRequestPacs:(NSDictionary*)pacs
                            URLString:(NSMutableString*)URLString
                               method:(HTTPRequestMethod)method
                          contentType:(NSString*)contentType
                             bodyData:(NSData*)bodyData
;

+(NSMutableURLRequest*)DRSRequestPacs:(NSDictionary*)pacs
                            URLString:(NSMutableString*)URLString
                               method:(HTTPRequestMethod)method
                               accept:(NSString*)accept
;

+(NSMutableURLRequest*)DRSRequestPacs:(NSDictionary*)pacs
                            URLString:(NSMutableString*)URLString
                               method:(HTTPRequestMethod)method
;

@end

NS_ASSUME_NONNULL_END
