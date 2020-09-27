#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RequestPatients : NSObject


+(NSMutableURLRequest*)getFromPacs:(NSDictionary*)pacs
                             patID:(NSString*)patID
                            issuer:(NSString*)issuer
;

//DO NOT USE because dcm4chee-arc rest patient API doesn´t support latin1 encoding
//USE instead HL7 MLLP ADT
+(NSMutableURLRequest*)putToPacs:(NSDictionary*)pacs
                         family1:(NSString*)family1
                         family2:(NSString*)family2
                           given:(NSString*)given
                           patID:(NSString*)patID
                          issuer:(NSString*)issuer
                       birthdate:(NSString*)birthdate
                             sex:(NSString*)sex
                     contentType:(NSString*)contentType
;

+(NSMutableURLRequest*):(NSDictionary*)pacs
                                     institution:(NSString*)institution
                                        username:(NSString*)username
                                        password:(NSString*)password
                                       firstname:(NSString*)firstname
                                        lastname:(NSString*)lastname
                                        isactive:(BOOL)isactive
;

/*
 +(NSMutableURLRequest*)postHtml5dicomuserForPacs:(NSDictionary*)pacs
                                      institution:(NSString*)institution
                                         username:(NSString*)username
                                         password:(NSString*)password
                                        firstname:(NSString*)firstname
                                         lastname:(NSString*)lastname
                                         isactive:(BOOL)isactive
 ;


 */
@end

NS_ASSUME_NONNULL_END
