//studyToken
/*
{
   "institution":"",
   "user":"",
   "password":"",
   "pacs":"",
   "accessType":"cornerstone|weasis|dicomzip|osirix",

 - "StudyInstanceUID":"1.2\...",
 - "AccessionNumber":"único",
 - "StudyDate":"aaaa-mm-dd", "PatientID":"",
 
   ("issuer":"oid")
   ("SeriesDescription":"\")
   ("Modality":"\")
   ("SOPClass":"\")
}
 
 -> 200 text/xml manifiesto weasis
 -> 200 application/json manifiesto cornerstone
 -> 200 application/zip dicomzip
 -> 204 (no content) json array con cero o dos o más study object formatados qido response
 -> 400 bad request
 -> 404 json malformed
*/

#import "DRS.h"

@interface DRS (studyToken)

-(void)addPOSTStudyTokenHandler;
-(void)addGETStudyTokenHandler;

+(RSResponse*)studyToken:(RSRequest*)request;

@end
