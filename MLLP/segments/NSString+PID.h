#import <Foundation/Foundation.h>

//? = optional (nil accepted)
//NS_ASSUME_NONNULL_BEGIN

@interface  NSString(PID)

//https://dcm4chee-arc-hl7cs.readthedocs.io/en/latest/adt/inbound.html#pid-patient-identification-segment
//https://dcm4chee-arc-hl7cs.readthedocs.io/en/latest/adt/inbound.html#tab-pid-231

+(NSString*)
   patIdentifierList      :(NSString*)PID_3 //  ID^^^ISSUER
   patName                :(NSString*)PID_5 //  FAMILY1>FAMILY2^GIVEN1 GIVEN2
   patMotherMaidenName    :(NSString*)PID_6 //?
   patBirthDate           :(NSString*)PID_7 //? AAAAMMDD
   patAdministrativeGender:(NSString*)PID_8 //? M | F | O
;

@end
//NS_ASSUME_NONNULL_END
