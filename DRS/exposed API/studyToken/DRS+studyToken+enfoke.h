#import "DRS.h"

@interface DRS (enfoke)

/*
 {
   "GetImages":
   {
      "AccessionNumber": "",
      "Patient":
      {
         "PatientDocumentType": "",
         "PatientDocumentNumber": "",
         "PatientBirthDate": "",
         "PatientName": "",
         "PatientLastName": ""
      },
      "RequestingPhysician":
      {
         "RequestingPhysicianEnrollment":
         [
            {
               "RequestingPhysicianEnrollmentType": "",
               "RequestingPhysicianEnrollmentNumber": ""
            }
         ],
         "RequestingPhysicianDocumentType": "",
         "RequestingPhysicianDocumentNumber": ""
      },
      "ApplicantType": ""
   }
}
 */

/*
  {"GetImages":{"AccessionNumber":"00101100042064","Patient":{"PatientDocumentType":"DNI","PatientDocumentNumber":"22001710","PatientBirthDate":"28/06/1971 0:00","PatientName":"LEONARDO","PatientLastName":"LOPEZ"},"RequestingPhysician":null,"ApplicantType":"PAC","URLType":"VF"}}
 */

-(void)addPOSTenfokePatientHandler;

/*
 enrollmentType=1 -> national
 
{"GetImages":
   {
      "AccessionNumber":"00101100042064",
      "Patient":null,
      "RequestingPhysician":
      {
         "RequestingPhysicianEnrollment":
         [
            {
               "RequestingPhysicianEnrollmentType": "1",
               "RequestingPhysicianEnrollmentNumber": "107060";
            }
         ],
         "RequestingPhysicianDocumentType": "1",
         "RequestingPhysicianDocumentNumber" : "22001710"
      }
      "ApplicantType":"MED",
      "URLType":"VM"
   }
 }
 */
-(void)addPOSTenfokeReferringHandler;

@end
