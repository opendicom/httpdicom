#import "NSURLSessionDataTask+DRS.h"
#import "RequestWadouri.h"

//NS_ASSUME_NONNULL_BEGIN

@interface ResponseWadouri : NSObject


//part 18 B.4 DICOM Media Type
//&contentType=application%2Fdicom

+(NSData*)DICMFromPacs:(NSDictionary*)pacs
                  EUID:(NSString*)euid
                  SUID:(NSString*)suid
                  IUID:(NSString*)iuid
                  anonymize:(BOOL)anonymize
                  transferSyntax:(NSString*)transferSyntax
;
+(NSData*)DICMFromPacs:(NSDictionary*)pacs
                  EUID:(NSString*)euid
                  SUID:(NSString*)suid
                  IUID:(NSString*)iuid
;



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
