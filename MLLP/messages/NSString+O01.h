//mwlitems

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface NSString(O01)

//http://ihewiki.wustl.edu/wiki/index.php/HL7_Tables#RAD-2_and_RAD-3:_Placer_and_Filler_Order_Management
//Source: IHE RAD TF-2 Table B-1: HL7 Order Mapping to DICOM MWL


+(NSString*)O01version :(NSString*)VersionID
sendingApplication     :(NSString*)MSH_3
sendingFacility        :(NSString*)MSH_4
receivingApplication   :(NSString*)MSH_5
receivingFacility      :(NSString*)MSH_6
messageControlId       :(NSString*)MSH_10
countryCode            :(NSString*)MSH_17
stringEncoding         :(NSStringEncoding)stringEncoding //MSH_18 00080005
principalLanguage      :(NSString*)MSH_19
patIdentifierList      :(NSString*)PID_3 //00100020+00100021
patName                :(NSString*)PID_5 //00100010
patMotherMaidenName    :(NSString*)PID_6 //00101060
patBirthDate           :(NSString*)PID_7 //00100030
patAdministrativeGender:(NSString*)PID_8 //00100040
isrInsurance           :(NSString*)PV1_8 //00200010 StudyID
isrPlacerNumber        :(NSString*)ORC_2 //00402016
isrFillerNumber        :(NSString*)ORC_3 //00402017
isrAN                  :(NSString*)OBR_18 //00080050
isrReferring           :(NSString*)OBR_16 //00321032 Requesting 00080090 Referring
isrReading             :(NSString*)OBR_32 //00081060
isrStudyIUID           :(NSString*)ZDS_1  //0020000D
reqID                  :(NSString*)OBR_19 //00401001
reqProcedure           :(NSString*)OBR_44 //00321064(00321060)
reqPriority            :(NSString*)ORC_7_ //00401003
spsDateTime            :(NSString*)ORC_7 //00400002+00400003
spsPerforming          :(NSString*)OBR_34 //00400006
sps1ID                 :(NSString*)sps1_OBR_20 //00400009
sps2ID                 :(NSString*)sps2_OBR_20 //00400009
sps3ID                 :(NSString*)sps3_OBR_20 //00400009
sps4ID                 :(NSString*)sps4_OBR_20 //00400009
sps1Modality           :(NSString*)sps1_OBR_24 //00080060
sps2Modality           :(NSString*)sps2_OBR_24 //00080060
sps3Modality           :(NSString*)sps3_OBR_24 //00080060
sps4Modality           :(NSString*)sps4_OBR_24 //00080060
sps1AET                :(NSString*)sps1_OBR_21 //00400001
sps2AET                :(NSString*)sps2_OBR_21 //00400001
sps3AET                :(NSString*)sps3_OBR_21 //00400001
sps4AET                :(NSString*)sps4_OBR_21 //00400001
sps1Protocol           :(NSString*)sps1_OBR_4  //00400008(00040007)
sps2Protocol           :(NSString*)sps2_OBR_4  //00400008(00040007)
sps3Protocol           :(NSString*)sps3_OBR_4  //00400008(00040007)
sps4Protocol           :(NSString*)sps4_OBR_4  //00400008(00040007)
;

@end

NS_ASSUME_NONNULL_END
