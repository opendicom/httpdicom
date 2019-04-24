#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RequestMWL : NSObject

+(id)postToPacs:(NSDictionary*)pacs
             CS:(NSString*)CS
            aet:(NSString*)aet
             DA:(NSString*)DA
             TM:(NSString*)TM
             TZ:(NSString*)TZ
       modality:(NSString*)modality
accessionNumber:(NSString*)accessionNumber
      referring:(NSString*)referring
         status:(NSString*)status
studyDescription:(NSString*)studyDescription
       priority:(NSString*)priority
           name:(NSString*)name
            pid:(NSString*)pid
         issuer:(NSString*)issuer
      birthdate:(NSString*)birthdate
            sex:(NSString*)sex
    contentType:(NSString*)contentType
;

@end

NS_ASSUME_NONNULL_END
