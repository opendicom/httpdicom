#import <Foundation/Foundation.h>

//? = optional (nil accepted)
//NS_ASSUME_NONNULL_BEGIN

//https://dcm4chee-arc-hl7cs.readthedocs.io/en/latest/orm/inbound.html#tab-obr-orm-omg


//4  UniversalServiceID (^^^99845^RX INTESTINAL^CR)
//   (P1^Procedure 1^ERL_MESA^X1_A1^SP Action Item X1_A1^DSS_MESA)

//12 DangerCode (code^description^system)
//http://ihewiki.wustl.edu/wiki/index.php/HL7_Tables#Danger_Code
//    HI=HIV positive
//    TB=Active tuberculosis

//13 RelevantClinicalInfo
//16 OrderingProvider (id^family1>family2^given1 given2) ->afiliación
//18 PlacerField1 (AccessionNumber)
//19 PlacerField2 (RequestedProcedureID)
//20 FillerField1 (stepID, empty -> pacs uses 18)
//21 FillerField2 (aet modality)
//24 DiagnosticServiceSectID (modality)
//30 TransportationMode
//31 ReasonForStudy
//32 PrincipalResultInterpreter (not in the conformance statement, but in the db without use yet

//34 Technician
//44 ProcedureCode (P1^Procedure 1^ERL_MESA^X1_A1)

@interface NSString(OBR)

+(NSString*)
   isrReferring :(NSString*)OBR_16
   isrAN        :(NSString*)OBR_18
   isrReading   :(NSString*)OBR_32
   reqID        :(NSString*)OBR_19
   reqProcedure :(NSString*)OBR_44
   spsPerforming:(NSString*)OBR_34
   spsID        :(NSString*)OBR_20
   spsModality  :(NSString*)OBR_24
   spsAET       :(NSString*)OBR_21
   spsProtocol  :(NSString*)OBR_4
;

@end

//NS_ASSUME_NONNULL_END
