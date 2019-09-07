//studyToken
/*
{
 
   "proxyURI":"",
   "session":"",
   "custodianOID":"\\...",
   "accessType":"cornerstone|weasis|dicomzip|osirix|",

 - "StudyInstanceUID":"\\...",
 - "AccessionNumber":"",
 - "StudyDate":" | \\aaaa-mm-dd | aaaa-mm-dd | aaaa-mm-dd\\ | aaaa-mm-dd\\aaaa-mm-dd",
   "PatientID":"",
 
   ("issuer":"oid")
   ("SeriesNumber":"\\")}
   ("SeriesDescription":"\\")
   ("Modality":"\\")
   ("SOPClass":"\\")
 
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
                  hasRestriction:(BOOL)hasRestriction
               SeriesNumberArray:(NSArray*)SeriesNumberArray
          SeriesDescriptionArray:(NSArray*)SeriesDescriptionArray
                   ModalityArray:(NSArray*)ModalityArray
                   SOPClassArray:(NSArray*)SOPClassArray
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
                       hasRestriction:(BOOL)hasRestriction
                    SeriesNumberArray:(NSArray*)SeriesNumberArray
               SeriesDescriptionArray:(NSArray*)SeriesDescriptionArray
                        ModalityArray:(NSArray*)ModalityArray
                        SOPClassArray:(NSArray*)SOPClassArray
                StudyInstanceUIDArray:(NSArray*)StudyInstanceUIDArray
                AccessionNumberString:(NSString*)AccessionNumberString
                      PatientIDString:(NSString*)PatientIDString
                      StudyDateString:(NSString*)StudyDateString
                         issuerString:(NSString*)issuerString
;

+(RSResponse*)dicomzipWithDevCustodianOIDArray:(NSMutableArray*)devCustodianOIDArray
                          wanCustodianOIDArray:(NSMutableArray*)wanCustodianOIDArray
                                hasRestriction:(BOOL)hasRestriction
                             SeriesNumberArray:(NSArray*)SeriesNumberArray
                        SeriesDescriptionArray:(NSArray*)SeriesDescriptionArray
                                 ModalityArray:(NSArray*)ModalityArray
                                 SOPClassArray:(NSArray*)SOPClassArray
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
                  hasRestriction:(BOOL)hasRestriction
               SeriesNumberArray:(NSArray*)SeriesNumberArray
          SeriesDescriptionArray:(NSArray*)SeriesDescriptionArray
                   ModalityArray:(NSArray*)ModalityArray
                   SOPClassArray:(NSArray*)SOPClassArray
           StudyInstanceUIDArray:(NSArray*)StudyInstanceUIDArray
           AccessionNumberString:(NSString*)AccessionNumberString
                 PatientIDString:(NSString*)PatientIDString
                 StudyDateString:(NSString*)StudyDateString
                    issuerString:(NSString*)issuerString
;

@end
