#import "NSURLSessionDataTask+DRS.h"

NS_ASSUME_NONNULL_BEGIN

@interface ResponsePatients : NSObject

// [] no existe
// [{}] existe y es único
// [{},{}...] existen y no son únicos
+(NSArray*)getFromPacs:(NSDictionary*)pacs
                 patID:(NSString*)patID
                issuer:(NSString*)issuer
;

//returns nil if the request could not be performed
//returns @"" when the patient was registered
//returns @"error message" if the server responded with an error
+(NSString*)putToPacs:(NSDictionary*)pacs
              family1:(NSString*)family1
              family2:(NSString*)family2
                given:(NSString*)given
                patID:(NSString*)patID
               issuer:(NSString*)issuer
            birthdate:(NSString*)birthdate
                  sex:(NSString*)sex
          contentType:(NSString*)contentType
;

/*
+(NSString*)postHtml5dicomuserForPacs:(NSDictionary*)pacs
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
