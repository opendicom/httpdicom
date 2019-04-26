#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RequestPatient : NSObject

+(NSMutableURLRequest*)getFromPacs:(NSDictionary*)pacs
                               pid:(NSString*)pid
                            issuer:(NSString*)issuer
;

//DO NOT USE because dcm4chee-arc rest patient API doesn´t support latin1 encoding
//USE instead HL7 MLLP ADT
+(NSMutableURLRequest*)putToPacs:(NSDictionary*)pacs
                            name:(NSString*)name
                             pid:(NSString*)pid
                          issuer:(NSString*)issuer
                       birthdate:(NSString*)birthdate
                             sex:(NSString*)sex
                     contentType:(NSString*)contentType
;

+(NSMutableURLRequest*)postHtml5dicomuserForPacs:(NSDictionary*)pacs
                                     institution:(NSString*)institution
                                        username:(NSString*)username
                                        password:(NSString*)password
                                       firstname:(NSString*)firstname
                                        lastname:(NSString*)lastname
                                        isactive:(BOOL)isactive
;

@end

NS_ASSUME_NONNULL_END
