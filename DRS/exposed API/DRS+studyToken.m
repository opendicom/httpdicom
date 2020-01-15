/*
 TODO
 socket in messages
 access types other lan and wan nodes
 osirix dcmURLs
 datatablesSeries
 datatablesPatient
 wadors study
 wadors series
 zip real compression
 tokenFolder keeping zipped
 */

#import "DRS+studyToken.h"
#import "DICMTypes.h"
#import "NSString+PCS.h"
#import "NSData+PCS.h"
#import "NSData+ZLIB.h"
#import "WeasisManifest.h"
#import "WeasisArcQuery.h"
#import "WeasisPatient.h"
#import "WeasisStudy.h"
#import "WeasisSeries.h"
#import "WeasisInstance.h"
#import "NSMutableArray+JSON.h"

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


#pragma mark static


// ZIP ISO structure

static uint32 zipLOCAL=0x04034B50;

static uint16 zipVersion=0x000A;//1.0 default value

static uint16 zipBitFlagsNone=0x0000;
static uint16 zipBitFlagsMaxCompression=0x0002;
static uint16 zipBitFlagsDescriptor=0x0008;//post data descriptor

/*
 Bit 2  Bit 1
   0      0    Normal (-en) compression option was used.
   0      1    Maximum (-exx/-ex) compression option was used.
   1      0    Fast (-ef) compression option was used.
   1      1    Super Fast (-es) compression option was used.

 Bit 3: If this bit is set, the fields crc-32, compressed
        size and uncompressed size are set to zero in the
        local header.  The correct values are put in the
        data descriptor immediately following the compressed
        data.  (Note: PKZIP version 2.04g for DOS only
        recognizes this bit for method 8 compression, newer
        versions of PKZIP recognize this bit for any
        compression method.)

 Bit 4: Reserved for use with method 8, for enhanced
        deflating.

 Bit 11: Language encoding flag (EFS).  If this bit is set,
         the filename and comment fields for this file
         MUST be encoded using UTF-8. (see APPENDIX D)
         (we don´t need it since all the names are pure ASCII)
 */
static uint16 zipCompression0=0x0000;
static uint16 zipCompression8=0x0008;
//uint16 zipTime;
//uint16 zipDate;
//uint32 zipCRC32=0x00000000;
//uint32 zipCompressedSize=0x00000000;
//uint32 zipUncompressedSize=0x00000000;
static uint16 zipNameLength=0x0024;//UUID.dcm
static uint16 zipExtraLength=0x0000;
//zipName
//noExtra
//zipData


static uint32 zipDESCRIPTOR=0x08074B50;
//zipCRC32
//zipCompressedSize
//zipUncompressedSize


static uint32 zipCENTRAL=0x02014B50;
static uint16 zipMadeBy=0x13;
//zipVersion
//zipBitFlags
//zipCompression8
//zipTime
//zipDate
//zipCRC32
//zipCompressedSize
//zipUncompressedSize
//zipNameLength
//zipExtraLength
//zipExtraLength comment
//zipExtraLength disk number start
//zipExtraLength internal file attribute
static uint32 zipExternalFileAttributes=0x81A40000;
//uint32 zipRelativeOffsetOfLocal
//zipName
//noExtra
//noComment


static uint32 zipEND=0x06054B50;
static uint16 zipDiskNumber=0x0000;
static uint16 zipDiskCentralStarts=0x0000;
//uint16 zipRecordTotal thisDisk
//zipRecordTotal
//uint32 zipCentralSize;
//uint32 zipCentralOffset;
//zipExtraLength
//noComment


// pk.pk/
static NSString *sqlTwoPks=@"\" | awk -F\\t ' BEGIN{ ORS=\"/\"; OFS=\".\";}{print $1, $2}'";

// item/
static NSString *sqlsingleslash=@"\" | awk -F\\t ' BEGIN{ ORS=\"/\"; OFS=\"\";}{print $1}'";



//recordSeparator+/n  unitSeparator+|
// | sed -e 's/\\x0F\\x0A$//'  (no necesario

static NSString *sqlRecordFourUnits=@"\" | awk -F\\t ' BEGIN{ ORS=\"\\x1E\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4}'";

static NSString *sqlRecordFiveUnits=@"\" | awk -F\\t ' BEGIN{ ORS=\"\\x1E\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4, $5}'";

static NSString *sqlRecordSixUnits=@"\" | awk -F\\t ' BEGIN{ ORS=\"\\x1E\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4, $5, $6}'";

static NSString *sqlRecordEightUnits=@"\" | awk -F\\t ' BEGIN{ ORS=\"\\x1E\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4, $5, $6, $7, $8}'";

static NSString *sqlRecordNineUnits=@"\" | awk -F\\t ' BEGIN{ ORS=\"\\x1E\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4, $5, $6, $7, $8, $9}'";

static NSString *sqlRecordTenUnits=@"\" | awk -F\\t ' BEGIN{ ORS=\"\\x1E\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10}'";

static NSString *sqlRecordElevenUnits=@"\" | awk -F\\t ' BEGIN{ ORS=\"\\x1E\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11}'";

//prolog
//filters...(including eventual IOCM
//limit (or anything else in the MYSQL SELECT after filters)
//epilog


#pragma mark - E,S functions

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
 NSString            * AccessionNumberSqlEqualString,
 NSString            * refInstitutionSqlLikeString,
 NSString            * refServiceSqlLikeString,
 NSString            * refUserSqlLikeString,
 NSString            * refIDSqlLikeString,
 NSString            * refIDTypeSqlLikeString,
 NSString            * readInstitutionSqlLikeString,
 NSString            * readServiceSqlLikeString,
 NSString            * readUserSqlLikeString,
 NSString            * readIDSqlLikeString,
 NSString            * readIDTypeSqlLikeString,
 NSString            * StudyIDSqlLikeString,
 NSString            * PatientIDSqlLikeString,
 NSString            * patientFamilySqlLikeEscapedString,
 NSString            * patientGivenSqlLikeEscapedString,
 NSString            * patientMiddleSqlLikeEscapedString,
 NSString            * patientPrefixSqlLikeEscapedString,
 NSString            * patientSuffixSqlLikeEscapedString,
 NSArray             * issuerArray,
 NSArray             * StudyDateArray,
 NSString            * SOPClassInStudySqlEqualString,
 NSString            * ModalityInStudySqlEqualString,
 NSString            * StudyDescriptionRegexpString
)
{
   NSMutableData * mutableData=[NSMutableData data];
#pragma mark - exclusive study
   if (StudyInstanceUIDRegexpString)
#pragma mark 1 StudyInstanceUID (no optionals)
   {

      if (execUTF8Bash(sqlcredentials,
                        [NSString stringWithFormat:
                         sqlDictionary[@"Eui"],
                         sqlprolog,
                         EuiE?sqlDictionary[@"EuiE"]:sqlDictionary[@"EP"],
                         sqlDictionary[@"WHERE"],
                         StudyInstanceUIDRegexpString,
                         @"",
                         sqlTwoPks
                         ],
                        mutableData)
          !=0) return [RSErrorResponse responseWithClientError:404 message:@"studyToken StudyInstanceUID %@ db error",StudyInstanceUIDRegexpString];
   }
   else if (AccessionNumberSqlEqualString)//3
#pragma mark 2 AccessionNumber (no optionals)
   {

      switch (issuerArray.count) {
            
         case issuerNone:
         {
            if (execUTF8Bash(sqlcredentials,
                        [NSString stringWithFormat:
                         sqlDictionary[@"Ean"][issuerNone],
                         sqlprolog,
                         EuiE?sqlDictionary[@"EuiE"]:sqlDictionary[@"EP"],
                         sqlDictionary[@"WHERE"],
                         AccessionNumberSqlEqualString,
                         @"",
                         sqlTwoPks
                         ],
                        mutableData)
                !=0) return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessionNumber db error. AN='%@' issuer='%@'",AccessionNumberSqlEqualString,[issuerArray componentsJoinedByString:@"^"]];
            } break;

         case issuerLocal:
         {
            if (execUTF8Bash(sqlcredentials,
                             [NSString stringWithFormat:
                              sqlDictionary[@"Ean"][issuerLocal],
                              sqlprolog,
                              EuiE?sqlDictionary[@"EuiE"]:sqlDictionary[@"EP"],
                              sqlDictionary[@"WHERE"],
                              AccessionNumberSqlEqualString,
                              issuerArray[issuerLocal],
                              @"",
                              sqlTwoPks
                             ],
                             mutableData)
                !=0) return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessionNumber db error. AN='%@' issuer='%@'",AccessionNumberSqlEqualString,[issuerArray componentsJoinedByString:@"^"]];
         } break;
                  
         case issuerUniversal:
         {
            if (execUTF8Bash(sqlcredentials,
                             [NSString stringWithFormat:
                              sqlDictionary[@"Ean"][issuerUniversal],
                              sqlprolog,
                              EuiE?sqlDictionary[@"EuiE"]:sqlDictionary[@"EP"],
                              sqlDictionary[@"WHERE"],
                              AccessionNumberSqlEqualString,
                              issuerArray[issuerUniversal],
                              issuerArray[issuerType],
                              @"",
                              sqlTwoPks
                              ],
                             mutableData)
               !=0) return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessionNumber db error. AN='%@' issuer='%@'",AccessionNumberSqlEqualString,[issuerArray componentsJoinedByString:@"^"]];
         } break;

                     
         case issuerDivision:
         {
            if (execUTF8Bash(sqlcredentials,
                             [NSString stringWithFormat:
                              sqlDictionary[@"Ean"][issuerDivision],
                              sqlprolog,
                              EuiE?sqlDictionary[@"EuiE"]:sqlDictionary[@"EP"],
                              sqlDictionary[@"WHERE"],
                              AccessionNumberSqlEqualString,
                              issuerArray[issuerUniversal],
                              issuerArray[issuerType],
                              issuerArray[issuerDivision],
                              @"",
                              sqlTwoPks
                              ],
                             mutableData)
               !=0) return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessionNumber db error. AN='%@' issuer='%@'",AccessionNumberSqlEqualString,[issuerArray componentsJoinedByString:@"^"]];
         } break;

         default:
            return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessionNumber issuer error '%@'",[issuerArray componentsJoinedByString:@"^"]];
            break;
      }
   }
   else
   {
#pragma mark - optionals (study)
      
      NSMutableString *optionals=[NSMutableString string];
      
      if (   refInstitutionSqlLikeString
          || refServiceSqlLikeString
          || refUserSqlLikeString
          || refIDSqlLikeString
          || refIDTypeSqlLikeString
          )
#pragma mark 10 ref
      {
         if (![(sqlDictionary[@"Epn"])[0] isEqualToString:@""])
         {
            // DB with pn compound field
            NSString *regexp=nil;
            if (refIDTypeSqlLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@^%@^%@^%@",
               refInstitutionSqlLikeString?refInstitutionSqlLikeString:@"",
               refServiceSqlLikeString?refServiceSqlLikeString:@"",
               refUserSqlLikeString?refUserSqlLikeString:@"",
               refIDSqlLikeString?refIDSqlLikeString:@"",
               refIDTypeSqlLikeString];
            else if (refIDSqlLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@^%@^%@",
               refInstitutionSqlLikeString?refInstitutionSqlLikeString:@"",
               refServiceSqlLikeString?refServiceSqlLikeString:@"",
               refUserSqlLikeString?refUserSqlLikeString:@"",
               refIDSqlLikeString];
            else if (refUserSqlLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@^%@",
               refInstitutionSqlLikeString?refInstitutionSqlLikeString:@"",
               refServiceSqlLikeString?refServiceSqlLikeString:@"",
               refUserSqlLikeString];
            else if (refServiceSqlLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@",
               refInstitutionSqlLikeString?refInstitutionSqlLikeString:@"",
               refServiceSqlLikeString];
            else if (refInstitutionSqlLikeString)
               regexp=[NSString stringWithString:refInstitutionSqlLikeString];
            
            if (regexp) [optionals appendFormat:(sqlDictionary[@"Epn"])[0],regexp];
         }
         else
         {
            //DB with pn detailed fields
            if (refInstitutionSqlLikeString) [optionals appendFormat:(sqlDictionary[@"Epn"])[1],refInstitutionSqlLikeString];
            if (refServiceSqlLikeString) [optionals appendFormat:(sqlDictionary[@"Epn"])[2],refServiceSqlLikeString];
            if (refUserSqlLikeString) [optionals appendFormat:(sqlDictionary[@"Epn"])[3],refUserSqlLikeString];
            if (refIDSqlLikeString) [optionals appendFormat:(sqlDictionary[@"Epn"])[4],refIDSqlLikeString];
            if (refIDTypeSqlLikeString) [optionals appendFormat:(sqlDictionary[@"Epn"])[5],refIDTypeSqlLikeString];
         }
      }

            
            if (   readInstitutionSqlLikeString
                || readServiceSqlLikeString
                || readUserSqlLikeString
                || readIDSqlLikeString
                || readIDTypeSqlLikeString
                )
      #pragma mark 10 read
            {
               if (![(sqlDictionary[@"Epn"])[0] isEqualToString:@""])
               {
                  // DB with pn compound field
                  NSString *regexp=nil;
                  if (readIDTypeSqlLikeString)
                     regexp=[NSString stringWithFormat:@"%@^%@^%@^%@^%@",
                     readInstitutionSqlLikeString?readInstitutionSqlLikeString:@"",
                     readServiceSqlLikeString?readServiceSqlLikeString:@"",
                     readUserSqlLikeString?readUserSqlLikeString:@"",
                     readIDSqlLikeString?readIDSqlLikeString:@"",
                     readIDTypeSqlLikeString];
                  else if (readIDSqlLikeString)
                     regexp=[NSString stringWithFormat:@"%@^%@^%@^%@",
                     readInstitutionSqlLikeString?readInstitutionSqlLikeString:@"",
                     readServiceSqlLikeString?readServiceSqlLikeString:@"",
                     readUserSqlLikeString?readUserSqlLikeString:@"",
                     readIDSqlLikeString];
                  else if (readUserSqlLikeString)
                     regexp=[NSString stringWithFormat:@"%@^%@^%@",
                     readInstitutionSqlLikeString?readInstitutionSqlLikeString:@"",
                     readServiceSqlLikeString?readServiceSqlLikeString:@"",
                     readUserSqlLikeString];
                  else if (readServiceSqlLikeString)
                     regexp=[NSString stringWithFormat:@"%@^%@",
                     readInstitutionSqlLikeString?readInstitutionSqlLikeString:@"",
                     readServiceSqlLikeString];
                  else if (readInstitutionSqlLikeString)
                     regexp=[NSString stringWithString:readInstitutionSqlLikeString];
                  
                  if (regexp) [optionals appendFormat:(sqlDictionary[@"Epn"])[0],regexp];
               }
               else
               {
                  //DB with pn detailed fields
                  if (readInstitutionSqlLikeString) [optionals appendFormat:(sqlDictionary[@"Epn"])[1],readInstitutionSqlLikeString];
                  if (readServiceSqlLikeString) [optionals appendFormat:(sqlDictionary[@"Epn"])[2],readServiceSqlLikeString];
                  if (readUserSqlLikeString) [optionals appendFormat:(sqlDictionary[@"Epn"])[3],readUserSqlLikeString];
                  if (readIDSqlLikeString) [optionals appendFormat:(sqlDictionary[@"Epn"])[4],readIDSqlLikeString];
                  if (readIDTypeSqlLikeString) [optionals appendFormat:(sqlDictionary[@"Epn"])[5],readIDTypeSqlLikeString];
               }
            }

#pragma mark 11 (optional) StudyDate Eda
      //(Eda)
      if (StudyDateArray)
      {
         switch (StudyDateArray.count) {
            case dateMatchAny:
               break;
            case dateMatchOn:
            {
               [optionals appendFormat:sqlDictionary[@"Eda"][dateMatchOn],StudyDateArray[0]];
            } break;
            case dateMatchSince:
            {
               [optionals appendFormat:sqlDictionary[@"Eda"][dateMatchSince],StudyDateArray[1]];
            } break;
            case dateMatchUntil:
            {
               [optionals appendFormat:sqlDictionary[@"Eda"][dateMatchUntil],StudyDateArray[2]];

            } break;
            case dateMatchBetween:
            {
               [optionals appendFormat:sqlDictionary[@"Eda"][dateMatchBetween],StudyDateArray[0],StudyDateArray[3]];

            } break;
         }
      }

#pragma mark 12 (optional) StudyDescription Elo
      if (StudyDescriptionRegexpString)
         [optionals appendFormat:sqlDictionary[@"Elo"],StudyDescriptionRegexpString];

#pragma mark 13 (optional) SOPClassesInStudy Ecu
      if (SOPClassInStudySqlEqualString)
         [optionals appendFormat:sqlDictionary[@"Ecu"],SOPClassInStudySqlEqualString];

#pragma mark 14 (optional) ModalitiesInStudy Emo
      if (ModalityInStudySqlEqualString)
         [optionals appendFormat:sqlDictionary[@"Emo"],ModalityInStudySqlEqualString];

      
      
#pragma mark - study base

      if (StudyIDSqlLikeString)
      {
#pragma mark 19 StudyID (+optionals)
         NSString *sqlQuery=[NSString stringWithFormat:
                             sqlDictionary[@"Eid"],
                             sqlprolog,
                             StudyIDSqlLikeString,
                             optionals,
                             @"",
                             sqlTwoPks
                             ];
         if (execUTF8Bash(sqlcredentials,sqlQuery,mutableData)!=0)
         {
            return [RSErrorResponse responseWithClientError:404 message:@"studyToken StudyID '%@' db error.",StudyIDSqlLikeString];
            LOG_WARNING(@"%@",sqlQuery);
         }
      }
      else if (PatientIDSqlLikeString)
      {
#pragma mark - optionals (patient)
         if (   patientFamilySqlLikeEscapedString
             || patientGivenSqlLikeEscapedString
             || patientMiddleSqlLikeEscapedString
             || patientPrefixSqlLikeEscapedString
             || patientSuffixSqlLikeEscapedString
             )
   #pragma mark 20 patient
         {
            if (![(sqlDictionary[@"Ppn"])[0] isEqualToString:@""])
            {
               // DB with pn compound field
               NSString *regexp=nil;
               if (patientSuffixSqlLikeEscapedString)
                  regexp=[NSString stringWithFormat:@"%@^%@^%@^%@^%@",
                  patientFamilySqlLikeEscapedString?patientFamilySqlLikeEscapedString:@"",
                  patientGivenSqlLikeEscapedString?patientGivenSqlLikeEscapedString:@"",
                  patientMiddleSqlLikeEscapedString?patientMiddleSqlLikeEscapedString:@"",
                  patientPrefixSqlLikeEscapedString?patientPrefixSqlLikeEscapedString:@"",
                  patientSuffixSqlLikeEscapedString];
               else if (patientPrefixSqlLikeEscapedString)
                  regexp=[NSString stringWithFormat:@"%@^%@^%@^%@",
                  patientFamilySqlLikeEscapedString?patientFamilySqlLikeEscapedString:@"",
                  patientGivenSqlLikeEscapedString?patientGivenSqlLikeEscapedString:@"",
                  patientMiddleSqlLikeEscapedString?patientMiddleSqlLikeEscapedString:@"",
                  patientPrefixSqlLikeEscapedString];
               else if (patientMiddleSqlLikeEscapedString)
                  regexp=[NSString stringWithFormat:@"%@^%@^%@",
                  patientFamilySqlLikeEscapedString?patientFamilySqlLikeEscapedString:@"",
                  patientGivenSqlLikeEscapedString?patientGivenSqlLikeEscapedString:@"",
                  patientMiddleSqlLikeEscapedString];
               else if (patientGivenSqlLikeEscapedString)
                  regexp=[NSString stringWithFormat:@"%@^%@",
                  patientFamilySqlLikeEscapedString?patientFamilySqlLikeEscapedString:@"",
                  patientGivenSqlLikeEscapedString];
               else if (patientFamilySqlLikeEscapedString)
                  regexp=[NSString stringWithString:patientFamilySqlLikeEscapedString];
               
               if (regexp) [optionals appendFormat:(sqlDictionary[@"Ppn"])[0],regexp];
            }
            else
            {
               //DB with pn detailed fields
               if (patientFamilySqlLikeEscapedString) [optionals appendFormat:(sqlDictionary[@"Ppn"])[1],patientFamilySqlLikeEscapedString];
               if (patientGivenSqlLikeEscapedString) [optionals appendFormat:(sqlDictionary[@"Ppn"])[2],patientGivenSqlLikeEscapedString];
               if (patientMiddleSqlLikeEscapedString) [optionals appendFormat:(sqlDictionary[@"Ppn"])[3],patientMiddleSqlLikeEscapedString];
               if (patientPrefixSqlLikeEscapedString) [optionals appendFormat:(sqlDictionary[@"Ppn"])[4],patientPrefixSqlLikeEscapedString];
               if (patientSuffixSqlLikeEscapedString) [optionals appendFormat:(sqlDictionary[@"Ppn"])[5],patientSuffixSqlLikeEscapedString];
            }
#pragma mark - patient base
#pragma mark 4 PatientID (optionals Eda Ecu Emo Elo)
            switch (issuerArray.count) {
                  
               case issuerNone:
               {
                  NSString *sqlQuery=[NSString stringWithFormat:
                                      sqlDictionary[@"Pid"][issuerNone],
                                      sqlprolog,
                                      PatientIDSqlLikeString,
                                      optionals,
                                      @"",
                                      sqlTwoPks
                                      ];
                  if (execUTF8Bash(sqlcredentials,sqlQuery,mutableData)!=0)
                  {
                     return [RSErrorResponse responseWithClientError:404 message:@"studyToken PatientID '%@' db error.",PatientIDSqlLikeString];
                     LOG_WARNING(@"%@",sqlQuery);
                  }
               } break;

               case issuerLocal:
               {
                  NSString *sqlQuery=[NSString stringWithFormat:
                                      sqlDictionary[@"Pid"][issuerLocal],
                                      sqlprolog,
                                      PatientIDSqlLikeString,
                                      issuerArray[issuerLocal],
                                      optionals,
                                      @"",
                                      sqlTwoPks
                                      ];
                  if (execUTF8Bash(sqlcredentials,sqlQuery,mutableData)!=0)
                  {
                     return [RSErrorResponse responseWithClientError:404 message:@"studyToken PatientID '%@' db error.",PatientIDSqlLikeString];
                     LOG_WARNING(@"%@",sqlQuery);
                  }
               } break;

               default:
                  return [RSErrorResponse responseWithClientError:404 message:@"studyToken patientID issuer error '%@'",[issuerArray componentsJoinedByString:@"^"]];
                  break;
            }
         }
      }
      else return [RSErrorResponse responseWithClientError:404 message:@"studyToken neither StudyInstanceUID, nor AccessionNumber, nor PatientID, nor StudyID, nor PatientName, nor ReferringPhysician present in the query"];
    }

    if ([mutableData length]==0)
    {
      LOG_VERBOSE(@"studyToken empty response");
      return nil;
    }
    for (NSString *pkdotpk in [[[NSString alloc]initWithData:mutableData encoding:NSUTF8StringEncoding]componentsSeparatedByString:@"/"])
    {
        if (pkdotpk.length) [EPDict setObject:[pkdotpk pathExtension] forKey:[pkdotpk stringByDeletingPathExtension]];
    }
    //record terminated by /

    return nil;
}


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
)
{
   NSMutableData *SOPClassData=[NSMutableData dataWithCapacity:64];
   if (execUTF8Bash(sqlcredentials,
                     [NSString stringWithFormat:
                      sqlIci4S,
                      sqlprolog,
                      SProperties[0],
                      @"limit 1",
                      @"\" | awk -F\\t ' BEGIN{ ORS=\"\"; OFS=\"\";}{print $1}'"
                      ],
                     SOPClassData)
       !=0)
   {
      LOG_ERROR(@"studyToken SOPClassData");
      return nil;
   }
   if (!SOPClassData.length) return nil;
   NSString *SOPClassString=[[NSString alloc] initWithData:SOPClassData  encoding:NSUTF8StringEncoding];
   /*
    //dicom cda
   if ([(IPropertiesFirstRecord[0])[3] isEqualToString:@"1.2.840.10008.5.1.4.1.1.104.2"]) continue;
   //SR
   if ([(IPropertiesFirstRecord[0])[3] hasPrefix:@"1.2.840.10008.5.1.4.1.1.88"])continue;
    
    //replaced by SOPClassOff
   */

   if (
          (    SeriesInstanceUIDRegex
            &&![SeriesInstanceUIDRegex
                numberOfMatchesInString:SProperties[1]
                options:0
                range:NSMakeRange(0, [SProperties[1] length])
                ]
            )
       ||  (    SeriesNumberRegex
            &&![SeriesNumberRegex
                numberOfMatchesInString:SProperties[3]
                options:0
                range:NSMakeRange(0, [SProperties[3] length])
                ]
            )
       ||  (    SeriesDescriptionRegex
            &&![SeriesDescriptionRegex
                numberOfMatchesInString:SProperties[2]
                options:0
                range:NSMakeRange(0, [SProperties[2] length])
                ]
            )
       ||  (    ModalityRegex
            &&![ModalityRegex
                numberOfMatchesInString:SProperties[4]
                options:0
                range:NSMakeRange(0, [SProperties[4] length])
                ]
            )
       ||  (    SOPClassRegex
            &&![SOPClassRegex
                numberOfMatchesInString:SOPClassString
                options:0
                range:NSMakeRange(0, SOPClassString.length)
                ]
            )
       ||  (    SOPClassOffRegex
            && [SOPClassOffRegex
                  numberOfMatchesInString:SOPClassString
                  options:0
                  range:NSMakeRange(0, SOPClassString.length)
                  ]
            )

       ) return nil;
    return SOPClassString;
};

#pragma mark - accessType functions

RSResponse * weasis(
 NSMutableArray      * JSONArray,
 NSString            * canonicalQuerySHA512String,
 NSString            * proxyURIString,
 NSString            * sessionString,
 NSString            * tokenString,
 NSMutableArray      * lanArray,
 NSMutableArray      * wanArray,
 NSString            * StudyInstanceUIDRegexpString,
 NSString            * AccessionNumberSqlEqualString,
 NSString            * refInstitutionSqlLikeString,
 NSString            * refServiceSqlLikeString,
 NSString            * refUserSqlLikeString,
 NSString            * refIDSqlLikeString,
 NSString            * refIDTypeSqlLikeString,
 NSString            * readInstitutionSqlLikeString,
 NSString            * readServiceSqlLikeString,
 NSString            * readUserSqlLikeString,
 NSString            * readIDSqlLikeString,
 NSString            * readIDTypeSqlLikeString,
 NSString            * StudyIDSqlLikeString,
 NSString            * PatientIDSqlLikeString,
 NSString            * patientFamilySqlLikeEscapedString,
 NSString            * patientGivenSqlLikeEscapedString,
 NSString            * patientMiddleSqlLikeEscapedString,
 NSString            * patientPrefixSqlLikeEscapedString,
 NSString            * patientSuffixSqlLikeEscapedString,
 NSArray             * issuerArray,
 NSArray             * StudyDateArray,
 NSString            * SOPClassInStudySqlEqualString,
 NSString            * ModalityInStudySqlEqualString,
 NSString            * StudyDescriptionRegexpString,
 BOOL                  hasRestriction,
 NSRegularExpression * SeriesInstanceUIDRegex,
 NSRegularExpression * SeriesNumberRegex,
 NSRegularExpression * SeriesDescriptionRegex,
 NSRegularExpression * ModalityRegex,
 NSRegularExpression * SOPClassRegex,
 NSRegularExpression * SOPClassOffRegex,
 NSInteger             accessType
)
{
   NSXMLElement *XMLRoot=[WeasisManifest manifest];
            
   if (lanArray.count > 1)
   {
      //add nodes and start corresponding processes
   }

   if (wanArray.count > 0)
   {
      //add nodes and start corresponding processes
   }

   if (lanArray.count == 0)
   {
      //add nodes and start corresponding processes
   }
   else
   {
      while (1)
      {
         NSString *devOID=lanArray[0];
         NSDictionary *devDict=DRS.pacs[devOID];

#pragma mark · GET type index
         NSUInteger getTypeIndex=[@[@"file",@"folder",@"wado",@"wadors",@"cget",@"cmove"] indexOfObject:devDict[@"get"]];

#pragma mark · SELECT switch
         switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:devDict[@"select"]]) {
            
            case NSNotFound:{
               LOG_WARNING(@"studyToken pacs %@ lacks \"select\" type property",devOID);
            } break;
               
            case selectTypeSql:{
   #pragma mark · SQL SELECT (unique option for now)
               NSDictionary *sqlcredentials=@{devDict[@"sqlcredentials"]:devDict[@"sqlpassword"]};
               NSString *sqlprolog=devDict[@"sqlprolog"];
               NSDictionary *sqlDictionary=DRS.sqls[devDict[@"sqlmap"]];

               
#pragma mark · apply EP (Study Patient) filters
               NSMutableDictionary *EPDict=[NSMutableDictionary dictionary];
               RSResponse *sqlEPErrorReturned=sqlEP(
                EPDict,
                sqlcredentials,
                sqlDictionary,
                sqlprolog,
                false,
                StudyInstanceUIDRegexpString,
                AccessionNumberSqlEqualString,
                refInstitutionSqlLikeString,
                refServiceSqlLikeString,
                refUserSqlLikeString,
                refIDSqlLikeString,
                refIDTypeSqlLikeString,
                readInstitutionSqlLikeString,
                readServiceSqlLikeString,
                readUserSqlLikeString,
                readIDSqlLikeString,
                readIDTypeSqlLikeString,
                StudyIDSqlLikeString,
                PatientIDSqlLikeString,
                patientFamilySqlLikeEscapedString,
                patientGivenSqlLikeEscapedString,
                patientMiddleSqlLikeEscapedString,
                patientPrefixSqlLikeEscapedString,
                patientSuffixSqlLikeEscapedString,
                issuerArray,
                StudyDateArray,
                SOPClassInStudySqlEqualString,
                ModalityInStudySqlEqualString,
                StudyDescriptionRegexpString
               );
               if (sqlEPErrorReturned) return sqlEPErrorReturned;

               
               NSXMLElement *arcQueryElement=
                     [WeasisArcQuery arcQueryId:sessionString weasisarcId:devOID weasisbaseUrl:proxyURIString weasiswebLogin:nil weasisrequireOnlySOPInstanceUID:nil weasisadditionnalParameters:nil weasisoverrideDicomTagsList:nil seriesFilterInstanceUID:SeriesInstanceUIDRegex.pattern seriesFilterNumber:SeriesNumberRegex.pattern seriesFilterDescription:SeriesDescriptionRegex.pattern seriesFilterModality:ModalityRegex.pattern seriesFilterSOPClass:SOPClassRegex.pattern seriesFilterSOPClassOff:SOPClassOffRegex.pattern
                      ];
                     [XMLRoot addChild:arcQueryElement];

#pragma mark ·· GET switch
               switch (getTypeIndex) {
                     
                  case NSNotFound:{
                     LOG_WARNING(@"studyToken pacs %@ lacks \"get\" property",devOID);
                  } break;

                  case getTypeWado:{
#pragma mark ·· WADO (unique option for now)
                     
#pragma mark ...patient loop
                     NSMutableData *mutableData=[NSMutableData data];
                     for (NSString *P in [NSSet setWithArray:[EPDict allValues]])
                     {
                        [mutableData setData:[NSData data]];
                        if (execUTF8Bash(sqlcredentials,
                                          [NSString stringWithFormat:
                                           sqlDictionary[@"P"],
                                           sqlprolog,
                                           P,
                                           @"",
                                           sqlRecordSixUnits
                                           ],
                                          mutableData)
                            !=0)
                        {
                           LOG_ERROR(@"studyToken patient db error");
                           continue;
                        }
NSXMLElement *PatientElement=nil;
                        NSArray *patientSqlPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding
                        PatientElement=
                        [WeasisPatient pk:(patientSqlPropertiesArray[0])[0] weasisPatientID:(patientSqlPropertiesArray[0])[1] weasisPatientName:(patientSqlPropertiesArray[0])[2] weasisIssuerOfPatientID:(patientSqlPropertiesArray[0])[3] weasisPatientBirthDate:(patientSqlPropertiesArray[0])[4] weasisPatientBirthTime:nil weasisPatientSex:(patientSqlPropertiesArray[0])[5]
                         ];
                        [arcQueryElement addChild:PatientElement];
                              

//#pragma mark study loop
                        for (NSString *E in EPDict)
                        {
                           if ([EPDict[E] isEqualToString:P])
                           {
                              [mutableData setData:[NSData data]];
                              if (execUTF8Bash(sqlcredentials,
                                                [NSString stringWithFormat:
                                                 sqlDictionary[@"E"],
                                                 sqlprolog,
                                                 E,
                                                 @"",
                                                 sqlRecordTenUnits
                                                 ],
                                                mutableData)
                                  !=0)
                              {
                                 LOG_ERROR(@"studyToken study db error");
                                 continue;
                              }
   NSXMLElement *StudyElement=nil;//Study=Exam
                              NSArray *EPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:3 decreasing:YES];//NSUTF8StringEncoding
    
                              StudyElement=
                              [WeasisStudy pk:(EPropertiesArray[0])[0] weasisStudyInstanceUID:(EPropertiesArray[0])[1] weasisStudyDescription:(EPropertiesArray[0])[2] weasisStudyDate:[DICMTypes DAStringFromDAISOString:(EPropertiesArray[0])[3]] weasisStudyTime:[DICMTypes TMStringFromTMISOString:(EPropertiesArray[0])[4]] weasisAccessionNumber:(EPropertiesArray[0])[5] weasisStudyId:(EPropertiesArray[0])[6] weasisReferringPhysicianName:(EPropertiesArray[0])[7] issuer:nil issuerType:nil series:(EPropertiesArray[0])[8] modalities:(EPropertiesArray[0])[9]
                               ];
                              [PatientElement addChild:StudyElement];
                               
                        [mutableData setData:[NSData data]];
                        if (execUTF8Bash(sqlcredentials,
                                          [NSString stringWithFormat:
                                           sqlDictionary[@"S"],
                                           sqlprolog,
                                           E,
                                           @"",
                                           sqlRecordTenUnits
                                           ],
                                          mutableData)
                            !=0)
                        {
                           LOG_ERROR(@"studyToken study db error");
                           continue;
                        }
                        NSArray *SPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:3 decreasing:NO];//NSUTF8StringEncoding
                        for (NSArray *SProperties in SPropertiesArray)
                        {
                           NSString *SOPClass=SOPCLassOfReturnableSeries(
                            sqlcredentials,
                            sqlDictionary[@"Ici4S"],
                            sqlprolog,
                            SProperties,
                            SeriesInstanceUIDRegex,
                            SeriesNumberRegex,
                            SeriesDescriptionRegex,
                            ModalityRegex,
                            SOPClassRegex,
                            SOPClassOffRegex
                           );
                           if (SOPClass)
                           {
                              //instances
                              [mutableData setData:[NSData data]];
                              if (execUTF8Bash(sqlcredentials,
                                                [NSString stringWithFormat:
                                                 sqlDictionary[@"I"],
                                                 sqlprolog,
                                                 SProperties[0],
                                                 @"",
                                                 sqlRecordFourUnits
                                                 ],
                                                mutableData)
                                  !=0)
                              {
                                 LOG_ERROR(@"studyToken study db error");
                                 continue;
                              }
                              NSArray *IPropertiesArray=[mutableData
                               arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding
                               orderedByUnitIndex:2
                               decreasing:NO
                               ];//NSUTF8StringEncoding

   //#pragma mark series loop
                              NSXMLElement *SeriesElement=[WeasisSeries pk:SProperties[0] weasisSeriesInstanceUID:SProperties[1] weasisSeriesDescription:SProperties[2] weasisSeriesNumber:SProperties[3] weasisModality:SProperties[4] weasisWadoTransferSyntaxUID:@"*" weasisWadoCompressionRate:nil weasisDirectDownloadThumbnail:nil sop:nil images:nil
                              ];
                              [StudyElement addChild:SeriesElement];
                                    

   //#pragma mark instance loop
                              for (NSArray *IProperties in IPropertiesArray)
                              {
   //#pragma mark instance loop
                                 NSXMLElement *InstanceElement=[WeasisInstance pk:IProperties[0] weasisSOPInstanceUID:IProperties[1] weasisInstanceNumber:IProperties[2] weasisDirectDownloadFile:nil
                                  ];//DirectDownloadFile
                                  [SeriesElement addChild:InstanceElement];
                                 }
                                 }//end for each I
                              }//end without restriction
                           }// end for each S
                        }//end for each E
                     }//end for each P
                  } break;//end of WADO
               }// end of GET switch
            } break;//end of sql
         } //end of SELECT switch

         /*
          if (!XMLRoot.childCount)
          {
          }
          */
         NSXMLDocument *doc=[NSXMLDocument documentWithRootElement:XMLRoot];
          doc.documentContentKind=NSXMLDocumentXMLKind;
          doc.characterEncoding=@"UTF-8";
          /*
          NSData *docData=[doc XMLData];
          return
          [RSDataResponse
           responseWithData:docData
           contentType:@"text/xml"
           ];
           */
         NSData *docData=[doc XMLData];
         if (DRS.tokentmpDir.length)
         [docData writeToFile:
           [
            [DRS.tokentmpDir stringByAppendingPathComponent:sessionString]
            stringByAppendingPathExtension:@"xml"]
          atomically:NO];
         
         return
         [RSDataResponse
          responseWithData:[docData gzip]
          contentType:@"application/x-gzip"
          ];

//base64 dicom:get -i does not work
/*
RSDataResponse *response=[RSDataResponse responseWithData:[[[LFCGzipUtility gzipData:[xmlweasismanifest dataUsingEncoding:NSUTF8StringEncoding]] base64EncodedStringWithOptions:0]dataUsingEncoding:NSUTF8StringEncoding] contentType:@"application/x-gzip"];
[response setValue:@"Base64" forAdditionalHeader:@"Content-Transfer-Encoding"];//https://tools.ietf.org/html/rfc2045
return response;

//xml dicom:get -iw works also, like with gzip
return [RSDataResponse
responseWithData:[xmlweasismanifest dataUsingEncoding:NSUTF8StringEncoding]
contentType:@"text/xml"];
*/
               
               
      }//end while 1

   }//end at least one dev
   return [RSErrorResponse responseWithClientError:404 message:@"studyToken should not be here"];
}


RSResponse* cornerstone(
 NSMutableArray      * JSONArray,
 NSString            * canonicalQuerySHA512String,
 NSString            * proxyURIString,
 NSString            * sessionString,
 NSString            * tokenString,
 NSMutableArray      * lanArray,
 NSMutableArray      * wanArray,
 NSString            * StudyInstanceUIDRegexpString,
 NSString            * AccessionNumberSqlEqualString,
 NSString            * refInstitutionSqlLikeString,
 NSString            * refServiceSqlLikeString,
 NSString            * refUserSqlLikeString,
 NSString            * refIDSqlLikeString,
 NSString            * refIDTypeSqlLikeString,
 NSString            * readInstitutionSqlLikeString,
 NSString            * readServiceSqlLikeString,
 NSString            * readUserSqlLikeString,
 NSString            * readIDSqlLikeString,
 NSString            * readIDTypeSqlLikeString,
 NSString            * StudyIDSqlLikeString,
 NSString            * PatientIDSqlLikeString,
 NSString            * patientFamilySqlLikeEscapedString,
 NSString            * patientGivenSqlLikeEscapedString,
 NSString            * patientMiddleSqlLikeEscapedString,
 NSString            * patientPrefixSqlLikeEscapedString,
 NSString            * patientSuffixSqlLikeEscapedString,
 NSArray             * issuerArray,
 NSArray             * StudyDateArray,
 NSString            * SOPClassInStudySqlEqualString,
 NSString            * ModalityInStudySqlEqualString,
 NSString            * StudyDescriptionRegexpString,
 BOOL                  hasRestriction,
 NSRegularExpression * SeriesInstanceUIDRegex,
 NSRegularExpression * SeriesNumberRegex,
 NSRegularExpression * SeriesDescriptionRegex,
 NSRegularExpression * ModalityRegex,
 NSRegularExpression * SOPClassRegex,
 NSRegularExpression * SOPClassOffRegex,
 NSInteger             accessType
)
{

      if (lanArray.count > 1)
      {
         //add nodes and start corresponding processes
      }

      if (wanArray.count > 0)
      {
         //add nodes and start corresponding processes
      }

      if (lanArray.count == 0)
      {
         //add nodes and start corresponding processes
      }
      else
      {
         while (1)
         {
            NSString *devOID=lanArray[0];
            NSDictionary *devDict=DRS.pacs[devOID];
#pragma mark · GET type index
            NSUInteger getTypeIndex=[@[@"file",@"folder",@"wado",@"wadors",@"cget",@"cmove"] indexOfObject:devDict[@"get"]];

#pragma mark · SELECT switch
                  
               switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:devDict[@"select"]]) {
               
               case NSNotFound:{
                  LOG_WARNING(@"studyToken pacs %@ lacks \"select\" type property",devOID);
               } break;
                  
               case selectTypeSql:{
      #pragma mark · SQL SELECT (unique option for now)
                  NSDictionary *sqlcredentials=@{devDict[@"sqlcredentials"]:devDict[@"sqlpassword"]};
                  NSString *sqlprolog=devDict[@"sqlprolog"];
                  NSDictionary *sqlDictionary=DRS.sqls[devDict[@"sqlmap"]];

#pragma mark · apply EP (Study Patient) filters
                  NSMutableDictionary *EPDict=[NSMutableDictionary dictionary];
                  RSResponse *sqlEPErrorReturned=sqlEP(
                   EPDict,
                   sqlcredentials,
                   sqlDictionary,
                   sqlprolog,
                   false,
                   StudyInstanceUIDRegexpString,
                   AccessionNumberSqlEqualString,
                   refInstitutionSqlLikeString,
                   refServiceSqlLikeString,
                   refUserSqlLikeString,
                   refIDSqlLikeString,
                   refIDTypeSqlLikeString,
                   readInstitutionSqlLikeString,
                   readServiceSqlLikeString,
                   readUserSqlLikeString,
                   readIDSqlLikeString,
                   readIDTypeSqlLikeString,
                   StudyIDSqlLikeString,
                   PatientIDSqlLikeString,
                   patientFamilySqlLikeEscapedString,
                   patientGivenSqlLikeEscapedString,
                   patientMiddleSqlLikeEscapedString,
                   patientPrefixSqlLikeEscapedString,
                   patientSuffixSqlLikeEscapedString,
                   issuerArray,
                   StudyDateArray,
                   SOPClassInStudySqlEqualString,
                   ModalityInStudySqlEqualString,
                   StudyDescriptionRegexpString
                  );
                  if (sqlEPErrorReturned) return sqlEPErrorReturned;


                  //find devOID in JSONArray
                  NSMutableArray *patientArray=nil;
                  NSMutableDictionary *arc=[JSONArray firstMutableDictionaryWithKey:@"arcId" isEqualToString:devOID];
                  if (arc)
                  {
                     //update cached arc and get cached patients
                     [arc setObject:proxyURIString forKey:@"baseUrl"];
                     patientArray=arc[@"patientList"];
                     if (!patientArray)
                     {
                        patientArray=[NSMutableArray array];
                        [arc setObject:patientArray forKey:@"patientList"];
                     }
                  }
                  else //no arc
                  {
                     //create arc
                     patientArray=[NSMutableArray array];
                     arc=[NSMutableDictionary dictionaryWithObjectsAndKeys:
                          devOID, @"arcId",
                          proxyURIString,@"baseUrl",
                          patientArray,@"patientList",
                          nil];
                  }

   #pragma mark ·· GET switch
                  switch (getTypeIndex) {
                        
                     case NSNotFound:{
                        LOG_WARNING(@"studyToken pacs %@ lacks \"get\" property",devOID);
                     } break;

                     case getTypeWado:{
   #pragma mark ·· WADO (unique option for now)
                        
   #pragma mark ...patient loop
                        NSMutableData *mutableData=[NSMutableData data];
                        for (NSString *P in [NSSet setWithArray:[EPDict allValues]])
                        {
                           [mutableData setData:[NSData data]];
                           if (execUTF8Bash(sqlcredentials,
                                             [NSString stringWithFormat:
                                              sqlDictionary[@"P"],
                                              sqlprolog,
                                              P,
                                              @"",
                                              sqlRecordSixUnits
                                              ],
                                             mutableData)
                               !=0)
                           {
                              LOG_ERROR(@"studyToken patient db error");
                              continue;
                           }
                           NSArray *patientSqlPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding
                           
                           NSMutableDictionary *patient=[patientArray firstMutableDictionaryWithKey:@"key" isEqualToString:P];
                           NSMutableArray *studyArray=nil;
                           
if (patient)
{
   //report eventual actualizations
   [patient setObject:(patientSqlPropertiesArray[0])[1] forKey:@"PatientID"];
   [patient setObject:(patientSqlPropertiesArray[0])[2] forKey:@"PatientName"];
   [patient setObject:(patientSqlPropertiesArray[0])[3] forKey:@"IssuerOfPatientID"];
   [patient setObject:(patientSqlPropertiesArray[0])[4] forKey:@"PatientBirthDate"];
   [patient setObject:(patientSqlPropertiesArray[0])[5] forKey:@"PatientSex"];
   studyArray=arc[@"studyList"];
   if (!studyArray)
   {
      studyArray=[NSMutableArray array];
      [patient setObject:studyArray forKey:@"studyList"];
   }
}
else //no patient
{
   patientArray=[NSMutableArray array];
   patient=[NSMutableDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithLongLong:[(patientSqlPropertiesArray[0])[0] longLongValue]],@"key",
            (patientSqlPropertiesArray[0])[1], @"PatientID",
            (patientSqlPropertiesArray[0])[2],@"PatientName",
            (patientSqlPropertiesArray[0])[3],@"IssuerOfPatientID",
            (patientSqlPropertiesArray[0])[4],@"PatientBirthDate",
            (patientSqlPropertiesArray[0])[5],@"PatientSex",
            studyArray,@"studyList",
            nil
           ];
}
#pragma mark ...study loop
                        for (NSString *E in EPDict)
                        {
                           if ([EPDict[E] isEqualToString:P])
                           {
                              [mutableData setData:[NSData data]];
                              if (execUTF8Bash(sqlcredentials,
                                                [NSString stringWithFormat:
                                                 sqlDictionary[@"E"],
                                                 sqlprolog,
                                                 E,
                                                 @"",
                                                 sqlRecordNineUnits
                                                 ],
                                                mutableData)
                                  !=0)
                              {
                                 LOG_ERROR(@"studyToken study db error");
                                 continue;
                              }
                              NSArray *studySqlPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:3 decreasing:YES];//NSUTF8StringEncoding

                              NSMutableDictionary *study=[studyArray firstMutableDictionaryWithKey:@"key" isEqualToString:E];
                              NSMutableArray *seriesArray=nil;
if (study)
{
   //report eventual actualizations
   [study  setObject:(studySqlPropertiesArray[0])[2] forKey:@"studyDescription"];
   [study  setObject:(studySqlPropertiesArray[0])[6] forKey:@"StudyID"];
   [study  setObject:(studySqlPropertiesArray[0])[7] forKey:@"ReferringPhysicianName"];
   if (!seriesArray)
   {
      seriesArray=[NSMutableArray array];
      [study setObject:seriesArray forKey:@"seriesList"];
   }
}
else //no study
{
#pragma mark TODO accessionNumber issuer
   //pk
                                 //study_iuid,study_desc,DATE(study_datetime),TIME(study_datetime),accession_no,study_id,ref_physician,
                                 //mods_in_study
   seriesArray=[NSMutableArray array];
   study=[NSMutableDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithLongLong:[(studySqlPropertiesArray[0])[0] longLongValue]],@"key",
      (studySqlPropertiesArray[0])[1], @"StudyInstanceUID",
      (studySqlPropertiesArray[0])[2], @"studyDescription",
      [DICMTypes DAStringFromDAISOString:(studySqlPropertiesArray[0])[3]], @"studyDate",
      [DICMTypes TMStringFromTMISOString:(studySqlPropertiesArray[0])[4]],@"StudyTime",
      (studySqlPropertiesArray[0])[5],@"AccessionNumber",
      (studySqlPropertiesArray[0])[6],@"StudyID",
      (studySqlPropertiesArray[0])[7],@"ReferringPhysicianName",
      (studySqlPropertiesArray[0])[8],@"modality",
      (patientSqlPropertiesArray[0])[1],@"patientId",
      (patientSqlPropertiesArray[0])[2],@"patientName",
      seriesArray,@"seriesList",
      nil
   ];
}
                              
#pragma mark ...series loop

                        [mutableData setData:[NSData data]];
                        if (execUTF8Bash(sqlcredentials,
                                          [NSString stringWithFormat:
                                           sqlDictionary[@"S"],
                                           sqlprolog,
                                           E,
                                           @"",
                                           sqlRecordElevenUnits
                                           ],
                                          mutableData)
                            !=0)
                        {
                           LOG_ERROR(@"studyToken series db error");
                           continue;
                        }
                        NSArray *seriesSqlPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:3 decreasing:NO];//NSUTF8StringEncoding
                        for (NSArray *seriesSqlProperties in seriesSqlPropertiesArray)
                        {
                           //if series exists in cache
                           NSMutableDictionary *series=[seriesArray firstMutableDictionaryWithKey:@"key" isEqualToString:seriesSqlProperties[0]];
                           if (series)
                           {
                              //SOP Class already known
                              //loop series only if numImages doesn´t correspond
                              if ([series[@"numImages"] longLongValue]!=[seriesSqlProperties[10]longLongValue])
                              {
                                 //loop instances
#pragma mark TODO
                              }
                           }
                           else //series no existe en cache
                           {
                              //add it?
                              NSString *SOPClass=SOPCLassOfReturnableSeries(
                                                       sqlcredentials,
                                                       sqlDictionary[@"Ici4S"],
                                                       sqlprolog,
                                                       seriesSqlProperties,
                                                       SeriesInstanceUIDRegex,
                                                       SeriesNumberRegex,
                                                       SeriesDescriptionRegex,
                                                       ModalityRegex,
                                                       SOPClassRegex,
                                                       SOPClassOffRegex
                                                      );
                              if (SOPClass)
                              {
                                 //yes, add it
                                 
NSMutableArray *instanceArray=[NSMutableArray array];
series=[NSMutableDictionary dictionaryWithObjectsAndKeys:
[NSNumber numberWithLongLong:[seriesSqlProperties[0] longLongValue]],@"key",
seriesSqlProperties[2], @"seriesDescription",
seriesSqlProperties[3], @"seriesNumber",
seriesSqlProperties[1], @"SeriesInstanceUID",
SOPClass, @"SOPClassUID",
seriesSqlProperties[4], @"Modality",
@"*",@"WadoTransferSyntaxUID",
seriesSqlProperties[6], @"Department",
seriesSqlProperties[7], @"StationName",
seriesSqlProperties[8], @"PerformingPhysician",
seriesSqlProperties[9], @"Laterality",
[NSNumber numberWithLongLong:[seriesSqlProperties[10] longLongValue]], @"numImages",
instanceArray,@"instanceList",
nil
];

                                 //add institution to studies
[study setObject:seriesSqlProperties[5] forKey:@"institution"];
                                 
                              
                              
                                    [mutableData setData:[NSData data]];
                                    if (execUTF8Bash(sqlcredentials,
                                                   [NSString stringWithFormat:
                                                      sqlDictionary[@"I"],
                                                      sqlprolog,
                                                      seriesSqlProperties[0],
                                                      @"",
                                                      sqlRecordFourUnits
                                                      ],
                                                   mutableData)
                                        !=0)
                                    {
                                       LOG_ERROR(@"studyToken study db error");
                                       continue;
                                    }
                                    NSArray *instanceSqlPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding

                                                                  
  #pragma mark ...instance loop
                                    for (NSArray *instanceSqlProperties in instanceSqlPropertiesArray)
                                    {
                                       //imageId = (weasis) DirectDownloadFile

                                       NSString *wadouriInstance=[NSString stringWithFormat:
                                                               @"%@?requestType=WADO&studyUID=%@&seriesUID=%@&objectUID=%@&session=%@&custodianOID=%@&arcId=%@%@",
                                                               proxyURIString,
                                                               (studySqlPropertiesArray[0])[1],
                                                               seriesSqlProperties[1],
                                                               instanceSqlProperties[1],
                                                               sessionString,
                                                               devDict[@"custodianoid"],
                                                               devOID,
                                                               devDict[@"wadocornerstoneparameters"]
                                                                  ];
                                       [instanceArray addObject:@{
                                                               @"imageId":wadouriInstance,
                                                               @"SOPInstanceUID":instanceSqlProperties[1],
                                                               @"InstanceNumber":instanceSqlProperties[2],
                                                               @"numFrames":@1
                                                               }
                                       ];

                                       }//end for each I
                                   } //end if SOPClass
                                 }//end series no existe en cache

                              }// end for each S
                           }//end for each E
                        }//end for each P
                     } break;//end of WADO
                  }// end of GET switch
               } break;//end of sql
            } //end of SELECT switch
         }
         NSData *cornerstoneJson=[NSJSONSerialization dataWithJSONObject:JSONArray options:0 error:nil];
            
         if (DRS.tokentmpDir.length)
         [cornerstoneJson writeToFile:
           [
            [DRS.tokentmpDir stringByAppendingPathComponent:sessionString]
            stringByAppendingPathExtension:@"json"]
          atomically:NO];

         return [RSDataResponse responseWithData:cornerstoneJson contentType:@"application/json"];
      }//end while 1
   }//end at least one dev

   return [RSErrorResponse responseWithClientError:404 message:@"studyToken should not be here"];
}


RSResponse* dicomzip(
 NSMutableArray * JSONArray,
 NSString            * canonicalQuerySHA512String,
 NSString            * proxyURIString,
 NSString            * sessionString,
 NSString            * tokenString,
 NSMutableArray      * lanArray,
 NSMutableArray      * wanArray,
 NSString            * StudyInstanceUIDRegexpString,
 NSString            * AccessionNumberSqlEqualString,
 NSString            * refInstitutionSqlLikeString,
 NSString            * refServiceSqlLikeString,
 NSString            * refUserSqlLikeString,
 NSString            * refIDSqlLikeString,
 NSString            * refIDTypeSqlLikeString,
 NSString            * readInstitutionSqlLikeString,
 NSString            * readServiceSqlLikeString,
 NSString            * readUserSqlLikeString,
 NSString            * readIDSqlLikeString,
 NSString            * readIDTypeSqlLikeString,
 NSString            * StudyIDSqlLikeString,
 NSString            * PatientIDSqlLikeString,
 NSString            * patientFamilySqlLikeEscapedString,
 NSString            * patientGivenSqlLikeEscapedString,
 NSString            * patientMiddleSqlLikeEscapedString,
 NSString            * patientPrefixSqlLikeEscapedString,
 NSString            * patientSuffixSqlLikeEscapedString,
 NSArray             * issuerArray,
 NSArray             * StudyDateArray,
 NSString            * SOPClassInStudySqlEqualString,
 NSString            * ModalityInStudySqlEqualString,
 NSString            * StudyDescriptionRegexpString,
 BOOL                  hasRestriction,
 NSRegularExpression * SeriesInstanceUIDRegex,
 NSRegularExpression * SeriesNumberRegex,
 NSRegularExpression * SeriesDescriptionRegex,
 NSRegularExpression * ModalityRegex,
 NSRegularExpression * SOPClassRegex,
 NSRegularExpression * SOPClassOffRegex,
 NSInteger             accessType
)
{
   //information model for getting and pulling the information, either from source or from cache
   __block NSMutableArray *filenames=[NSMutableArray array];
   __block NSMutableArray *wados=    [NSMutableArray array];
   __block NSMutableArray *crc32s=   [NSMutableArray array];
   __block NSMutableArray *lengths=  [NSMutableArray array];

   //cache made of a session.json manifest file and a corresponding session/ directory
   __block NSFileManager *fileManager=[NSFileManager defaultManager];
   __block NSString *DIR=
     [DRS.tokentmpDir
      stringByAppendingPathComponent:tokenString
      ];
    NSError *error=nil;
    if (![fileManager fileExistsAtPath:DIR])
    {
       if (![fileManager
             createDirectoryAtPath:DIR
             withIntermediateDirectories:YES
             attributes:nil
             error:&error]
           ) return [RSErrorResponse responseWithClientError:404 message:@"studyToken no access to token cache: %@",[error description]];
    }

    __block BOOL fromCache=false;
/*
    __block NSString *JSON=[DIR stringByAppendingPathExtension:@"json"];
    if ([fileManager fileExistsAtPath:JSON])
    {
        jsonArray=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:JSON] options:NSJSONReadingMutableContainers error:&error];
        if (! jsonArray) LOG_WARNING(@"studyToken dicomzip json unreadable at %@. %@",JSON, [error description]);
        else
        {
            if (jsonArray.count!=4) LOG_WARNING(@"studyToken dicomzip json bad");
            else
            {
                NSArray *jsonFilenames=jsonArray[0];
                if (!jsonFilenames || !jsonFilenames.count) LOG_WARNING(@"studyToken dicomzip json no filenames");
                else
                {
                    [filenames addObjectsFromArray:jsonFilenames];
                    NSArray *jsonWados=jsonArray[1];
                    if (!jsonWados || (jsonFilenames.count!=jsonWados.count)) LOG_WARNING(@"studyToken dicomzip json no inconsistent wados");
                    else
                    {
                        [wados addObjectsFromArray:jsonWados];
                        NSArray *jsonCrc32s=jsonArray[2];
                        if (!jsonCrc32s || (jsonFilenames.count!=jsonCrc32s.count)) LOG_WARNING(@"studyToken dicomzip json no inconsistent crc32s");
                        else
                        {
                            [crc32s addObjectsFromArray:jsonCrc32s];
                            NSArray *jsonLengths=jsonArray[3];
                            if (!jsonLengths || (jsonFilenames.count!=jsonLengths.count)) LOG_WARNING(@"studyToken dicomzip json no inconsistent lengths");
                            else
                            {
                                [lengths addObjectsFromArray:jsonLengths];
                                fromCache=true;
                            }
                        }
                    }
                }
            }
            
        }
        
        if (!fromCache) [fileManager moveItemAtPath:JSON toPath:[JSON stringByAppendingPathExtension:@"bad"] error:nil];
    }
*/
    
    if (!fromCache)
    {
       if (lanArray.count > 1)
       {
          //add nodes and start corresponding processes
       }

       if (wanArray.count > 0)
       {
          //add nodes and start corresponding processes
       }

       if (lanArray.count == 0)
       {
          //add nodes and start corresponding processes
       }
       else
       {
          while (1)
          {
             NSString *devOID=lanArray[0];
             NSDictionary *devDict=DRS.pacs[devOID];

#pragma mark · GET type index
             NSUInteger getTypeIndex=[@[@"file",@"folder",@"wado",@"wadors",@"cget",@"cmove"] indexOfObject:devDict[@"get"]];

#pragma mark · SELECT switch
             switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:devDict[@"select"]]) {
                
                case NSNotFound:{
                   LOG_WARNING(@"studyToken pacs %@ lacks \"select\" type property",devOID);
                } break;
                   
                case selectTypeSql:{
#pragma mark · SQL SELECT (unique option for now)
                   NSDictionary *sqlcredentials=@{devDict[@"sqlcredentials"]:devDict[@"sqlpassword"]};
                   NSString *sqlprolog=devDict[@"sqlprolog"];
                   NSDictionary *sqlDictionary=DRS.sqls[devDict[@"sqlmap"]];

                   

#pragma mark · apply EuiE (Study Patient) filters
                   NSMutableDictionary *EuiEDict=[NSMutableDictionary dictionary];
                   RSResponse *sqlEuiEErrorReturned=sqlEP(
                    EuiEDict,
                    sqlcredentials,
                    sqlDictionary,
                    sqlprolog,
                    true,
                    StudyInstanceUIDRegexpString,
                    AccessionNumberSqlEqualString,
                    refInstitutionSqlLikeString,
                    refServiceSqlLikeString,
                    refUserSqlLikeString,
                    refIDSqlLikeString,
                    refIDTypeSqlLikeString,
                    readInstitutionSqlLikeString,
                    readServiceSqlLikeString,
                    readUserSqlLikeString,
                    readIDSqlLikeString,
                    readIDTypeSqlLikeString,
                    StudyIDSqlLikeString,
                    PatientIDSqlLikeString,
                    patientFamilySqlLikeEscapedString,
                    patientGivenSqlLikeEscapedString,
                    patientMiddleSqlLikeEscapedString,
                    patientPrefixSqlLikeEscapedString,
                    patientSuffixSqlLikeEscapedString,
                    issuerArray,
                    StudyDateArray,
                    SOPClassInStudySqlEqualString,
                    ModalityInStudySqlEqualString,
                    StudyDescriptionRegexpString
                   );
                   if (sqlEuiEErrorReturned) return sqlEuiEErrorReturned;
                 

#pragma mark ·· GET switch
                   switch (getTypeIndex) {
                         
                      case NSNotFound:{
                         LOG_WARNING(@"studyToken pacs %@ lacks \"get\" property",devOID);
                      } break;

                      case getTypeWado:{
#pragma mark ·· WADO (unique option for now)
                         
                         NSMutableData *mutableData=[NSMutableData data];
                         for (NSString *Eui in EuiEDict)
                         {
//#pragma mark study loop
                            [mutableData setData:[NSData data]];
                            if (execUTF8Bash(sqlcredentials,
                                           [NSString stringWithFormat:
                                            sqlDictionary[@"S"],
                                            sqlprolog,
                                            EuiEDict[Eui],
                                            @"",
                                            sqlRecordFiveUnits
                                            ],
                                           mutableData)
                                !=0)
                            {
                               LOG_ERROR(@"studyToken study db error");
                               continue;
                            }
                            NSArray *SPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:3 decreasing:NO];//NSUTF8StringEncoding
                            for (NSArray *SProperties in SPropertiesArray)
                            {
//#pragma mark series loop
                               NSString *SOPClass=SOPCLassOfReturnableSeries(
                                sqlcredentials,
                                sqlDictionary[@"Ici4S"],
                                sqlprolog,
                                SProperties,
                                SeriesInstanceUIDRegex,
                                SeriesNumberRegex,
                                SeriesDescriptionRegex,
                                ModalityRegex,
                                SOPClassRegex,
                                SOPClassOffRegex
                               );
                               if (SOPClass)
                               {
                                  //instances
                                  [mutableData setData:[NSData data]];
                                  if (execUTF8Bash(sqlcredentials,
                                                 [NSString stringWithFormat:
                                                  sqlDictionary[@"Iui4S"],
                                                  sqlprolog,
                                                  SProperties[0],
                                                  @"",
                                                  sqlsingleslash
                                                  ],
                                                 mutableData)
                                   !=0)
                                  {
                                     LOG_ERROR(@"studyToken study db error");
                                     continue;
                                  }
                                  NSString *sopuids=[[NSString alloc]initWithData:mutableData encoding:NSUTF8StringEncoding];
                                  for (NSString *sopuid in sopuids.pathComponents)
                                  {
                                     //remove the / empty component at the end
                                     if (sopuid.length > 1)
                                     {
                                        [wados addObject:[NSString stringWithFormat:@"%@?requestType=WADO&studyUID=%@&seriesUID=%@&objectUID=%@&contentType=application/dicom%@",devDict[@"wadouri"],Eui,SProperties[1],sopuid,devDict[@"wadodicomdicparameters"]]];
                                     }
                                  }// end for each I
                               }//end if SOPClass
                            }//end for each S
                         } break;//end of E and WADO
                      }// end of GET switch
                   } break;//end of sql
                } //end of SELECT switch
             }
             break;
          }//end while 1

       }//end at least one dev
    }

#pragma mark stream zipped response
    
   __block NSMutableData *CENTRAL=[NSMutableData data];
   __block BOOL needsEpilog=(accessType!=accessTypeWadoRSDicom);
   __block BOOL needsProlog=(accessType==accessTypeWadoRSDicom);
#pragma mark TODO Time and Date
   __block uint16 zipTime=0x7534;
   __block uint16 zipDate=0x4F3B;
   __block uint32 LOCALPointer=0;
   __block uint16 LOCALIndex=0;
   
   // The RSAsyncStreamBlock works like the RSStreamBlock
   // The block must call "completionBlock" passing the new chunk of data when ready, an empty NSData when done, or nil on error and pass a NSError.
   // The block cannot call "completionBlock" more than once per invocation.
   
   
   
   
#pragma mark - handler
   return [RSStreamedResponse responseWithContentType:@"application/octet-stream" asyncStreamBlock:^(RSBodyReaderCompletionBlock completionBlock)
   {
      /*
       5 steps:
       - prolog
       - entry data (LOCAL) for each entry
       - entry directory (if CENTRAL data exists)
       - epilog
       - end of stream
       
       wadors has prolog and data
       zip has data, directory, and epilog
       ... pdf...
       */
#pragma mark 1. PROLOG
      if (needsProlog)
      {
         needsProlog=false;
      }
#pragma mark 2. DATA
      else if (LOCALIndex < wados.count)
      {
#pragma mark prepare crc32, compressed, uncompressed, entryData
        NSData *entryData=nil;
        NSString *entryPath=nil;
        uint32 zipCRC32=0x00000000;
        uint16 zipCompression=zipCompression0;
        uint32 zipCompressedSize=0x00000000;
        uint32 zipUncompressedSize=0x00000000;

        if (fromCache) entryPath=[DIR stringByAppendingPathComponent:filenames[LOCALIndex]];
        //if exists, get it from caché, else perform qido
        if (fromCache && [fileManager fileExistsAtPath:entryPath])
        {
            entryData=[NSData dataWithContentsOfFile:entryPath];
            zipCompressedSize=(uint32)entryData.length;
            zipCRC32=(uint32)[[[[entryPath stringByDeletingPathExtension]stringByDeletingPathExtension]pathExtension]intValue];
            zipUncompressedSize=(uint32)[[[entryPath stringByDeletingPathExtension]pathExtension]intValue];
        }
        else if (wados[LOCALIndex])
        {
           NSData *uncompressedData=[NSData dataWithContentsOfURL:[NSURL URLWithString:wados[LOCALIndex]]];
           zipCRC32=[uncompressedData crc32];
           [crc32s addObject:[NSNumber numberWithUnsignedInteger:zipCRC32]];
           zipUncompressedSize=(uint32)uncompressedData.length;
           [lengths addObject:[NSNumber numberWithUnsignedInteger:zipUncompressedSize]];
           [filenames addObject:
            [NSString stringWithFormat:
             @"%010u.%010u.%010u.dcm",
             LOCALIndex,
             zipCRC32,
             zipUncompressedSize
             ]
            ];
           switch (accessType) {
              case accessTypeIsoDicomZip:
              case accessTypeWadoRSDicom:
                 entryData=uncompressedData;
                 break;
                 
              case accessTypeDicomzip:
              case accessTypeDeflateIsoDicomZip:
                 entryData=[uncompressedData rawzip];
                 break;
                 
              case accessTypeMaxDeflateIsoDicomZip:
                 entryData=[uncompressedData maxrawzip];
                 break;
           }
           zipCompressedSize=(uint32)entryData.length;
           if (entryData)[entryData writeToFile:[DIR stringByAppendingPathComponent: filenames[LOCALIndex]] atomically:NO];
        }

        
        if (!entryData)
        {
           NSLog(@"could not retrive: %@",wados[LOCALIndex]);
           completionBlock([NSData data], nil);
        }
        else
        {
           
#pragma mark streamings

           switch (accessType) {
              case accessTypeDicomzip:
              case accessTypeIsoDicomZip:
              case accessTypeDeflateIsoDicomZip:
              case accessTypeMaxDeflateIsoDicomZip:
              {
                 if (zipCompressedSize != zipUncompressedSize) zipCompression=zipCompression8;
                 NSData *nameData=[filenames[LOCALIndex] dataUsingEncoding:NSASCIIStringEncoding];
                 NSMutableData *LOCAL=[NSMutableData data];

                 [LOCAL appendBytes:&zipLOCAL length:4];
                 [LOCAL appendBytes:&zipVersion length:2];
                 [LOCAL appendBytes:&zipBitFlagsNone length:2];
                 [LOCAL appendBytes:&zipCompression length:2];
                 [LOCAL appendBytes:&zipTime length:2];
                 [LOCAL appendBytes:&zipDate length:2];
                 [LOCAL appendBytes:&zipCRC32 length:4];
                 [LOCAL appendBytes:&zipUncompressedSize length:4];
                 [LOCAL appendBytes:&zipCompressedSize length:4];
                 [LOCAL appendBytes:&zipNameLength length:2];
                 [LOCAL appendBytes:&zipExtraLength length:2];
                 [LOCAL appendData:nameData];
                 //noExtra
                 [LOCAL appendData:entryData];
                 completionBlock(LOCAL, nil);

                 //CENTRAL 46
                 [CENTRAL appendBytes:&zipCENTRAL length:4];
                 [CENTRAL appendBytes:&zipMadeBy length:2];//made by
                 [CENTRAL appendBytes:&zipVersion length:2];//needed
                 [CENTRAL appendBytes:&zipBitFlagsNone length:2];
                 [CENTRAL appendBytes:&zipCompression length:2];
                 [CENTRAL appendBytes:&zipTime length:2];
                 [CENTRAL appendBytes:&zipDate length:2];
                 [CENTRAL appendBytes:&zipCRC32 length:4];
                 [CENTRAL appendBytes:&zipCompressedSize length:4];
                 [CENTRAL appendBytes:&zipUncompressedSize length:4];
                 [CENTRAL appendBytes:&zipNameLength length:2];
                 [CENTRAL appendBytes:&zipExtraLength length:2];
                 [CENTRAL appendBytes:&zipExtraLength length:2];//comment
                 [CENTRAL appendBytes:&zipExtraLength length:2];//disk number start
                 [CENTRAL appendBytes:&zipExtraLength length:2];//internal file attribute
                 [CENTRAL appendBytes:&zipExternalFileAttributes length:4];
                 [CENTRAL appendBytes:&LOCALPointer length:4];//offsetOfLocalHeader
                 [CENTRAL appendData:nameData];
                 //noExtra
                 //noComment

                 LOCALPointer+=entryData.length+66;//30 entry + 36 name
              } break;
                 
              case accessTypeWadoRSDicom:
#pragma mark TODO WADORSDICOM for each file
                 completionBlock([NSData data], nil);
                 break;

              case accessTypeZip64IsoDicomZip:
#pragma mark TODO zip64 for each file
              {
                 NSData *nameData=[filenames[LOCALIndex] dataUsingEncoding:NSASCIIStringEncoding];
                 NSMutableData *LOCAL=[NSMutableData data];
                 [LOCAL appendBytes:&zipLOCAL length:4];
                 [LOCAL appendBytes:&zipVersion length:2];
                 [LOCAL appendBytes:&zipBitFlagsDescriptor length:2];
                 [LOCAL appendBytes:&zipCompression length:2];
                 [LOCAL appendBytes:&zipTime length:2];
                 [LOCAL appendBytes:&zipDate length:2];
                 [LOCAL increaseLengthBy:12];
                 [LOCAL appendBytes:&zipNameLength length:2];
                 [LOCAL appendBytes:&zipExtraLength length:2];
                 [LOCAL appendData:nameData];
                 //noExtra
                 [LOCAL appendData:entryData];
                 
                 [LOCAL appendBytes:&zipDESCRIPTOR length:4];
                 [LOCAL appendBytes:&zipCRC32 length:4];
                 [LOCAL appendBytes:&zipCompressedSize length:4];
                 [LOCAL appendBytes:&zipUncompressedSize length:4];

                 
                 completionBlock(LOCAL, nil);

                 //CENTRAL 46
                 [CENTRAL appendBytes:&zipCENTRAL length:4];
                 [CENTRAL appendBytes:&zipMadeBy length:2];//made by
                 [CENTRAL appendBytes:&zipVersion length:2];//needed
                 [CENTRAL appendBytes:&zipBitFlagsDescriptor length:2];
                 [CENTRAL appendBytes:&zipCompression length:2];
                 [CENTRAL appendBytes:&zipTime length:2];
                 [CENTRAL appendBytes:&zipDate length:2];
                 [CENTRAL appendBytes:&zipCRC32 length:4];
                 [CENTRAL appendBytes:&zipCompressedSize length:4];
                 [CENTRAL appendBytes:&zipUncompressedSize length:4];
                 [CENTRAL appendBytes:&zipNameLength length:2];
                 [CENTRAL appendBytes:&zipExtraLength length:2];
                 [CENTRAL appendBytes:&zipExtraLength length:2];//comment
                 [CENTRAL appendBytes:&zipExtraLength length:2];//disk number start
                 [CENTRAL appendBytes:&zipExtraLength length:2];//internal file attribute
                 [CENTRAL appendBytes:&zipExternalFileAttributes length:4];
                 [CENTRAL appendBytes:&LOCALPointer length:4];//offsetOfLocalHeader
                 [CENTRAL appendData:nameData];
                 //noExtra
                 //noComment

                 LOCALPointer+=entryData.length+66+16;//30 entry + 36 name + 16 descriptor
                 } break;

            }
         }
         LOCALIndex++;
      }
#pragma mark 3. DIRECTORY
      else if (CENTRAL.length) //chunk with directory
      {
        completionBlock(CENTRAL, nil);
        [CENTRAL setData:[NSData data]];
      }
#pragma mark 4. EPILOG
      else if (needsEpilog)
      {
         [CENTRAL appendBytes:&zipEND length:4];
         [CENTRAL appendBytes:&zipDiskNumber length:2];
         [CENTRAL appendBytes:&zipDiskCentralStarts length:2];
         [CENTRAL appendBytes:&LOCALIndex length:2];//disk zipEntries
         [CENTRAL appendBytes:&LOCALIndex length:2];//total zipEntries
         uint32 CENTRALSize=82 * LOCALIndex;
         [CENTRAL appendBytes:&CENTRALSize length:4];
         [CENTRAL appendBytes:&LOCALPointer length:4];
         [CENTRAL appendBytes:&zipExtraLength length:2];//comment
         
         completionBlock(CENTRAL, nil);
         [CENTRAL setData:[NSData data]];
         needsEpilog=false;
     }
#pragma mark 5. END OF STREAM
      else
      {
        completionBlock(CENTRAL, nil);//empty last chunck
        
/*        //write JSON
        NSError *error;
        if (![[NSString
               stringWithFormat:@"[[\"%@\"],[\"%@\"],[%@],[%@]]",
               [filenames componentsJoinedByString:@"\",\""],
               [wados componentsJoinedByString:@"\",\""],
               [crc32s componentsJoinedByString:@","],
               [lengths componentsJoinedByString:@","]
               ]
              writeToFile:JSON
              atomically:NO
              encoding:NSUTF8StringEncoding
              error:&error
            ])
           LOG_WARNING(@"studyToken could not save dicomzip json");
 */
     }
   }];
}


RSResponse* osirixdcmURLs(
 NSMutableArray * JSONArray,
 NSString            * canonicalQuerySHA512String,
 NSString            * proxyURIString,
 NSString            * sessionString,
 NSString            * tokenString,
 NSMutableArray      * lanArray,
 NSMutableArray      * wanArray,
 NSString            * StudyInstanceUIDRegexpString,
 NSString            * AccessionNumberSqlEqualString,
 NSString            * refInstitutionSqlLikeString,
 NSString            * refServiceSqlLikeString,
 NSString            * refUserSqlLikeString,
 NSString            * refIDSqlLikeString,
 NSString            * refIDTypeSqlLikeString,
 NSString            * StudyIDSqlLikeString,
 NSString            * PatientIDSqlLikeString,
 NSString            * patientFamilySqlLikeEscapedString,
 NSString            * patientGivenSqlLikeEscapedString,
 NSString            * patientMiddleSqlLikeEscapedString,
 NSString            * patientPrefixSqlLikeEscapedString,
 NSString            * patientSuffixSqlLikeEscapedString,
 NSArray             * issuerArray,
 NSArray             * StudyDateArray,
 NSString            * SOPClassInStudySqlEqualString,
 NSString            * ModalityInStudySqlEqualString,
 NSString            * StudyDescriptionRegexpString,
 BOOL                  hasRestriction,
 NSRegularExpression * SeriesInstanceUIDRegex,
 NSRegularExpression * SeriesNumberRegex,
 NSRegularExpression * SeriesDescriptionRegex,
 NSRegularExpression * ModalityRegex,
 NSRegularExpression * SOPClassRegex,
 NSRegularExpression * SOPClassOffRegex,
 NSInteger             accessType
)
{
    return [RSErrorResponse responseWithClientError:404 message:@"osirix to be programmed yet"];
}


#pragma mark -
@implementation DRS (studyToken)




-(void)addPostAndGetStudyTokenHandler
{
   [self
    addHandler:@"POST"
    regex:[NSRegularExpression regularExpressionWithPattern:@"^/(studyToken|osirix.dcmURLs|weasis.xml|dicom.zip|iso.dicom.zip|deflate.dicom.zip|deflate.iso.dicom.zip|max.deflate.iso.dicom.zip|zip64.iso.dicom.zip|wadors.dicom|datatablesseries.json|datatablespatient.json|cornerstone.json)$" options:0 error:NULL]
    processBlock:^(RSRequest* request,RSCompletionBlock completionBlock)
    {
       completionBlock(^RSResponse* (RSRequest* request) {return [DRS studyToken:request];}(request));
    }
   ];

   [self
    addHandler:@"GET"
    regex:[NSRegularExpression regularExpressionWithPattern:@"^/(studyToken|osirix.dcmURLs|weasis.xml|dicom.zip|iso.dicom.zip|deflate.dicom.zip|deflate.iso.dicom.zip|max.deflate.iso.dicom.zip|zip64.iso.dicom.zip|wadors.dicom|datatablesseries.json|datatablespatient.json|cornerstone.json)$" options:0 error:NULL]
    processBlock:^(RSRequest* request,RSCompletionBlock completionBlock)
    {
       completionBlock(^RSResponse* (RSRequest* request) {return [DRS studyToken:request];}(request));
    }
   ];
}


+(RSResponse*)studyToken:(RSRequest*)request
{
#pragma mark parsing request
   
   LOG_INFO(@"socket number: %i",request.socketNumber);
   //read json
   NSMutableArray *names=[NSMutableArray array];
   NSMutableArray *values=[NSMutableArray array];
   NSString *errorString=parseRequestParams(request, names, values);
   if (errorString) return [RSErrorResponse responseWithClientError:404 message:@"%@",errorString];
   
   NSMutableArray *JSONArray=nil;
   NSFileManager *defaultManager=[NSFileManager defaultManager];
   NSError *error=nil;
   
#pragma mark · 1. query context
   
   //1.1 proxyURI
   NSString *proxyURIString=nil;
   NSInteger proxyURIIndex=[names indexOfObject:@"proxyURI"];
   if (proxyURIIndex!=NSNotFound) proxyURIString=values[proxyURIIndex];
   else proxyURIString=@"whatIsTheURLToBeInvoked?";
   
   //1.2 session
   NSString *sessionString=nil;
   NSInteger sessionIndex=[names indexOfObject:@"session"];
   if (sessionIndex!=NSNotFound) sessionString=values[sessionIndex];
   else sessionString=@"";
   
   //1.3 token
   NSString *tokenString=nil;
   NSInteger tokenIndex=[names indexOfObject:@"token"];
   if (tokenIndex!=NSNotFound) tokenString=values[tokenIndex];
   else tokenString=@"";


#pragma mark · 2. institution

   NSMutableString *canonicalQuery=[NSMutableString stringWithString:@""];
   
   
   //2.1
   NSMutableArray *lanArray=[NSMutableArray array];
   NSMutableArray *wanArray=[NSMutableArray array];
   
   NSInteger orgIndex=[names indexOfObject:@"institution"];
   if (orgIndex==NSNotFound)
   {
      orgIndex=[names indexOfObject:@"lanPacs"];
      if (orgIndex!=NSNotFound) [lanArray addObjectsFromArray:[values[orgIndex] componentsSeparatedByString:@"|"]];
      orgIndex=[names indexOfObject:@"wanPacs"];
      if (orgIndex!=NSNotFound) [wanArray addObjectsFromArray:[values[orgIndex] componentsSeparatedByString:@"|"]];
   }
   else
   {
      NSArray *orgArray=[values[orgIndex] componentsSeparatedByString:@"|"];
      for (NSInteger i=[orgArray count]-1;i>=0;i--)
      {
         if ([DRS.wan indexOfObject:orgArray[i]]!=NSNotFound)
         {
            [wanArray addObject:orgArray[i]];
            LOG_DEBUG(@"studyToken institution wan %@",orgArray[i]);
         }
         else if ([DRS.dev indexOfObject:orgArray[i]]!=NSNotFound)
         {
            [lanArray addObject:orgArray[i]];
            LOG_DEBUG(@"studyToken institution lan %@",orgArray[i]);
         }
         else if ([DRS.lan indexOfObject:orgArray[i]]!=NSNotFound)
         {
            //find all dev of local custodian
            if (DRS.oidsaeis[orgArray[i]])
            {
               [lanArray addObjectsFromArray:DRS.oidsaeis[orgArray[i]]];
               LOG_VERBOSE(@"studyToken institution for lan %@:\r\n%@",orgArray[i],[DRS.oidsaeis[orgArray[i]]description]);
            }
            else
            {
               [lanArray addObjectsFromArray:DRS.titlestitlesaets[orgArray[i]]];
               LOG_VERBOSE(@"studyToken institution for lan %@:\r\n%@",orgArray[i],[DRS.titlestitlesaets[orgArray[i]]description]);
            }
         }
         else
         {
            LOG_WARNING(@"studyToken institution '%@' not registered",orgArray[i]);
         }
      }
   }
   if (![lanArray count] && ![wanArray count]) return [RSErrorResponse responseWithClientError:404 message:@"no valid pacs in the request"];

   if ([lanArray count]) [canonicalQuery appendFormat:@"\"lanPacs\":\"%@\",",[[lanArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]componentsJoinedByString:@"|"]];

   if ([wanArray count]) [canonicalQuery appendFormat:@"\"wanPacs\":\"%@\",",[[lanArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]componentsJoinedByString:@"|"]];

#pragma mark · 3. study filters
   
//3.1 StudyInstanceUID (UIPipeList)
    NSString *StudyInstanceUIDRegexpString=nil;
    NSInteger StudyInstanceUIDIndex=[names indexOfObject:@"StudyInstanceUID"];
    if (StudyInstanceUIDIndex!=NSNotFound)
    {
       if ([values[StudyInstanceUIDIndex] length])
       {
          if ([DICMTypes isUIPipeListString:values[StudyInstanceUIDIndex]])
          {
             StudyInstanceUIDRegexpString=[values[StudyInstanceUIDIndex] regexQuoteEscapedString];
             [canonicalQuery appendFormat:@"\"StudyInstanceUID\":\"%@\",",StudyInstanceUIDRegexpString];
          }
          else return [RSErrorResponse responseWithClientError:404 message:@"studyToken param StudyInstanceUID: %@",values[StudyInstanceUIDIndex]];
       }
    }


//3.2 AccessionNumber sqlEqualEscapedString
    NSString *AccessionNumberSqlEqualString=nil;
    NSInteger AccessionNumberIndex=[names indexOfObject:@"AccessionNumber"];
    if (AccessionNumberIndex!=NSNotFound)
    {
       AccessionNumberSqlEqualString=[values[AccessionNumberIndex] sqlEqualEscapedString];
       [canonicalQuery appendFormat:@"\"AccessionNumber\":\"%@\",",AccessionNumberSqlEqualString];
    }
                 
//3.10 refInstitution
    NSString *refInstitutionSqlLikeString=nil;
    NSInteger refInstitutionIndex=[names indexOfObject:@"refInstitution"];
    if (refInstitutionIndex!=NSNotFound)
    {
       refInstitutionSqlLikeString=[values[refInstitutionIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"refInstitution\":\"%@\",",refInstitutionSqlLikeString];
    }
//3.10 refService
    NSString *refServiceSqlLikeString=nil;
    NSInteger refServiceIndex=[names indexOfObject:@"refService"];
    if (refServiceIndex!=NSNotFound)
    {
       refServiceSqlLikeString=[values[refServiceIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"refService\":\"%@\",",refServiceSqlLikeString];
    }
//3.10 refUser
    NSString *refUserSqlLikeString=nil;
    NSInteger refUserIndex=[names indexOfObject:@"refUser"];
    if (refUserIndex!=NSNotFound)
    {
       refUserSqlLikeString=[values[refUserIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"refUser\":\"%@\",",refUserSqlLikeString];
    }
//3.10 refID
    NSString *refIDSqlLikeString=nil;
    NSInteger refIDIndex=[names indexOfObject:@"refID"];
    if (refIDIndex!=NSNotFound)
    {
       refIDSqlLikeString=[values[refIDIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"refID\":\"%@\",",refIDSqlLikeString];
    }
//3.10 refIDType
    NSString *refIDTypeSqlLikeString=nil;
    NSInteger refIDTypeIndex=[names indexOfObject:@"refIDType"];
    if (refIDTypeIndex!=NSNotFound)
    {
       refIDTypeSqlLikeString=[values[refIDTypeIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"refIDType\":\"%@\",",refIDTypeSqlLikeString];
    }

//3.11 readInstitution
    NSString *readInstitutionSqlLikeString=nil;
    NSInteger readInstitutionIndex=[names indexOfObject:@"readInstitution"];
    if (readInstitutionIndex!=NSNotFound)
    {
       readInstitutionSqlLikeString=[values[readInstitutionIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"readInstitution\":\"%@\",",readInstitutionSqlLikeString];
    }
//3.11 readService
    NSString *readServiceSqlLikeString=nil;
    NSInteger readServiceIndex=[names indexOfObject:@"readService"];
    if (readServiceIndex!=NSNotFound)
    {
       readServiceSqlLikeString=[values[readServiceIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"readService\":\"%@\",",readServiceSqlLikeString];
    }
//3.11 readUser
    NSString *readUserSqlLikeString=nil;
    NSInteger readUserIndex=[names indexOfObject:@"readUser"];
    if (readUserIndex!=NSNotFound)
    {
       readUserSqlLikeString=[values[readUserIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"readUser\":\"%@\",",readUserSqlLikeString];
    }
//3.11 readID
    NSString *readIDSqlLikeString=nil;
    NSInteger readIDIndex=[names indexOfObject:@"readID"];
    if (readIDIndex!=NSNotFound)
    {
       readIDSqlLikeString=[values[readIDIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"readID\":\"%@\",",readIDSqlLikeString];
    }
//3.11 readIDType
    NSString *readIDTypeSqlLikeString=nil;
    NSInteger readIDTypeIndex=[names indexOfObject:@"readIDType"];
    if (readIDTypeIndex!=NSNotFound)
    {
       readIDTypeSqlLikeString=[values[readIDTypeIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"readIDType\":\"%@\",",readIDTypeSqlLikeString];
    }

   
//3.19 StudyID sqlLikeEscapedString
     NSString *StudyIDSqlLikeString=nil;
     NSInteger StudyIDIndex=[names indexOfObject:@"StudyID"];
     if (StudyIDIndex!=NSNotFound)
     {
        StudyIDSqlLikeString=[values[StudyIDIndex] sqlLikeEscapedString];
        [canonicalQuery appendFormat:@"\"StudyID\":\"%@\",",StudyIDSqlLikeString];
     }

//3.29 PatientID sqlLikeEscapedString
    NSString *PatientIDSqlLikeString=nil;
    NSInteger PatientIDIndex=[names indexOfObject:@"PatientID"];
    if (PatientIDIndex!=NSNotFound)
    {
       PatientIDSqlLikeString=[values[PatientIDIndex] sqlLikeEscapedString];
       [canonicalQuery appendFormat:@"\"PatientID\":\"%@\",",PatientIDSqlLikeString];
    }

//3.21 patientFamily
   NSString *patientFamilySqlLikeEscapedString=nil;
   NSInteger patientFamilyIndex=[names indexOfObject:@"patientFamily"];
   if (patientFamilyIndex!=NSNotFound)
   {
      patientFamilySqlLikeEscapedString=[values[patientFamilyIndex] regexQuoteEscapedString];
      [canonicalQuery appendFormat:@"\"patientFamily\":\"%@\",",patientFamilySqlLikeEscapedString];
   }
//3.21 patientGiven
   NSString *patientGivenSqlLikeEscapedString=nil;
   NSInteger patientGivenIndex=[names indexOfObject:@"patientGiven"];
   if (patientGivenIndex!=NSNotFound)
   {
      patientGivenSqlLikeEscapedString=[values[patientGivenIndex] regexQuoteEscapedString];
      [canonicalQuery appendFormat:@"\"patientGiven\":\"%@\",",patientGivenSqlLikeEscapedString];
   }
//3.22 patientMiddle
   NSString *patientMiddleSqlLikeEscapedString=nil;
   NSInteger patientMiddleIndex=[names indexOfObject:@"patientMiddle"];
   if (patientMiddleIndex!=NSNotFound)
   {
      patientMiddleSqlLikeEscapedString=[values[patientMiddleIndex] regexQuoteEscapedString];
      [canonicalQuery appendFormat:@"\"patientMiddle\":\"%@\",",patientMiddleSqlLikeEscapedString];
   }
//3.23 patientPrefix
   NSString *patientPrefixSqlLikeEscapedString=nil;
   NSInteger patientPrefixIndex=[names indexOfObject:@"patientPrefix"];
   if (patientPrefixIndex!=NSNotFound)
   {
      patientPrefixSqlLikeEscapedString=[values[patientPrefixIndex] regexQuoteEscapedString];
      [canonicalQuery appendFormat:@"\"patientPrefix\":\"%@\",",patientPrefixSqlLikeEscapedString];
   }
//3.24 patientSuffix
   NSString *patientSuffixSqlLikeEscapedString=nil;
   NSInteger patientSuffixIndex=[names indexOfObject:@"patientSuffix"];
   if (patientSuffixIndex!=NSNotFound)
   {
      patientSuffixSqlLikeEscapedString=[values[patientSuffixIndex] regexQuoteEscapedString];
      [canonicalQuery appendFormat:@"\"patientSuffix\":\"%@\",",patientSuffixSqlLikeEscapedString];
   }

//issuer sqlEqualEscapedString
   NSArray *issuerArray=nil;
   NSInteger issuerIndex=[names indexOfObject:@"issuer"];
   if (issuerIndex==NSNotFound) issuerArray=nil;
   else
   {
      [canonicalQuery appendFormat:@"\"issuer\":\"%@\",",[values[issuerIndex] sqlEqualEscapedString]];
      NSArray *array=[[values[issuerIndex] sqlEqualEscapedString] componentsSeparatedByString:@"^"];
      switch (array.count) {
         case 1:
         {
            if ([array[0] length]==0) issuerArray=@[];
            else if ([array[0] length]<17) issuerArray=[NSArray arrayWithArray:array];
            else return [RSErrorResponse responseWithClientError:404 message:@"studyToken bad param issuer: '%@'",values[issuerIndex]];
         } break;
         case 3:
         {
            if ([array[1] length] && ([@[@"DNS",@"EUI64",@"ISO",@"URI",@"UUID",@"X400",@"X500"] indexOfObject:array[2]]!=NSNotFound))
            {
               if (![array[0] length]) issuerArray=[NSArray arrayWithArray:array];
               else if ([array[0] length]<17) issuerArray=[array arrayByAddingObject:array[0]];
               else return [RSErrorResponse responseWithClientError:404 message:@"studyToken bad param issuer: '%@'",values[issuerIndex]];
            }
         } break;
         default:
         {
            return [RSErrorResponse responseWithClientError:404 message:@"studyToken bad param issuer: '%@'",values[issuerIndex]];
         } break;
      }
   }


#pragma mark · 4. addittional study filters
   
//4.12 StudyDate Eda
    NSArray *StudyDateArray=nil;
    NSInteger StudyDateIndex=[names indexOfObject:@"StudyDate"];
    if (StudyDateIndex!=NSNotFound)
    {
       NSString *StudyDateString=values[StudyDateIndex];
       [canonicalQuery appendFormat:@"\"StudyDate\":\"%@\",",StudyDateString];
       if (![StudyDateString length]) StudyDateArray=@[];
       else
       {
          if (![DICMTypes isDA0or1PipeString:StudyDateString]) return [RSErrorResponse responseWithClientError:404 message:@"studyToken bad StudyDate %@",StudyDateString];
          else
          {
             NSArray *StudyDatePipeComponents=[StudyDateString componentsSeparatedByString:@"|"];
             
             if(![StudyDateArray[1] length])
             {
                //aaaa-mm-dd|  =since
                StudyDateArray=@[StudyDatePipeComponents[0],@""];
             }
             else if(![StudyDateArray[0] length])
             {
                //|aaaa-mm-dd  =until
                StudyDateArray=@[@"",@"",StudyDatePipeComponents[1]];
             }
             else
             {
                //aaaa-mm-dd|aaaa-mm-dd
                //[aaaa-mm-dd][][][aaaa-mm-dd] = between
                StudyDateArray=@[StudyDatePipeComponents[0],@"",@"",StudyDatePipeComponents[1]];
             }
          }
        }
    }
    
//4.14 SOPClassInStudyString
   NSString *SOPClassInStudySqlEqualString=nil;
   NSInteger SOPClassInStudyIndex=[names indexOfObject:@"SOPClassInStudy"];
   if (SOPClassInStudyIndex!=NSNotFound)
   {
      if ([DICMTypes isSingleUIString:values[SOPClassInStudyIndex]]) SOPClassInStudySqlEqualString=values[SOPClassInStudyIndex];
      [canonicalQuery appendFormat:@"\"SOPClassInStudy\":\"%@\",",SOPClassInStudySqlEqualString];
   }
       
//4.13 StudyDescription regexQuoteEscapedString
    NSString *StudyDescriptionRegexpString=nil;
    NSInteger StudyDescriptionIndex=[names indexOfObject:@"StudyDescription"];
    if (StudyDescriptionIndex!=NSNotFound)
    {
       StudyDescriptionRegexpString=[values[StudyDescriptionIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"StudyDescription\":\"%@\",",StudyDescriptionRegexpString];
    }

   
//4.15 ModalityInStudyString
   NSString *ModalityInStudySqlEqualString=nil;
   NSInteger ModalityInStudyIndex=[names indexOfObject:@"ModalityInStudy"];
   if (ModalityInStudyIndex!=NSNotFound)
   {
      if ([DICMTypes isSingleCSString:values[ModalityInStudyIndex]]) ModalityInStudySqlEqualString=values[ModalityInStudyIndex];
      [canonicalQuery appendFormat:@"\"ModalityInStudy\":\"%@\",",ModalityInStudySqlEqualString];
   }


#pragma mark · 5. series restrictions

//5.30 SeriesInstanceUID
   NSRegularExpression *SeriesInstanceUIDRegex=nil;
   NSInteger SeriesInstanceUIDIndex=[names indexOfObject:@"SeriesInstanceUID"];
   if (SeriesInstanceUIDIndex!=NSNotFound)
   {
      SeriesInstanceUIDRegex=[NSRegularExpression regularExpressionWithPattern:values[SeriesInstanceUIDIndex] options:0 error:NULL];
      [canonicalQuery appendFormat:@"\"SeriesInstanceUID\":\"%@\",",values[SeriesInstanceUIDIndex]];
   }
   
//5.31 SeriesNumber
   NSRegularExpression *SeriesNumberRegex=nil;
   NSInteger SeriesNumberIndex=[names indexOfObject:@"SeriesNumber"];
   if (SeriesNumberIndex!=NSNotFound)
   {
      SeriesNumberRegex=[NSRegularExpression regularExpressionWithPattern:values[SeriesNumberIndex] options:0 error:NULL];
      [canonicalQuery appendFormat:@"\"SeriesNumber\":\"%@\",",values[SeriesNumberIndex]];
   }

//5.32 SeriesDescription@StationName@Department@Institution
   NSRegularExpression *SeriesDescriptionRegex=nil;
   NSInteger SeriesDescriptionIndex=[names indexOfObject:@"SeriesDescription"];
   if (SeriesDescriptionIndex!=NSNotFound)
   {
      SeriesDescriptionRegex=[NSRegularExpression regularExpressionWithPattern:values[SeriesDescriptionIndex] options:0 error:NULL];
      [canonicalQuery appendFormat:@"\"SeriesDescription\":\"%@\",",values[SeriesDescriptionIndex]];
   }
   
//5.33 Modality
   NSRegularExpression *ModalityRegex=nil;
   NSInteger ModalityIndex=[names indexOfObject:@"Modality"];
   if (ModalityIndex!=NSNotFound)
   {
      ModalityRegex=[NSRegularExpression regularExpressionWithPattern:values[ModalityIndex] options:0 error:NULL];
      [canonicalQuery appendFormat:@"\"Modality\":\"%@\",",values[ModalityIndex]];
   }

//5.34 SOPClass
   NSRegularExpression *SOPClassRegex=nil;
   NSInteger SOPClassIndex=[names indexOfObject:@"SOPClass"];
   if (SOPClassIndex!=NSNotFound)
   {
      SOPClassRegex=[NSRegularExpression regularExpressionWithPattern:values[SOPClassIndex] options:0 error:NULL];
      [canonicalQuery appendFormat:@"\"SOPClass\":\"%@\",",values[SOPClassIndex]];
   }
   
//5.35 SOPClassOff
   NSRegularExpression *SOPClassOffRegex=nil;
   NSInteger SOPClassOffIndex=[names indexOfObject:@"SOPClassOff"];
   if (SOPClassOffIndex!=NSNotFound)
   {
      SOPClassOffRegex=[NSRegularExpression regularExpressionWithPattern:values[SOPClassOffIndex] options:0 error:NULL];
      [canonicalQuery appendFormat:@"\"SOPClassOff\":\"%@\",",values[SOPClassOffIndex]];
   }

//hasRestriction?
   BOOL hasRestriction=
      SeriesInstanceUIDRegex
   || SeriesNumberRegex
   || SeriesDescriptionRegex
   || ModalityRegex
   || SOPClassRegex
   || SOPClassOffRegex;

#pragma mark sha512
   [canonicalQuery replaceCharactersInRange:NSMakeRange(canonicalQuery.length-1, 1) withString:@"}"];
   LOG_DEBUG(@"curl --header \"Content-Type: application/json\" --request POST --data '%@' %@ > dcm.zip",canonicalQuery,[request.URL absoluteString]);
   NSString *canonicalQuerySHA512String=[canonicalQuery SHA512String];
   NSString *queryPath=
   [
    [
     [
      DRS.tokentmpDir
      stringByAppendingPathComponent:@"query"
     ]
     stringByAppendingPathComponent:canonicalQuerySHA512String
    ]
    stringByAppendingPathExtension:@"json"
   ];

   NSString *matchPath=
   [
    [
     [
      DRS.tokentmpDir
      stringByAppendingPathComponent:@"match"
     ]
     stringByAppendingPathComponent:canonicalQuerySHA512String
    ]
    stringByAppendingPathExtension:@"json"
   ];

   if (![defaultManager fileExistsAtPath:queryPath])
   {
      //save first time request
      [canonicalQuery writeToFile:canonicalQuerySHA512String atomically:NO encoding:NSUTF8StringEncoding error:nil];
   }
   else
   {
      //request already exists, load response if exists
       JSONArray=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:matchPath] options:NSJSONReadingMutableContainers  error:&error];
       if (! JSONArray)
       {
          LOG_WARNING(@"studyToken descarted cached match %@. %@",[matchPath lastPathComponent], [error description]);
          if (![defaultManager
                moveItemAtPath:matchPath
                toPath:[DRS.tokentmpDir stringByAppendingPathComponent:@"descarted"] error:&error])
          LOG_WARNING(@"studyToken could remove bad match file. %@",[error description]);
       }
   }
   if (!JSONArray) JSONArray=[NSMutableArray array];


#pragma mark · 6 accessType

//6.1
   NSInteger accessType=NSNotFound;
   NSString *requestPath=request.path;
   if (![requestPath isEqualToString:@"/studyToken"])
      accessType=[
                  @[
                     @"/weasis.xml",
                     @"/cornerstone.json",
                     @"/dicom.zip",
                     @"/osirix.dcmURLs",
                     @"/datatablesseries.json",
                     @"/datatablespatient.json",
                     @"/iso.dicom.zip",
                     @"/deflate.iso.dicom.zip",
                     @"/max.deflate.iso.dicom.zip",
                     @"/zip64.iso.dicom.zip",
                     @"/wadors.dicom"
                  ]  indexOfObject:requestPath
                  ];
   else
   {
      NSInteger accessTypeIndex=[names indexOfObject:@"accessType"];
      if (accessTypeIndex==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessType required in request"];
      accessType=[
                  @[
                     @"weasis.xml",
                     @"cornerstone.json",
                     @"dicom.zip",
                     @"osirix.dcmURLs",
                     @"datatablesseries.json",
                     @"datatablespatient.json",
                     @"iso.dicom.zip",
                     @"deflate.iso.dicom.zip",
                     @"max.deflate.iso.dicom.zip",
                     @"zip64.iso.dicom.zip",
                     @"wadors.dicom"
                  ]
                  indexOfObject:values[accessTypeIndex]
                  ];
      if (accessType==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessType %@ unknown",values[accessTypeIndex]];
   }
   switch (accessType) {
      case accessTypeWeasis:{
         return weasis(
                 JSONArray,
                 canonicalQuerySHA512String,
                 proxyURIString,
                 sessionString,
                 tokenString,
                 lanArray,
                 wanArray,
                 StudyInstanceUIDRegexpString,
                 AccessionNumberSqlEqualString,
                 refInstitutionSqlLikeString,
                 refServiceSqlLikeString,
                 refUserSqlLikeString,
                 refIDSqlLikeString,
                 refIDTypeSqlLikeString,
                 readInstitutionSqlLikeString,
                 readServiceSqlLikeString,
                 readUserSqlLikeString,
                 readIDSqlLikeString,
                 readIDTypeSqlLikeString,
                 StudyIDSqlLikeString,
                 PatientIDSqlLikeString,
                 patientFamilySqlLikeEscapedString,
                 patientGivenSqlLikeEscapedString,
                 patientMiddleSqlLikeEscapedString,
                 patientPrefixSqlLikeEscapedString,
                 patientSuffixSqlLikeEscapedString,
                 issuerArray,
                 StudyDateArray,
                 SOPClassInStudySqlEqualString,
                 ModalityInStudySqlEqualString,
                 StudyDescriptionRegexpString,
                 hasRestriction,
                 SeriesInstanceUIDRegex,
                 SeriesNumberRegex,
                 SeriesDescriptionRegex,
                 ModalityRegex,
                 SOPClassRegex,
                 SOPClassOffRegex,
                 accessType
                 );
         } break;//end of sql wado weasis
      case accessTypeCornerstone:{
         return cornerstone(
                 JSONArray,
                 canonicalQuerySHA512String,
                 proxyURIString,
                 sessionString,
                 tokenString,
                 lanArray,
                 wanArray,
                 StudyInstanceUIDRegexpString,
                 AccessionNumberSqlEqualString,
                 refInstitutionSqlLikeString,
                 refServiceSqlLikeString,
                 refUserSqlLikeString,
                 refIDSqlLikeString,
                 refIDTypeSqlLikeString,
                 readInstitutionSqlLikeString,
                 readServiceSqlLikeString,
                 readUserSqlLikeString,
                 readIDSqlLikeString,
                 readIDTypeSqlLikeString,
                 StudyIDSqlLikeString,
                 PatientIDSqlLikeString,
                 patientFamilySqlLikeEscapedString,
                 patientGivenSqlLikeEscapedString,
                 patientMiddleSqlLikeEscapedString,
                 patientPrefixSqlLikeEscapedString,
                 patientSuffixSqlLikeEscapedString,
                 issuerArray,
                 StudyDateArray,
                 SOPClassInStudySqlEqualString,
                 ModalityInStudySqlEqualString,
                 StudyDescriptionRegexpString,
                 hasRestriction,
                 SeriesInstanceUIDRegex,
                 SeriesNumberRegex,
                 SeriesDescriptionRegex,
                 ModalityRegex,
                 SOPClassRegex,
                 SOPClassOffRegex,
                 accessType
                 );
         } break;//end of sql wado cornerstone
      case accessTypeDicomzip:
      case accessTypeIsoDicomZip:
      case accessTypeDeflateIsoDicomZip:
      case accessTypeMaxDeflateIsoDicomZip:
      {
            return dicomzip(
                    JSONArray,
                    canonicalQuerySHA512String,
                    proxyURIString,
                    sessionString,
                    tokenString,
                    lanArray,
                    wanArray,
                    StudyInstanceUIDRegexpString,
                    AccessionNumberSqlEqualString,
                    refInstitutionSqlLikeString,
                    refServiceSqlLikeString,
                    refUserSqlLikeString,
                    refIDSqlLikeString,
                    refIDTypeSqlLikeString,
                    readInstitutionSqlLikeString,
                    readServiceSqlLikeString,
                    readUserSqlLikeString,
                    readIDSqlLikeString,
                    readIDTypeSqlLikeString,
                    StudyIDSqlLikeString,
                    PatientIDSqlLikeString,
                    patientFamilySqlLikeEscapedString,
                    patientGivenSqlLikeEscapedString,
                    patientMiddleSqlLikeEscapedString,
                    patientPrefixSqlLikeEscapedString,
                    patientSuffixSqlLikeEscapedString,
                    issuerArray,
                    StudyDateArray,
                    SOPClassInStudySqlEqualString,
                    ModalityInStudySqlEqualString,
                    StudyDescriptionRegexpString,
                    hasRestriction,
                    SeriesInstanceUIDRegex,
                    SeriesNumberRegex,
                    SeriesDescriptionRegex,
                    ModalityRegex,
                    SOPClassRegex,
                    SOPClassOffRegex,
                    accessType
                    );
         
         } break;//end of sql wado dicomzip
      case accessTypeOsirix:{
            return osirixdcmURLs(
                    JSONArray,
                    canonicalQuerySHA512String,
                    proxyURIString,
                    sessionString,
                    tokenString,
                    lanArray,
                    wanArray,
                    StudyInstanceUIDRegexpString,
                    AccessionNumberSqlEqualString,
                    refInstitutionSqlLikeString,
                    refServiceSqlLikeString,
                    refUserSqlLikeString,
                    refIDSqlLikeString,
                    refIDTypeSqlLikeString,
                    StudyIDSqlLikeString,
                    PatientIDSqlLikeString,
                    patientFamilySqlLikeEscapedString,
                    patientGivenSqlLikeEscapedString,
                    patientMiddleSqlLikeEscapedString,
                    patientPrefixSqlLikeEscapedString,
                    patientSuffixSqlLikeEscapedString,
                    issuerArray,
                    StudyDateArray,
                    SOPClassInStudySqlEqualString,
                    ModalityInStudySqlEqualString,
                    StudyDescriptionRegexpString,
                    hasRestriction,
                    SeriesInstanceUIDRegex,
                    SeriesNumberRegex,
                    SeriesDescriptionRegex,
                    ModalityRegex,
                    SOPClassRegex,
                    SOPClassOffRegex,
                    accessType
                    );
         } break;//end of sql wado osirix
      case accessTypeDatatablesSeries:{
         } break;//end of sql wado datatableSeries
      case accessTypeDatatablesPatient:{
         } break;//end of sql wado datatableSeries
   }


//#pragma mark instance loop
   return [RSErrorResponse responseWithClientError:404 message:@"studyToken should not be here"];

}

@end
