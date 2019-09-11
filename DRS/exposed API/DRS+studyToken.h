//studyToken
/*
 ^/(osirix.dcmURLs|weasis.xml|dicom.zip|datatablesseries.json|datatablespatient.json|cornerstone.json)$
{
 
   "proxyURI":"",
   "session":"",
   "custodianOID":"|",

 - "StudyInstanceUID":"|",
 - "AccessionNumber":"",
 - "PatientID":""
 
   ("StudyDate":"() |aaaa-mm-dd  aaaa-mm-dd  aaaa-mm-dd| aaaa-mm-dd|aaaa-mm-dd")
   ("issuer":"oid")
 
   ("SeriesInstanceUID":"regex")}
   ("SeriesNumber":"regex")}
   ("SeriesDescription":"regex")
   ("Modality":"regex")
   ("SOPClass":"regex")
   ("SOPClassOff":"regex")

 -> 200 text/xml manifiesto weasis
 -> 200 application/json manifiesto cornerstone
 -> 200 application/zip dicomzip
 -> 204 (no content) json array con cero o dos o más study object formatados qido response
 -> 400 bad request
 -> 404 json malformed
 
 studyTokenTask performs the work it returns the first response and then writes the following ones on a buffer where they can be discovered by calls for more.
 
 The calls can be a wado where study=transaction series=custodian instance=paquetID
 
 tasks:
 
 find the separation between studyToken and studyTokenTask
*/

#import "DRS.h"

@interface DRS (studyToken)

-(void)addPostAndGetStudyTokenHandler;

+(RSResponse*)studyToken:(RSRequest*)request;

+(RSResponse*)weasisWithProxyURI:(NSString*)proxyURIString
               session:(NSString*)sessionString
  devCustodianOIDArray:(NSMutableArray*)devCustodianOIDArray
  wanCustodianOIDArray:(NSMutableArray*)wanCustodianOIDArray
        transferSyntax:(NSString*)transferSyntax
        hasRestriction:(BOOL)hasRestriction
SeriesInstanceUIDRegex:(NSRegularExpression*)SeriesInstanceUIDRegex
     SeriesNumberRegex:(NSRegularExpression*)SeriesNumberRegex
SeriesDescriptionRegex:(NSRegularExpression*)SeriesDescriptionRegex
         ModalityRegex:(NSRegularExpression*)ModalityRegex
         SOPClassRegex:(NSRegularExpression*)SOPClassRegex
      SOPClassOffRegex:(NSRegularExpression*)SOPClassOffRegex
 StudyInstanceUIDArray:(NSArray*)StudyInstanceUIDArray
 AccessionNumberString:(NSString*)AccessionNumberString
       PatientIDString:(NSString*)PatientIDString
       StudyDateString:(NSString*)StudyDateString
          issuerString:(NSString*)issuerString
;


+(RSResponse*)cornerstoneWithProxyURI:(NSString*)proxyURIString
               session:(NSString*)sessionString
  devCustodianOIDArray:(NSMutableArray*)devCustodianOIDArray
  wanCustodianOIDArray:(NSMutableArray*)wanCustodianOIDArray
        transferSyntax:(NSString*)transferSyntax
        hasRestriction:(BOOL)hasRestriction
SeriesInstanceUIDRegex:(NSRegularExpression*)SeriesInstanceUIDRegex
     SeriesNumberRegex:(NSRegularExpression*)SeriesNumberRegex
SeriesDescriptionRegex:(NSRegularExpression*)SeriesDescriptionRegex
         ModalityRegex:(NSRegularExpression*)ModalityRegex
         SOPClassRegex:(NSRegularExpression*)SOPClassRegex
      SOPClassOffRegex:(NSRegularExpression*)SOPClassOffRegex
 StudyInstanceUIDArray:(NSArray*)StudyInstanceUIDArray
 AccessionNumberString:(NSString*)AccessionNumberString
       PatientIDString:(NSString*)PatientIDString
       StudyDateString:(NSString*)StudyDateString
          issuerString:(NSString*)issuerString
;

+(RSResponse*)dicomzipWithDevCustodianOIDArray:(NSMutableArray*)devCustodianOIDArray
  wanCustodianOIDArray:(NSMutableArray*)wanCustodianOIDArray
        transferSyntax:(NSString*)transferSyntax
        hasRestriction:(BOOL)hasRestriction
SeriesInstanceUIDRegex:(NSRegularExpression*)SeriesInstanceUIDRegex
     SeriesNumberRegex:(NSRegularExpression*)SeriesNumberRegex
SeriesDescriptionRegex:(NSRegularExpression*)SeriesDescriptionRegex
         ModalityRegex:(NSRegularExpression*)ModalityRegex
         SOPClassRegex:(NSRegularExpression*)SOPClassRegex
      SOPClassOffRegex:(NSRegularExpression*)SOPClassOffRegex
 StudyInstanceUIDArray:(NSArray*)StudyInstanceUIDArray
 AccessionNumberString:(NSString*)AccessionNumberString
       PatientIDString:(NSString*)PatientIDString
       StudyDateString:(NSString*)StudyDateString
          issuerString:(NSString*)issuerString
;

+(RSResponse*)osirixWithProxyURI:(NSString*)proxyURIString
               session:(NSString*)sessionString
  devCustodianOIDArray:(NSMutableArray*)devCustodianOIDArray
  wanCustodianOIDArray:(NSMutableArray*)wanCustodianOIDArray
        transferSyntax:(NSString*)transferSyntax
        hasRestriction:(BOOL)hasRestriction
SeriesInstanceUIDRegex:(NSRegularExpression*)SeriesInstanceUIDRegex
     SeriesNumberRegex:(NSRegularExpression*)SeriesNumberRegex
SeriesDescriptionRegex:(NSRegularExpression*)SeriesDescriptionRegex
         ModalityRegex:(NSRegularExpression*)ModalityRegex
         SOPClassRegex:(NSRegularExpression*)SOPClassRegex
      SOPClassOffRegex:(NSRegularExpression*)SOPClassOffRegex
 StudyInstanceUIDArray:(NSArray*)StudyInstanceUIDArray
 AccessionNumberString:(NSString*)AccessionNumberString
       PatientIDString:(NSString*)PatientIDString
       StudyDateString:(NSString*)StudyDateString
          issuerString:(NSString*)issuerString
;

@end
