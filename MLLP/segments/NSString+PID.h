#import <Foundation/Foundation.h>

//? = optional (nil accepted)
//NS_ASSUME_NONNULL_BEGIN

@interface  NSString(PID)

//https://dcm4chee-arc-hl7cs.readthedocs.io/en/latest/adt/inbound.html#pid-patient-identification-segment
//https://dcm4chee-arc-hl7cs.readthedocs.io/en/latest/adt/inbound.html#tab-pid-231

+(NSString*)
   PatientIdentifierList   :(NSString*)PID_3 //  ID^^^ISSUER
   PatientName             :(NSString*)PID_5 //  FAMILY1>FAMILY2^GIVEN1 GIVEN2
   MotherMaidenName        :(NSString*)PID_6 //?
   PatientBirthDate        :(NSString*)PID_7 //? AAAAMMDD
   PatientAdministrativeSex:(NSString*)PID_8 //? M | F | O
;

@end
//NS_ASSUME_NONNULL_END
