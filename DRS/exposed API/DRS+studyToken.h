#import "DRS.h"

#import "DICMTypes.h"
#import "NSString+PCS.h"
#import "NSData+PCS.h"
#import "NSMutableArray+JSON.h"
#import "NSData+ZLIB.h"

#pragma mark enums

enum accessType{
   accessTypeWeasis,
   accessTypeCornerstone,
   accessTypeDicomzip,
   accessTypeOsirix,
   accessTypeDatatablesSeries,
   accessTypeDatatablesPatient,
   accessTypeIsoDicomZip,
   accessTypeDeflateIsoDicomZip,
   accessTypeMaxDeflateIsoDicomZip,
   accessTypeZip64IsoDicomZip,
   accessTypeWadoRSDicom
};

enum selectType{
   selectTypeSql,
   selectTypeQido,
   selectTypeCfind
};

enum getType{
   getTypeFile,
   getTypeFolder,
   getTypeWado,
   getTypeWadors,
   getTypeCget,
   getTypeCmove
};

enum dateMatch{
   dateMatchAny,
   dateMatchOn,
   dateMatchSince,
   dateMatchUntil,
   dateMatchBetween,
};

enum issuer{
   issuerNone,
   issuerLocal,
   issuerUniversal,
   issuerType,
   issuerDivision
};


enum EcumulativeFilter{
   EcumulativeFilterPid=1,
   EcumulativeFilterPpn,
   EcumulativeFilterEid,
   EcumulativeFilterEda,
   EcumulativeFilterElo,
   EcumulativeFilterRef,
   EcumulativeFilterRead,
   EcumulativeFilterEsc,
   EcumulativeFilterEmo,
};


enum pnFilter{
   pnFilterCompound,
   pnFilterFamily,
   pnFilterGiven,
   pnFilterMiddle,
   pnFilterPrefix,
   pnFilterSuffix
};


#pragma mark - functions prototypes


/*
study pk and patient pk of studies selected
*/
RSResponse * sqlEP(
 NSMutableDictionary * EPDict,
 NSDictionary        * sqlcredentials,
 NSDictionary        * sqlDictionary,
 NSString            * sqlprolog,
 BOOL                EuiE,
 NSString            * StudyInstanceUIDRegexpString,
 NSString            * AccessionNumberEqualString,
 NSString            * refInstitutionLikeString,
 NSString            * refServiceLikeString,
 NSString            * refUserLikeString,
 NSString            * refIDLikeString,
 NSString            * refIDTypeLikeString,
 NSString            * readInstitutionSqlLikeString,
 NSString            * readServiceSqlLikeString,
 NSString            * readUserSqlLikeString,
 NSString            * readIDSqlLikeString,
 NSString            * readIDTypeSqlLikeString,
 NSString            * StudyIDLikeString,
 NSString            * PatientIDLikeString,
 NSString            * patientFamilyLikeString,
 NSString            * patientGivenLikeString,
 NSString            * patientMiddleLikeString,
 NSString            * patientPrefixLikeString,
 NSString            * patientSuffixLikeString,
 NSArray             * issuerArray,
 NSArray             * StudyDateArray,
 NSString            * SOPClassInStudyRegexpString,
 NSString            * ModalityInStudyRegexpString,
 NSString            * StudyDescriptionRegexpString
);


/*
 applied at series level in each of the access type to restrict returned series.
 The function returns the SOPClass of series to be included
 */
NSString * SOPCLassOfReturnableSeries(
 NSDictionary        * sqlcredentials,
 NSString            * sqlIci4S,
 NSString            * sqlprolog,
 NSArray             * SProperties,
 NSRegularExpression * SeriesInstanceUIDRegex,
 NSRegularExpression * SeriesNumberRegex,
 NSRegularExpression * SeriesDescriptionRegex,
 NSRegularExpression * ModalityRegex,
 NSRegularExpression * SOPClassRegex,
 NSRegularExpression * SOPClassOffRegex
);


#pragma mark - static
// pk.pk/
static NSString *sqlTwoPks=@"| awk -F\\t ' BEGIN{ ORS=\"/\"; OFS=\".\";} {print $1, $2} '";

// item/
static NSString *sqlsingleslash=@"| awk -F\\t ' BEGIN{ ORS=\"/\"; OFS=\"\";} {print $1} '";

static NSString *sqlRecordFourUnits=@"| awk -F\\t ' BEGIN{ ORS=\"\\x0D\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4}'";

static NSString *sqlRecordFiveUnits=@"| awk -F\\t ' BEGIN{ ORS=\"\\x0D\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4, $5}'";

static NSString *sqlRecordSixUnits=@"| awk -F\\t ' BEGIN{ ORS=\"\\x0D\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4, $5, $6}'";

static NSString *sqlRecordEightUnits=@"| awk -F\\t ' BEGIN{ ORS=\"\\x0D\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4, $5, $6, $7, $8}'";

static NSString *sqlRecordNineUnits=@"| awk -F\\t ' BEGIN{ ORS=\"\\x0D\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4, $5, $6, $7, $8, $9}'";

static NSString *sqlRecordTenUnits=@"| awk -F\\t ' BEGIN{ ORS=\"\\x0D\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10}'";

static NSString *sqlRecordElevenUnits=@"| awk -F\\t ' BEGIN{ ORS=\"\\x0D\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11}'";

#pragma mark -

@interface DRS (studyToken)

-(void)addPostAndGetStudyTokenHandler;

+(RSResponse*)studyToken:(RSRequest*)request;

@end


//studyToken
/*
 ^/(osirix.dcmURLs|weasis.xml|dicom.zip|uncompressed.dicom.zip|deflate.dicom.zip|dicom.zipx|datatablesseries.json|datatablespatient.json|cornerstone.json)$
{
 
   "proxyURI":"",
   "session":"",
   "custodianOID":"|",

 - "StudyInstanceUID":"|",
 - "AccessionNumber":"",
 - "PatientID":""
 
   ("StudyDate":"() |aaaa-mm-dd  aaaa-mm-dd  aaaa-mm-dd| aaaa-mm-dd|aaaa-mm-dd")
   ("issuer":"oid")
 
   ("SeriesInstanceUID":"regex")
   ("SeriesNumber":"regex")
 
   ("SeriesInstitution":"regex")
   ("SeriesDepartment":"regex")
   ("SeriesStationName":"regex")
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


/*
 JSON returned

 "arcId":"devOID",
 "baseUrl":"proxyURIString",
 "patientList":
 [
  {
   "key"=123,
   "PatientID":"",
   "PatientName":"",
   "IssuerOfPatientID":"",
   "PatientBirthDate":"",
   "PatientSex":"",
   "studyList":
   [
    {
     "key"=123,
     "StudyInstanceUID":"",
     "studyDescription":"",
     "studyDate":"",
     "StudyTime":"",
     "AccessionNumber":"",
     "StudyID":"",
     "ReferringPhysicianName":"",
     "numImages":"",
     "modality":"",
     "patientId":"",
     "patientName":"",
     "seriesList":
     [
      {
       "key"=123,
       "seriesDescription":"",
       "seriesNumber":"",
       "SeriesInstanceUID":"",
       "SOPClassUID":"",
       "Modality":"",
       "WadoTransferSyntaxUID":"",
       "instanceList":
       [
        {
         "key"=123,
         "imageId":"wadouriInstance",
         "SOPClassUID":"",
         "SOPInstanceUID":"",
         "InstanceNumber":"",
         "numFrames":1
        }
       ]
      }
     ]
    }
   ]
  }
 ]
}

(-1=info not available, 0=not an image, 1=monoframe, x=multiframe)


@interface DRS (studyTokenCornerstone)

- (RSResponse*)cornerstone4JSONArray:(NSMutableArray*)JSONArray
         canonicalQuerySHA512String:(NSString*)canonicalQuerySHA512String
                     proxyURIString:(NSString*)proxyURIString
                      sessionString:(NSString*)sessionString
                        tokenString:(NSString*)tokenString
                           lanArray:(NSMutableArray*)lanArray
                           wanArray:(NSMutableArray*)wanArray
       StudyInstanceUIDRegexpString:(NSString*)StudyInstanceUIDRegexpString
         AccessionNumberEqualString:(NSString*)AccessionNumberEqualString
           refInstitutionLikeString:(NSString*)refInstitutionLikeString
               refServiceLikeString:(NSString*)refServiceLikeString
                  refUserLikeString:(NSString*)refUserLikeString
                    refIDLikeString:(NSString*)refIDLikeString
                refIDTypeLikeString:(NSString*)refIDTypeLikeString
       readInstitutionSqlLikeString:(NSString*)readInstitutionSqlLikeString
           readServiceSqlLikeString:(NSString*)readServiceSqlLikeString
              readUserSqlLikeString:(NSString*)readUserSqlLikeString
                readIDSqlLikeString:(NSString*)readIDSqlLikeString
            readIDTypeSqlLikeString:(NSString*)readIDTypeSqlLikeString
                  StudyIDLikeString:(NSString*)StudyIDLikeString
                PatientIDLikeString:(NSString*)PatientIDLikeString
            patientFamilyLikeString:(NSString*)patientFamilyLikeString
             patientGivenLikeString:(NSString*)patientGivenLikeString
            patientMiddleLikeString:(NSString*)patientMiddleLikeString
            patientPrefixLikeString:(NSString*)patientPrefixLikeString
            patientSuffixLikeString:(NSString*)patientSuffixLikeString
                        issuerArray:(NSArray*)issuerArray
                     StudyDateArray:(NSArray*)StudyDateArray
        SOPClassInStudyRegexpString:(NSString*)SOPClassInStudyRegexpString
        ModalityInStudyRegexpString:(NSString*)ModalityInStudyRegexpString
       StudyDescriptionRegexpString:(NSString*)StudyDescriptionRegexpString
                     hasRestriction:(BOOL)hasRestriction
             SeriesInstanceUIDRegex:(NSRegularExpression*)SeriesInstanceUIDRegex
                  SeriesNumberRegex:(NSRegularExpression*)SeriesNumberRegex
             SeriesDescriptionRegex:(NSRegularExpression*)SeriesDescriptionRegex
                      ModalityRegex:(NSRegularExpression*)ModalityRegex
                      SOPClassRegex:(NSRegularExpression*)SOPClassRegex
                   SOPClassOffRegex:(NSRegularExpression*)SOPClassOffRegex
                         accessType:(NSInteger)accessType
;
@end


@interface DRS (studyTokenDicomzip)

- (RSResponse*)dicomzip4JSONArray:(NSMutableArray*)JSONArray
         canonicalQuerySHA512String:(NSString*)canonicalQuerySHA512String
                     proxyURIString:(NSString*)proxyURIString
                      sessionString:(NSString*)sessionString
                        tokenString:(NSString*)tokenString
                           lanArray:(NSMutableArray*)lanArray
                           wanArray:(NSMutableArray*)wanArray
       StudyInstanceUIDRegexpString:(NSString*)StudyInstanceUIDRegexpString
         AccessionNumberEqualString:(NSString*)AccessionNumberEqualString
           refInstitutionLikeString:(NSString*)refInstitutionLikeString
               refServiceLikeString:(NSString*)refServiceLikeString
                  refUserLikeString:(NSString*)refUserLikeString
                    refIDLikeString:(NSString*)refIDLikeString
                refIDTypeLikeString:(NSString*)refIDTypeLikeString
       readInstitutionSqlLikeString:(NSString*)readInstitutionSqlLikeString
           readServiceSqlLikeString:(NSString*)readServiceSqlLikeString
              readUserSqlLikeString:(NSString*)readUserSqlLikeString
                readIDSqlLikeString:(NSString*)readIDSqlLikeString
            readIDTypeSqlLikeString:(NSString*)readIDTypeSqlLikeString
                  StudyIDLikeString:(NSString*)StudyIDLikeString
                PatientIDLikeString:(NSString*)PatientIDLikeString
            patientFamilyLikeString:(NSString*)patientFamilyLikeString
             patientGivenLikeString:(NSString*)patientGivenLikeString
            patientMiddleLikeString:(NSString*)patientMiddleLikeString
            patientPrefixLikeString:(NSString*)patientPrefixLikeString
            patientSuffixLikeString:(NSString*)patientSuffixLikeString
                        issuerArray:(NSArray*)issuerArray
                     StudyDateArray:(NSArray*)StudyDateArray
        SOPClassInStudyRegexpString:(NSString*)SOPClassInStudyRegexpString
        ModalityInStudyRegexpString:(NSString*)ModalityInStudyRegexpString
       StudyDescriptionRegexpString:(NSString*)StudyDescriptionRegexpString
                     hasRestriction:(BOOL)hasRestriction
             SeriesInstanceUIDRegex:(NSRegularExpression*)SeriesInstanceUIDRegex
                  SeriesNumberRegex:(NSRegularExpression*)SeriesNumberRegex
             SeriesDescriptionRegex:(NSRegularExpression*)SeriesDescriptionRegex
                      ModalityRegex:(NSRegularExpression*)ModalityRegex
                      SOPClassRegex:(NSRegularExpression*)SOPClassRegex
                   SOPClassOffRegex:(NSRegularExpression*)SOPClassOffRegex
                         accessType:(NSInteger)accessType
;
@end


@interface DRS (studyTokenOsirixdcmURLs)

- (RSResponse*)osirixdcmURLs4JSONArray:(NSMutableArray*)JSONArray
         canonicalQuerySHA512String:(NSString*)canonicalQuerySHA512String
                     proxyURIString:(NSString*)proxyURIString
                      sessionString:(NSString*)sessionString
                        tokenString:(NSString*)tokenString
                           lanArray:(NSMutableArray*)lanArray
                           wanArray:(NSMutableArray*)wanArray
       StudyInstanceUIDRegexpString:(NSString*)StudyInstanceUIDRegexpString
         AccessionNumberEqualString:(NSString*)AccessionNumberEqualString
           refInstitutionLikeString:(NSString*)refInstitutionLikeString
               refServiceLikeString:(NSString*)refServiceLikeString
                  refUserLikeString:(NSString*)refUserLikeString
                    refIDLikeString:(NSString*)refIDLikeString
                refIDTypeLikeString:(NSString*)refIDTypeLikeString
       readInstitutionSqlLikeString:(NSString*)readInstitutionSqlLikeString
           readServiceSqlLikeString:(NSString*)readServiceSqlLikeString
              readUserSqlLikeString:(NSString*)readUserSqlLikeString
                readIDSqlLikeString:(NSString*)readIDSqlLikeString
            readIDTypeSqlLikeString:(NSString*)readIDTypeSqlLikeString
                  StudyIDLikeString:(NSString*)StudyIDLikeString
                PatientIDLikeString:(NSString*)PatientIDLikeString
            patientFamilyLikeString:(NSString*)patientFamilyLikeString
             patientGivenLikeString:(NSString*)patientGivenLikeString
            patientMiddleLikeString:(NSString*)patientMiddleLikeString
            patientPrefixLikeString:(NSString*)patientPrefixLikeString
            patientSuffixLikeString:(NSString*)patientSuffixLikeString
                        issuerArray:(NSArray*)issuerArray
                     StudyDateArray:(NSArray*)StudyDateArray
        SOPClassInStudyRegexpString:(NSString*)SOPClassInStudyRegexpString
        ModalityInStudyRegexpString:(NSString*)ModalityInStudyRegexpString
       StudyDescriptionRegexpString:(NSString*)StudyDescriptionRegexpString
                     hasRestriction:(BOOL)hasRestriction
             SeriesInstanceUIDRegex:(NSRegularExpression*)SeriesInstanceUIDRegex
                  SeriesNumberRegex:(NSRegularExpression*)SeriesNumberRegex
             SeriesDescriptionRegex:(NSRegularExpression*)SeriesDescriptionRegex
                      ModalityRegex:(NSRegularExpression*)ModalityRegex
                      SOPClassRegex:(NSRegularExpression*)SOPClassRegex
                   SOPClassOffRegex:(NSRegularExpression*)SOPClassOffRegex
                         accessType:(NSInteger)accessType
;

@end
*/
