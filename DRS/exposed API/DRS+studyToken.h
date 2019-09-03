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
   ("SeriesNumber":"\")}
   ("SeriesDescription":"\")
   ("Modality":"\")
   ("SOPClass":"\")
 
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
      hasSeriesNumberRestriction:(BOOL)hasSeriesNumberRestriction
               SeriesNumberArray:(NSArray*)SeriesNumberArray
 hasSeriesDescriptionRestriction:(BOOL)hasSeriesDescriptionRestriction
          SeriesDescriptionArray:(NSArray*)SeriesDescriptionArray
          hasModalityRestriction:(BOOL)hasModalityRestriction
                   ModalityArray:(NSArray*)ModalityArray
          hasSOPClassRestriction:(BOOL)hasSOPClassRestriction
                   SOPClassArray:(NSArray*)SOPClassArray
           StudyInstanceUIDArray:(NSArray*)StudyInstanceUIDArray
           AccessionNumberString:(NSString*)AccessionNumberString
                 PatientIDString:(NSString*)PatientIDString
                 StudyDateString:(NSString*)StudyDateString
;


+(RSResponse*)cornerstoneWithProxyURI:(NSString*)proxyURIString
                              session:(NSString*)sessionString
                 devCustodianOIDArray:(NSMutableArray*)devCustodianOIDArray
                 wanCustodianOIDArray:(NSMutableArray*)wanCustodianOIDArray
                       hasRestriction:(BOOL)hasRestriction
           hasSeriesNumberRestriction:(BOOL)hasSeriesNumberRestriction
                    SeriesNumberArray:(NSArray*)SeriesNumberArray
      hasSeriesDescriptionRestriction:(BOOL)hasSeriesDescriptionRestriction
               SeriesDescriptionArray:(NSArray*)SeriesDescriptionArray
               hasModalityRestriction:(BOOL)hasModalityRestriction
                        ModalityArray:(NSArray*)ModalityArray
               hasSOPClassRestriction:(BOOL)hasSOPClassRestriction
                        SOPClassArray:(NSArray*)SOPClassArray
                StudyInstanceUIDArray:(NSArray*)StudyInstanceUIDArray
                AccessionNumberString:(NSString*)AccessionNumberString
                      PatientIDString:(NSString*)PatientIDString
;

+(RSResponse*)cornerstoneWithProxyURI:(NSString*)proxyURIString
                              session:(NSString*)sessionString
                 devCustodianOIDArray:(NSMutableArray*)devCustodianOIDArray
                 wanCustodianOIDArray:(NSMutableArray*)wanCustodianOIDArray
                       hasRestriction:(BOOL)hasRestriction
           hasSeriesNumberRestriction:(BOOL)hasSeriesNumberRestriction
                    SeriesNumberArray:(NSArray*)SeriesNumberArray
      hasSeriesDescriptionRestriction:(BOOL)hasSeriesDescriptionRestriction
               SeriesDescriptionArray:(NSArray*)SeriesDescriptionArray
               hasModalityRestriction:(BOOL)hasModalityRestriction
                        ModalityArray:(NSArray*)ModalityArray
               hasSOPClassRestriction:(BOOL)hasSOPClassRestriction
                        SOPClassArray:(NSArray*)SOPClassArray
                StudyInstanceUIDArray:(NSArray*)StudyInstanceUIDArray
                AccessionNumberString:(NSString*)AccessionNumberString
                      PatientIDString:(NSString*)PatientIDString
                      StudyDateString:(NSString*)StudyDateString
;

@end
