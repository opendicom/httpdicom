#import "PID.h"

@implementation PID

+(NSString*)
   PatientIdentifierList:(NSString*)PID_3
   AlternatePatientID   :(NSString*)PID_4
   PatientName          :(NSString*)PID_5
   MotherMaidenName     :(NSString*)PID_6
   PatientBirthDate     :(NSString*)PID_7
   PatientSex           :(NSString*)PID_8
   PatientAlias         :(NSString*)PID_9
{
   if (!PID_3 || !PID_5) return nil;
   
   if (!PID_4)PID_4=@"";
   if (!PID_6)PID_6=@"";
   if (!PID_7)PID_7=@"";
   if (!PID_8)PID_8=@"";
   if (!PID_9)PID_9=@"";
   
   return [NSString stringWithFormat:
           @"PID|||%@|%@|%@|%@|%@|%@|%@",
           PID_3,
           PID_4,
           PID_5,
           PID_6,
           PID_7,
           PID_8,
           PID_9
           ];
}

@end
