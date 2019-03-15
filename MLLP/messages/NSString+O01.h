//mwlitems

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface NSString(O01)

//http://ihewiki.wustl.edu/wiki/index.php/HL7_Tables#RAD-2_and_RAD-3:_Placer_and_Filler_Order_Management
//Source: IHE RAD TF-2 Table B-1: HL7 Order Mapping to DICOM MWL
//* = addition by opendicom

+(NSString*)singleSps          :(NSString*)VersionID //?
sendingRisName                 :(NSString*)MSH_3 //?
sendingRisIP                   :(NSString*)MSH_4 //?
receivingCustodianTitle        :(NSString*)MSH_5 //?
receivingPacsaet               :(NSString*)MSH_6 //?
MessageControlId               :(NSString*)MSH_10 //?
CountryCode                    :(NSString*)MSH_17 //?
stringEncoding                 :(NSStringEncoding)stringEncoding //? MSH_18 00080005
PrincipalLanguage              :(NSString*)MSH_19 //?
PatientIdentifierList          :(NSString*)PID_3 //  00100020+00100021
PatientName                    :(NSString*)PID_5 //  00100010
MotherMaidenName               :(NSString*)PID_6 //? 00101060
PatientBirthDate               :(NSString*)PID_7 //? 00100030
PatientAdministrativeSex       :(NSString*)PID_8 //? 00100040
isrPatientInsuranceShortName   :(NSString*)PV1_8 //00080090 ReferringPhysicianName
isrPlacerNumber                :(NSString*)ORC_2 //00402016
isrFillerNumber                :(NSString*)ORC_3 //00402017
spsOrderStatus                 :(NSString*)ORC_5 //00400020*
spsDateTime                    :(NSString*)ORC_7 //00400002+00400003*
rpPriority                     :(NSString*)ORC_7_ //00401003
spsProtocolCode                :(NSString*)OBR_4  //00400008(00040007)
isrDangerCode                  :(NSString*)OBR_12 //00380500
isrRelevantClinicalInfo        :(NSString*)OBR_13 //00102000
isrReferringPhysician          :(NSString*)OBR_16 //00321032 RequestingPhysician
isrAccessionNumber             :(NSString*)OBR_18 //00080050*
rpID                           :(NSString*)OBR_19 //00401001
spsID                          :(NSString*)OBR_20 //00400009
spsStationAETitle              :(NSString*)OBR_21 //00400001*
spsModality                    :(NSString*)OBR_24 //00080060*
rpTransportationMode           :(NSString*)OBR_30 //00401004
rpReasonForStudy               :(NSString*)OBR_31              //00401002
isrNameOfPhysiciansReadingStudy:(NSString*)OBR_32  //00081060*
spsTechnician                  :(NSString*)OBR_34 //00400006 (PerformingPhysicianName)
rpUniversalStudyCode           :(NSString*)OBR_44 //00321064(00321060)
isrStudyInstanceUID            :(NSString*)ZDS_1  //0020000D
;

//dcm4chee-arc GUI

//RequestedProcedureID
//StudyInstanceUID
//SPSStartDate
//SPSStartTime
//SP Physician's Name
//AccessionNumber
//Modalities
//SPSDescription
//SS AE Title

//detailed:

//Referring Physician´s Name
//RequestedProcedureDescription

//extended filter

//SPS Status
//SPS Description
//Scheduled Performing Phsysician´s Name



@end

NS_ASSUME_NONNULL_END
