//Register a Patient
//admit patient without bed
//MSH-9: ADT^A04^ADT_A01

#import <Foundation/Foundation.h>


//? = optional (nil accepted)
NS_ASSUME_NONNULL_BEGIN

@interface NSString(A04)

//https://dcm4chee-arc-hl7cs.readthedocs.io/en/latest/adt/inbound.html#adt-ack-register-a-patient-event-a04

//Supported HL7 versions: 2.3.1, 2,5, 2.5.1
//A remote HL7 Application notifies that a patient has arrived at a healthcare facility for an episode of care in which the patient is not assigned to a bed. Examples of such episodes include outpatient visits, ambulatory care encounters, and emergency room visits.
//If a Patient record with the extracted primary Patient ID already exists in the database, that Patient record will get updated. If there is no such Patient record a new Patient record will be inserted into the database
//The creation of new Patient records will be suppressed for message types which are listed by configuration parameter HL7 No Patient Create Message Type(s) of dcm4che DICOM Archive 5.

+(NSString*)registerPatient:(NSString*)VersionID //?
   sendingRisName          :(NSString*)MSH_3 //?
   sendingRisIP            :(NSString*)MSH_4 //?
   receivingCustodianTitle :(NSString*)MSH_5 //?
   receivingPacsaet        :(NSString*)MSH_6 //?
   MessageControlId        :(NSString*)MSH_10 //?
   CountryCode             :(NSString*)MSH_17 //?
   stringEncoding          :(NSStringEncoding)stringEncoding //? MSH_18 00080005
   PrincipalLanguage       :(NSString*)MSH_19 //?
   PatientIdentifierList   :(NSString*)PID_3 //  00100020+00100021
   PatientName             :(NSString*)PID_5 //  00100010
   MotherMaidenName        :(NSString*)PID_6 //? 00101060
   PatientBirthDate        :(NSString*)PID_7 //? 00100030
   PatientAdministrativeSex:(NSString*)PID_8 //? 00100040
;
@end

NS_ASSUME_NONNULL_END
