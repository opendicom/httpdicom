#import "A01.h"

#import "MSH.h"
#import "PID.h"

@implementation A01

+(NSString*)admitInpatient:(NSString*)VersionID
   sendingRisName         :(NSString*)MSH_3
   sendingRisIP           :(NSString*)MSH_4
   receivingCustodianTitle:(NSString*)MSH_5
   receivingPacsaet       :(NSString*)MSH_6
   MessageControlId       :(NSString*)MSH_10
   CountryCode            :(NSString*)MSH_17
   stringEncoding         :(NSStringEncoding)stringEncoding //MSH_18 00080005
   PrincipalLanguage      :(NSString*)MSH_19
   PatientIdentifierList  :(NSString*)PID_3 //00100020+00100021
   PatientName            :(NSString*)PID_5 //00100010
   PatientBirthDate       :(NSString*)PID_7 //00100030
   PatientSex             :(NSString*)PID_8 //00100040
{
   
    NSString * MSH = [MSH
     SendingApplication  :MSH_3
     SendingFacility     :MSH_4
     ReceivingApplication:MSH_5
     ReceivingFacility   :MSH_6
     MessageType         :@"ADT^A01^ADT_A01"
     MessageControlID    :MSH_10
     VersionID           :VersionID
     CountryCode         :MSH_17
     CharacterSet        :stringEncoding
     PrincipalLanguage   :MSH_19
     ]
    ];
   if (!MSH)return nil;
   
      
   NSString * PID = [PID
     PatientIdentifierList:PID_3
     AlternatePatientID   :nil
     PatientName          :PID_5
     MotherMaidenName     :nil
     PatientBirthDate     :PID_7
     PatientSex           :PID_8
     PatientAlias         :nil
     ]
    ];
   if (!PID) return nil;

   return [NSString stringWithFormat:@"%@\r%@\r",MSH,PID];
}
@end
