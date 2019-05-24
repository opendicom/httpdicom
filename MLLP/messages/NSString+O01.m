#import "NSString+O01.h"

#import "NSString+MSH.h"
#import "NSString+PID.h"
#import "NSString+PV1.h"
#import "NSString+ORC.h"
#import "NSString+OBR.h"
#import "NSString+ZDS.h"

@implementation NSString(O01)
/*
+(NSString*)O01version         :(NSString*)VersionID //?
sendingRisName                 :(NSString*)MSH_3 //?
sendingRisIP                   :(NSString*)MSH_4 //?
receivingCustodianTitle        :(NSString*)MSH_5 //?
receivingPacsaet               :(NSString*)MSH_6 //?
messageControlId               :(NSString*)MSH_10 //?
countryCode                    :(NSString*)MSH_17 //?
stringEncoding                 :(NSStringEncoding)stringEncoding //? MSH_18 00080005
principalLanguage              :(NSString*)MSH_19 //?
patIdentifierList              :(NSString*)PID_3 //  00100020+00100021
patName                        :(NSString*)PID_5 //  00100010
patMotherMaidenName            :(NSString*)PID_6 //? 00101060
patBirthDate                   :(NSString*)PID_7 //? 00100030
patAdministrativeGender        :(NSString*)PID_8 //? 00100040
isrPatientInsuranceShortName   :(NSString*)PV1_8 //00080090 ReferringPhysicianName
isrPlacerNumber                :(NSString*)ORC_2 //00402016
isrFillerNumber                :(NSString*)ORC_3 //00402017
spsOrderStatus                 :(NSString*)ORC_5 //00400020*
spsDateTime                    :(NSString*)ORC_7 //00400002+00400003*
reqPriority                    :(NSString*)ORC_7_ //00401003
sps1ProtocolCode               :(NSString*)sps1_OBR_4  //00400008(00040007)
sps2ProtocolCode               :(NSString*)sps2_OBR_4  //00400008(00040007)
sps3ProtocolCode               :(NSString*)sps3_OBR_4  //00400008(00040007)
sps4ProtocolCode               :(NSString*)sps4_OBR_4  //00400008(00040007)
isrDangerCode                  :(NSString*)OBR_12 //00380500
isrRelevantClinicalInfo        :(NSString*)OBR_13 //00102000
isrReferringPhysician          :(NSString*)OBR_16 //00321032 RequestingPhysician
isrAccessionNumber             :(NSString*)OBR_18 //00080050*
reqID                          :(NSString*)OBR_19 //00401001
sps1ID                         :(NSString*)sps1_OBR_20 //00400009
sps2ID                         :(NSString*)sps2_OBR_20 //00400009
sps3ID                         :(NSString*)sps3_OBR_20 //00400009
sps4ID                         :(NSString*)sps4_OBR_20 //00400009
sps1StationAETitle             :(NSString*)sps1_OBR_21 //00400001*
sps2StationAETitle             :(NSString*)sps2_OBR_21 //00400001*
sps3StationAETitle             :(NSString*)sps3_OBR_21 //00400001*
sps4StationAETitle             :(NSString*)sps4_OBR_21 //00400001*
sps1Modality                   :(NSString*)sps1_OBR_24 //00080060*
sps2Modality                   :(NSString*)sps2_OBR_24 //00080060*
sps3Modality                   :(NSString*)sps3_OBR_24 //00080060*
sps4Modality                   :(NSString*)sps4_OBR_24 //00080060*
reqTransportationMode           :(NSString*)OBR_30 //00401004
reqReasonForStudy               :(NSString*)OBR_31              //00401002
isrNameOfPhysiciansReadingStudy:(NSString*)OBR_32  //00081060*
spsTechnician                  :(NSString*)OBR_34 //00400006 (PerformingPhysicianName)
reqUniversalStudyCode           :(NSString*)OBR_44 //00321064(00321060)
isrStudyInstanceUID            :(NSString*)ZDS_1  //0020000D
*/

+(NSString*)O01version :(NSString*)VersionID
sendingApplication     :(NSString*)MSH_3
sendingFacility        :(NSString*)MSH_4
receivingApplication   :(NSString*)MSH_5
receivingFacility      :(NSString*)MSH_6
messageControlId       :(NSString*)MSH_10
countryCode            :(NSString*)MSH_17
stringEncoding         :(NSStringEncoding)stringEncoding
principalLanguage      :(NSString*)MSH_19
patIdentifierList      :(NSString*)PID_3
patName                :(NSString*)PID_5
patMotherMaidenName    :(NSString*)PID_6
patBirthDate           :(NSString*)PID_7
patAdministrativeGender:(NSString*)PID_8
isrInsurance           :(NSString*)PV1_8
isrPlacerNumber        :(NSString*)ORC_2
isrFillerNumber        :(NSString*)ORC_3
isrAN                  :(NSString*)OBR_18
isrReferring           :(NSString*)OBR_16
isrReading             :(NSString*)OBR_32
isrStudyIUID           :(NSString*)ZDS_1
reqID                  :(NSString*)OBR_19
reqProcedure           :(NSString*)OBR_44
reqPriority            :(NSString*)ORC_7_
spsDateTime            :(NSString*)ORC_7
spsPerforming          :(NSString*)OBR_34
sps1ID                 :(NSString*)sps1_OBR_20
sps2ID                 :(NSString*)sps2_OBR_20
sps3ID                 :(NSString*)sps3_OBR_20
sps4ID                 :(NSString*)sps4_OBR_20
sps1Modality           :(NSString*)sps1_OBR_24
sps2Modality           :(NSString*)sps2_OBR_24
sps3Modality           :(NSString*)sps3_OBR_24
sps4Modality           :(NSString*)sps4_OBR_24
sps1AET                :(NSString*)sps1_OBR_21
sps2AET                :(NSString*)sps2_OBR_21
sps3AET                :(NSString*)sps3_OBR_21
sps4AET                :(NSString*)sps4_OBR_21
sps1Protocol           :(NSString*)sps1_OBR_4
sps2Protocol           :(NSString*)sps2_OBR_4
sps3Protocol           :(NSString*)sps3_OBR_4
sps4Protocol           :(NSString*)sps4_OBR_4

{
   NSMutableString *message=[NSMutableString string];
   
   NSString * MSH = [NSString
    sendingApplication  :MSH_3
    sendingFacility     :MSH_4
    receivingApplication:MSH_5
    receivingFacility   :MSH_6
    messageType         :@"ORM^O01"
    messageControlID    :MSH_10
    versionID           :VersionID
    countryCode         :MSH_17
    stringEncoding      :stringEncoding
    principalLanguage   :MSH_19
    ];
   if (!MSH)return nil;
   [message appendString:MSH];
   
   NSString * PID = [NSString
    patIdentifierList      :PID_3
    patName                :PID_5
    patMotherMaidenName    :PID_6
    patBirthDate           :PID_7
    patAdministrativeGender:PID_8
    ];
   if (!PID) return nil;
   [message appendString:@"\r"];
   [message appendString:PID];

   NSString * PV1 = [NSString
    isrInsurance:PV1_8
    isrReferring:OBR_16
    ];//=DICOM pregnancyStatus
   if (!PV1) return nil;
   [message appendString:@"\r"];
   [message appendString:PV1];


   
   NSString * ORC = [NSString
    orderControl   :@"NW"
    isrPlacerNumber:ORC_2
    isrFillerNumber:ORC_3
    reqPriority    :ORC_7_
    spsOrderStatus :ORC_5
    spsDateTime    :ORC_7
    ];
   if (!ORC) return nil;
   [message appendString:@"\r"];
   [message appendString:ORC];

   NSString * OBR1= [NSString
    isrReferring :OBR_16
    isrAN        :OBR_18
    isrReading   :OBR_32
    reqID        :OBR_19
    reqProcedure :OBR_44
    spsPerforming:OBR_34
    spsID        :sps1_OBR_20
    spsModality  :sps1_OBR_24
    spsAET       :sps1_OBR_21
    spsProtocol  :sps1_OBR_4
    ];
   if (!OBR1) return nil;
   [message appendString:@"\r"];
   [message appendString:OBR1];

   
   if ([sps2_OBR_24 length])
   {
      NSString *commonRpID=nil;
      if ([rpID length]) commonRpID=rpID;
      else commonRpID=[OBR1 componentsSeparatedByString:@"|"][19];
      
      [message appendString:@"\r"];
      [message appendString:ORC];
      
      NSString * OBR2= [NSString
                        isrReferring :OBR_16
                        isrAN        :OBR_18
                        isrReading   :OBR_32
                        reqID        :OBR_19
                        reqProcedure :OBR_44
                        spsPerforming:OBR_34
                        spsID        :sps2_OBR_20
                        spsModality  :sps2_OBR_24
                        spsAET       :sps2_OBR_21
                        spsProtocol  :sps2_OBR_4
                        ];
      if (!OBR2) return nil;
      [message appendString:@"\r"];
      [message appendString:OBR2];
      
      if ([sps3_OBR_24 length])
      {
         [message appendString:@"\r"];
         [message appendString:ORC];
         
         NSString * OBR2= [NSString
                           isrReferring :OBR_16
                           isrAN        :OBR_18
                           isrReading   :OBR_32
                           reqID        :OBR_19
                           reqProcedure :OBR_44
                           spsPerforming:OBR_34
                           spsID        :sps3_OBR_20
                           spsModality  :sps3_OBR_24
                           spsAET       :sps3_OBR_21
                           spsProtocol  :sps3_OBR_4
                           ];
         if (!OBR3) return nil;
         [message appendString:@"\r"];
         [message appendString:OBR3];
         
         if ([sps4_OBR_24 length])
         {
            [message appendString:@"\r"];
            [message appendString:ORC];
            
            NSString * OBR2= [NSString
                              isrReferring :OBR_16
                              isrAN        :OBR_18
                              isrReading   :OBR_32
                              reqID        :OBR_19
                              reqProcedure :OBR_44
                              spsPerforming:OBR_34
                              spsID        :sps4_OBR_20
                              spsModality  :sps4_OBR_24
                              spsAET       :sps4_OBR_21
                              spsProtocol  :sps4_OBR_4
                              ];
            if (!OBR4) return nil;
            [message appendString:@"\r"];
            [message appendString:OBR3];

         }
         
      }

   }
   

   NSString * ZDS = [NSString
    StudyInstanceUID:ZDS_1
    ];
   if (!ZDS) return nil;
   [message appendString:@"\r"];
   [message appendString:ZDS];
   [message appendString:@"\r"];

   return [NSString stringWithString:message];
}
@end
