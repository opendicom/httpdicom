#import "NSString+MSH.h" //#import "NSString+A04.h"
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
                     sendingApplication  :MSH_3
                     sendingFacility     :MSH_4
                     receivingApplication:MSH_5
                     receivingFacility   :MSH_6
                     messageType         :@"ADT^A04^ADT_A01"
                     messageControlID    :MSH_10
                     versionID           :VersionID
                     countryCode         :MSH_17
                     stringEncoding      :stringEncoding
                     principalLanguage   :MSH_19
                     ];
   if (!MSH)return nil;
   
   
   NSString * PID = [NSString
                     patIdentifierList      :PID_3
                     patName                :PID_5
                     patMotherMaidenName    :nil
                     patBirthDate           :PID_7
                     patAdministrativeGender:PID_8
                     ];
   if (!PID) return nil;
   
   return [NSString stringWithFormat:@"%@\r%@\r",MSH,PID];
}
@end
