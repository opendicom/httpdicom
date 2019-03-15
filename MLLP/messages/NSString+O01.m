#import "NSString+O01.h"

#import "NSString+MSH.h"
#import "NSString+PID.h"
#import "NSString+PV1.h"
#import "NSString+ORC.h"
#import "NSString+OBR.h"
#import "NSString+ZDS.h"

@implementation NSString(O01)

+(NSString*)singleSps          :(NSString*)VersionID
sendingRisName                 :(NSString*)MSH_3
sendingRisIP                   :(NSString*)MSH_4
receivingCustodianTitle        :(NSString*)MSH_5
receivingPacsaet               :(NSString*)MSH_6
MessageControlId               :(NSString*)MSH_10
CountryCode                    :(NSString*)MSH_17
stringEncoding                 :(NSStringEncoding)stringEncoding
PrincipalLanguage              :(NSString*)MSH_19
PatientIdentifierList          :(NSString*)PID_3
PatientName                    :(NSString*)PID_5
MotherMaidenName               :(NSString*)PID_6
PatientBirthDate               :(NSString*)PID_7
PatientAdministrativeSex       :(NSString*)PID_8
isrPatientInsuranceShortName   :(NSString*)PV1_8
isrPlacerNumber                :(NSString*)ORC_2
isrFillerNumber                :(NSString*)ORC_3
spsOrderStatus                 :(NSString*)ORC_5
spsDateTime                    :(NSString*)ORC_7
rpPriority                     :(NSString*)ORC_7_
spsProtocolCode                :(NSString*)OBR_4
isrDangerCode                  :(NSString*)OBR_12
isrRelevantClinicalInfo        :(NSString*)OBR_13
isrReferringPhysician          :(NSString*)OBR_16
isrAccessionNumber             :(NSString*)OBR_18
rpID                           :(NSString*)OBR_19
spsID                          :(NSString*)OBR_20
spsStationAETitle              :(NSString*)OBR_21
spsModality                    :(NSString*)OBR_24
rpTransportationMode           :(NSString*)OBR_30
rpReasonForStudy               :(NSString*)OBR_31
isrNameOfPhysiciansReadingStudy:(NSString*)OBR_32
spsTechnician                  :(NSString*)OBR_34
rpUniversalStudyCode           :(NSString*)OBR_44
isrStudyInstanceUID            :(NSString*)ZDS_1 
{
   
   NSString * MSH = [NSString
    SendingApplication  :MSH_3
    SendingFacility     :MSH_4
    ReceivingApplication:MSH_5
    ReceivingFacility   :MSH_6
    MessageType         :@"ORM^O01"
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


   NSString * PV1 = [NSString
    VisitNumber      :PV1_8
    ReferringDoctor  :@""
    AmbultatoryStatus:@""
    ];
   if (!PV1) return nil;
   

   
   NSString * ORC = [NSString
    OrderControl        :@"NW"
    sendingRisName      :ORC_2
    receivingPacsaet    :ORC_3
    isrPlacerDT         :nil
    isrFillerScheduledDT:ORC_7
    spsOrderStatus      :ORC_5
    spsDateTime         :ORC_7
    rpPriority          :ORC_7_
    EnteringDevice      :MSH_4
    ];
   if (!ORC) return nil;

   
   NSString * OBR= [NSString
    spsProtocolCode                :OBR_4
    isrDangerCode                  :OBR_12
    isrRelevantClinicalInfo        :OBR_13
    isrReferringPhysician          :OBR_16
    isrAccessionNumber             :OBR_18
    rpID                           :OBR_19
    spsID                          :OBR_20
    spsStationAETitle              :OBR_21
    spsModality                    :OBR_24
    rpTransportationMode           :OBR_30
    rpReasonForStudy               :OBR_31
    isrNameOfPhysiciansReadingStudy:OBR_32
    spsTechnician                  :OBR_34
    rpUniversalStudyCode           :OBR_44
    ];
   if (!OBR) return nil;
   


   NSString * ZDS = [NSString
    StudyInstanceUID:ZDS_1
    ];
   if (!ZDS) return nil;


   return [NSString stringWithFormat:@"%@\r%@\r%@\r%@\r%@\r%@\r",MSH,PID,PV1,ORC,OBR,ZDS];
}
@end
