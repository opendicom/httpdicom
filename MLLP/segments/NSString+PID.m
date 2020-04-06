#import "NSString+PID.h"

@implementation NSString(PID)

+(NSString*)
   patIdentifierList      :(NSString*)PID_3 //  ID^^^ISSUER
   patName                :(NSString*)PID_5 //  FAMILY1>FAMILY2^GIVEN1 GIVEN2
   patMotherMaidenName    :(NSString*)PID_6 //?
   patBirthDate           :(NSString*)PID_7 //? AAAAMMDD
   patAdministrativeGender:(NSString*)PID_8 //? M | F | O
{
   if (!PID_3 || !PID_5)
   {
      NSLog(@"WARN: [PID] PatientIdentifierList (PID_3) and PatientName (PID_5)");
      return nil;
   }
   
   if (!PID_6)PID_6=@"";
   if (!PID_7)PID_7=@"";
   if (!PID_8)PID_8=@"";
   
   return [NSString stringWithFormat:
           @"PID|||%@||%@|%@|%@|%@",
           PID_3,
           PID_5,
           PID_6,
           PID_7,
           PID_8
           ];
}

@end
