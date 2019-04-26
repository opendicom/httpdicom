#import "NSURLSessionDataTask+DRS.h"

NS_ASSUME_NONNULL_BEGIN

@interface ResponsePatient : NSObject

+(NSArray*)getFromPacs:(NSDictionary*)pacs
                   pid:(NSString*)pid
                issuer:(NSString*)issuer
;

+(NSString*)putToPacs:(NSDictionary*)pacs
                 name:(NSString*)name
                  pid:(NSString*)pid
               issuer:(NSString*)issuer
            birthdate:(NSString*)birthdate
                  sex:(NSString*)sex
          contentType:(NSString*)contentType
;

+(NSString*)postHtml5dicomuserForPacs:(NSDictionary*)pacs
                          institution:(NSString*)institution
                             username:(NSString*)username
                             password:(NSString*)password
                            firstname:(NSString*)firstname
                             lastname:(NSString*)lastname
                             isactive:(BOOL)isactive
;

@end

NS_ASSUME_NONNULL_END
