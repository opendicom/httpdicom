#import "NSString+A04.h"

#import "NSString+MSH.h"
#import "NSString+PID.h"

@implementation NSString(A04)

+(NSString*)registerPatient:(NSString*)VersionID
   sendingRisName          :(NSString*)MSH_3
   sendingRisIP            :(NSString*)MSH_4
   receivingCustodianTitle :(NSString*)MSH_5
   receivingPacsaet        :(NSString*)MSH_6
   MessageControlId        :(NSString*)MSH_10
   CountryCode             :(NSString*)MSH_17
   stringEncoding          :(NSStringEncoding)stringEncoding
   PrincipalLanguage       :(NSString*)MSH_19
   PatientIdentifierList   :(NSString*)PID_3
   PatientName             :(NSString*)PID_5
   MotherMaidenName        :(NSString*)PID_6
   PatientBirthDate        :(NSString*)PID_7
   PatientAdministrativeSex:(NSString*)PID_8
{
   
   NSString * MSH = [NSString
                     SendingApplication  :MSH_3
                     SendingFacility     :MSH_4
                     ReceivingApplication:MSH_5
                     ReceivingFacility   :MSH_6
                     MessageType         :@"ADT^A04^ADT_A01"
                     MessageControlID    :MSH_10
                     VersionID           :VersionID
                     CountryCode         :MSH_17
                     CharacterSet        :stringEncoding
                     PrincipalLanguage   :MSH_19
                     ];
   if (!MSH)return nil;
   
   
   NSString * PID = [NSString
                     PatientIdentifierList   :PID_3
                     PatientName             :PID_5
                     MotherMaidenName        :nil
                     PatientBirthDate        :PID_7
                     PatientAdministrativeSex:PID_8
                     ];
   if (!PID) return nil;
   
   return [NSString stringWithFormat:@"%@\r%@\r",MSH,PID];
}
@end
