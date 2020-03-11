#import "NSURLSessionDataTask+DRS.h"
#import "RequestWadouri.h"

//NS_ASSUME_NONNULL_BEGIN

@interface ResponseWadouri : NSObject


+(NSData*)objectFromPacs:(NSDictionary*)pacs
                    EUID:(NSString*)euid
                    SUID:(NSString*)suid
                    IUID:(NSString*)iuid
         acceptMediaType:(NSString*)mediaType
;

+(NSData*)XMLStringFromPacs:(NSDictionary*)pacs                                         EUID:(NSString*)euid
                       SUID:(NSString*)suid
                       IUID:(NSString*)iuid

;
@end

//NS_ASSUME_NONNULL_END
