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
static NSString *sqlTwoPks=@"\" | awk -F\\t ' BEGIN{ ORS=\"/\"; OFS=\".\";} {print $1, $2} '";

// item/
static NSString *sqlsingleslash=@"\" | awk -F\\t ' BEGIN{ ORS=\"/\"; OFS=\"\";} {print $1} '";



// //r+/n  unitSeparator+|
// | sed -e 's/\\x0F\\x0A$//'

static NSString *sqlRecordFourUnits=@"\" | awk -F\\t ' BEGIN{ ORS=\"\\x0D\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4}'";

static NSString *sqlRecordFiveUnits=@"\" | awk -F\\t ' BEGIN{ ORS=\"\\x0D\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4, $5}'";

static NSString *sqlRecordSixUnits=@"\" | awk -F\\t ' BEGIN{ ORS=\"\\x0D\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4, $5, $6}'";

static NSString *sqlRecordEightUnits=@"\" | awk -F\\t ' BEGIN{ ORS=\"\\x0D\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4, $5, $6, $7, $8}'";

static NSString *sqlRecordNineUnits=@"\" | awk -F\\t ' BEGIN{ ORS=\"\\x0D\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4, $5, $6, $7, $8, $9}'";

static NSString *sqlRecordTenUnits=@"\" | awk -F\\t ' BEGIN{ ORS=\"\\x0D\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10}'";

static NSString *sqlRecordElevenUnits=@"\" | awk -F\\t ' BEGIN{ ORS=\"\\x0D\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11}'";

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
)
{
   NSMutableData * mutableData=[NSMutableData data];
#pragma mark - exclusive study matches
   if (StudyInstanceUIDRegexpString)
#pragma mark · StudyInstanceUID
   {
//six parts: prolog,select,where,and,limit&order,format
      if (execUTF8Bash(
          sqlcredentials,
          [NSString stringWithFormat:@"%@%@%@%@%@%@",
           sqlprolog,
            EuiE?sqlDictionary[@"EselectEuiE"]:sqlDictionary[@"EselectEP"],
           sqlDictionary[@"Ewhere"],
           [NSString stringWithFormat:
            sqlDictionary[@"EmatchEui"],
            StudyInstanceUIDRegexpString
            ],
           @"",
           sqlTwoPks
          ],
          mutableData)
          !=0) return [RSErrorResponse responseWithClientError:404 message:@"studyToken StudyInstanceUID %@ db error",StudyInstanceUIDRegexpString];
   }
   else if (AccessionNumberEqualString)
#pragma mark · AccessionNumber
   {

      switch (issuerArray.count) {
            
         case issuerNone:
         {
            if (execUTF8Bash(sqlcredentials,
                        [NSString stringWithFormat:@"%@%@%@%@%@%@",
                         sqlprolog,
                         EuiE?sqlDictionary[@"EselectEuiE"]:sqlDictionary[@"EselectEP"],
                         sqlDictionary[@"Ewhere"],
                         [NSString stringWithFormat:
                          (sqlDictionary[@"EmatchEan"])[issuerNone],
                          AccessionNumberEqualString
                          ],
                         @"",
                         sqlTwoPks
                        ],
                        mutableData)
                !=0) return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessionNumber db error. AN='%@' issuer='%@'",AccessionNumberEqualString,[issuerArray componentsJoinedByString:@"^"]];
            } break;

         case issuerLocal:
         {
            if (execUTF8Bash(sqlcredentials,
                             [NSString stringWithFormat:@"%@%@%@%@%@%@%@",
                              sqlprolog,
                              EuiE?sqlDictionary[@"EselectEuiE"]:sqlDictionary[@"EselectEP"],
                              ((sqlDictionary[@"Ejoin"])[0])[0],
                              sqlDictionary[@"Ewhere"],
                              [NSString stringWithFormat:
                               (sqlDictionary[@"EmatchEan"])[issuerLocal],
                               AccessionNumberEqualString,
                               issuerArray[0]
                               ],
                              @"",
                              sqlTwoPks
                             ],
                             mutableData)
                !=0) return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessionNumber db error. AN='%@' issuer='%@'",AccessionNumberEqualString,[issuerArray componentsJoinedByString:@"^"]];
         } break;
                  
         case issuerUniversal:
         {
            if (execUTF8Bash(sqlcredentials,
                             [NSString stringWithFormat:@"%@%@%@%@%@%@%@",
                              sqlprolog,
                              EuiE?sqlDictionary[@"EselectEuiE"]:sqlDictionary[@"EselectEP"],
                              ((sqlDictionary[@"Ejoin"])[0])[0],
                              sqlDictionary[@"Ewhere"],
                              [NSString stringWithFormat:
                               (sqlDictionary[@"EmatchEan"])[issuerUniversal],
                               AccessionNumberEqualString,
                               issuerArray[1],
                               issuerArray[2]
                               ],
                              @"",
                              sqlTwoPks
                             ],
                             mutableData)
               !=0) return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessionNumber db error. AN='%@' issuer='%@'",AccessionNumberEqualString,[issuerArray componentsJoinedByString:@"^"]];
         } break;

                     
         case issuerDivision:
         {
            if (execUTF8Bash(sqlcredentials,
                             [NSString stringWithFormat:@"%@%@%@%@%@%@%@",
                              sqlprolog,
                              EuiE?sqlDictionary[@"EselectEuiE"]:sqlDictionary[@"EselectEP"],
                              ((sqlDictionary[@"Ejoin"])[0])[0],
                              sqlDictionary[@"Ewhere"],
                              [NSString stringWithFormat:
                               (sqlDictionary[@"EmatchEan"])[issuerDivision],
                               AccessionNumberEqualString,
                               issuerArray[0],
                               issuerArray[1],
                               issuerArray[2]
                               ],
                              @"",
                              sqlTwoPks
                             ],
                             mutableData)
               !=0) return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessionNumber db error. AN='%@' issuer='%@'",AccessionNumberEqualString,[issuerArray componentsJoinedByString:@"^"]];
         } break;

         default:
            return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessionNumber issuer error '%@'",[issuerArray componentsJoinedByString:@"^"]];
            break;
      }
   }
   else
   {
#pragma mark - cumulative matches
      
      NSMutableArray *sqlJoins=[NSMutableArray array];
      NSMutableString *filters=[NSMutableString string];
      
      if (PatientIDLikeString)
#pragma mark 1 Pid
      {
         [sqlJoins addObjectsFromArray:(sqlDictionary[@"Ejoin"])[EcumulativeFilterPid]];
         switch (issuerArray.count) {
               
            case issuerNone:
               [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPid])[issuerNone],PatientIDLikeString];
               break;

            case issuerLocal:
               [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPid])[issuerLocal],PatientIDLikeString,issuerArray[0]];
               break;

            default:
               return [RSErrorResponse responseWithClientError:404 message:@"studyToken patientID issuer error '%@'",[issuerArray componentsJoinedByString:@"^"]];
               break;
         }
      }
      

      if (   patientFamilyLikeString
          || patientGivenLikeString
          || patientMiddleLikeString
          || patientPrefixLikeString
          || patientSuffixLikeString
          )
#pragma mark 2 Ppn
      {
          for (NSString *moreJoin in (sqlDictionary[@"Ejoin"])[EcumulativeFilterPpn])
          {
              if ([sqlJoins indexOfObject:moreJoin]==NSNotFound)[sqlJoins addObject:moreJoin];
          }
          NSString *pnFilterCompoundString=((sqlDictionary[@"Eand"])[EcumulativeFilterPpn])[pnFilterCompound];
         if (![pnFilterCompoundString isEqualToString:@""])
         {
            // DB with pn compound field
            NSString *regexp=nil;
            if (patientSuffixLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@^%@^%@^%@",
               patientFamilyLikeString?patientFamilyLikeString:@"",
               patientGivenLikeString?patientGivenLikeString:@"",
               patientMiddleLikeString?patientMiddleLikeString:@"",
               patientPrefixLikeString?patientPrefixLikeString:@"",
               patientSuffixLikeString];
            else if (patientPrefixLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@^%@^%@",
               patientFamilyLikeString?patientFamilyLikeString:@"",
               patientGivenLikeString?patientGivenLikeString:@"",
               patientMiddleLikeString?patientMiddleLikeString:@"",
               patientPrefixLikeString];
            else if (patientMiddleLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@^%@",
               patientFamilyLikeString?patientFamilyLikeString:@"",
               patientGivenLikeString?patientGivenLikeString:@"",
               patientMiddleLikeString];
            else if (patientGivenLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@",
               patientFamilyLikeString?patientFamilyLikeString:@"",
               patientGivenLikeString];
            else if (patientFamilyLikeString)
               regexp=[NSString stringWithString:patientFamilyLikeString];
            
            if (regexp) [filters appendFormat:pnFilterCompoundString,regexp];
         }
         else
         {
            //DB with pn detailed fields
            if (patientFamilyLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPpn])[pnFilterFamily],patientFamilyLikeString];
            if (patientGivenLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPpn])[pnFilterGiven],patientGivenLikeString];
            if (patientMiddleLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPpn])[pnFilterMiddle],patientMiddleLikeString];
            if (patientPrefixLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPpn])[pnFilterPrefix],patientPrefixLikeString];
            if (patientSuffixLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPpn])[pnFilterSuffix],patientSuffixLikeString];
         }

      }
      
      
      
      if (StudyIDLikeString)
#pragma mark 3 Eid
      {
          for (NSString *moreJoin in (sqlDictionary[@"Ejoin"])[EcumulativeFilterEid])
          {
              if ([sqlJoins indexOfObject:moreJoin]==NSNotFound)[sqlJoins addObject:moreJoin];
          }
         [filters appendFormat:(sqlDictionary[@"Eand"])[EcumulativeFilterEid],StudyIDLikeString];
      }



      //(Eda)
      if (StudyDateArray)
#pragma mark 4 Eda
      {
         for (NSString *moreJoin in (sqlDictionary[@"Ejoin"])[EcumulativeFilterEda])
         {
             if ([sqlJoins indexOfObject:moreJoin]==NSNotFound)[sqlJoins addObject:moreJoin];
         }
          
         NSArray *Eda=nil;
         NSString *StudyDate0=nil;
         NSString *StudyDate1=nil;
         NSString *StudyDate2=nil;
         NSString *StudyDate3=nil;
         if ([((sqlDictionary[@"Eand"])[EcumulativeFilterEda])[0] count])
         {
             //ISO in DB
             Eda=((sqlDictionary[@"Eand"])[EcumulativeFilterEda])[0];
             StudyDate0=StudyDateArray[0];
             StudyDate1=StudyDateArray[1];
             StudyDate2=StudyDateArray[2];
             StudyDate3=StudyDateArray[3];
         }
         else
         {
             //DICOM DA in DB
             Eda=((sqlDictionary[@"Eand"])[EcumulativeFilterEda])[1];
             NSUInteger count=StudyDateArray.count;
             if (count>0)
             {
                 StudyDate0=[DICMTypes DAStringFromDAISOString:StudyDateArray[0]];
                 if (count>1)
                 {
                     StudyDate1=[DICMTypes DAStringFromDAISOString:StudyDateArray[1]];
                     if (count>2)
                     {
                         StudyDate2=[DICMTypes DAStringFromDAISOString:StudyDateArray[2]];
                         if (count>3)
                         {
                             StudyDate3=[DICMTypes DAStringFromDAISOString:StudyDateArray[3]];
                         }
                     }
                 }
             }
         }
         switch (StudyDateArray.count) {
            case dateMatchAny:
               break;
            case dateMatchOn:
            {
               [filters appendFormat:Eda[dateMatchOn],StudyDate0];
            } break;
            case dateMatchSince:
            {
               [filters appendFormat:Eda[dateMatchSince],StudyDate0];
            } break;
            case dateMatchUntil:
            {
               [filters appendFormat:Eda[dateMatchUntil],StudyDate2];

            } break;
            case dateMatchBetween:
            {
               [filters appendFormat:Eda[dateMatchBetween],StudyDate0,StudyDate3];

            } break;
         }
      }



#pragma mark 5 Elo
      if (StudyDescriptionRegexpString)
      {
         for (NSString *moreJoin in (sqlDictionary[@"Ejoin"])[EcumulativeFilterElo])
         {
             if ([sqlJoins indexOfObject:moreJoin]==NSNotFound)[sqlJoins addObject:moreJoin];
         }
         [filters appendFormat:(sqlDictionary[@"Eand"])[EcumulativeFilterElo],StudyDescriptionRegexpString];
      }
      
      
      if (   refInstitutionLikeString
          || refServiceLikeString
          || refUserLikeString
          || refIDLikeString
          || refIDTypeLikeString
          )
#pragma mark 6 Ref
      {
          NSLog(@"%d",EcumulativeFilterRef);
         for (NSString *moreJoin in (sqlDictionary[@"Ejoin"])[EcumulativeFilterRef])
         {
             if ([sqlJoins indexOfObject:moreJoin]==NSNotFound)[sqlJoins addObject:moreJoin];
         }
         NSString *pnFilterCompoundString=((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterCompound];
         if (![pnFilterCompoundString isEqualToString:@""])
         {
            // DB with pn compound field
            NSString *regexp=nil;
            if (refIDTypeLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@^%@^%@^%@",
               refInstitutionLikeString?refInstitutionLikeString:@"",
               refServiceLikeString?refServiceLikeString:@"",
               refUserLikeString?refUserLikeString:@"",
               refIDLikeString?refIDLikeString:@"",
               refIDTypeLikeString];
            else if (refIDLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@^%@^%@",
               refInstitutionLikeString?refInstitutionLikeString:@"",
               refServiceLikeString?refServiceLikeString:@"",
               refUserLikeString?refUserLikeString:@"",
               refIDLikeString];
            else if (refUserLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@^%@",
               refInstitutionLikeString?refInstitutionLikeString:@"",
               refServiceLikeString?refServiceLikeString:@"",
               refUserLikeString];
            else if (refServiceLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@",
               refInstitutionLikeString?refInstitutionLikeString:@"",
               refServiceLikeString];
            else if (refInstitutionLikeString)
               regexp=[NSString stringWithString:refInstitutionLikeString];
            
            if (regexp) [filters appendFormat:pnFilterCompoundString,regexp];
         }
         else
         {
            //DB with pn detailed fields
            if (refInstitutionLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterFamily],refInstitutionLikeString];
            if (refServiceLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterGiven],refServiceLikeString];
            if (refUserLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterGiven],refUserLikeString];
            if (refIDLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterGiven],refIDLikeString];
            if (refIDTypeLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterGiven],refIDTypeLikeString];
         }
      }
      
      
      if (   readInstitutionSqlLikeString
          || readServiceSqlLikeString
          || readUserSqlLikeString
          || readIDSqlLikeString
          || readIDTypeSqlLikeString
          )
#pragma mark 7 Read
      {
         for (NSString *moreJoin in (sqlDictionary[@"Ejoin"])[EcumulativeFilterRead])
         {
             if ([sqlJoins indexOfObject:moreJoin]==NSNotFound)[sqlJoins addObject:moreJoin];
         }
         NSString *pnFilterCompoundString=((sqlDictionary[@"Eand"])[EcumulativeFilterRead])[pnFilterCompound];
         if (![pnFilterCompoundString isEqualToString:@""])
         {
            // DB with pn compound field
            NSString *regexp=nil;
            if (refIDTypeLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@^%@^%@^%@",
               refInstitutionLikeString?refInstitutionLikeString:@"",
               refServiceLikeString?refServiceLikeString:@"",
               refUserLikeString?refUserLikeString:@"",
               refIDLikeString?refIDLikeString:@"",
               refIDTypeLikeString];
            else if (refIDLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@^%@^%@",
               refInstitutionLikeString?refInstitutionLikeString:@"",
               refServiceLikeString?refServiceLikeString:@"",
               refUserLikeString?refUserLikeString:@"",
               refIDLikeString];
            else if (refUserLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@^%@",
               refInstitutionLikeString?refInstitutionLikeString:@"",
               refServiceLikeString?refServiceLikeString:@"",
               refUserLikeString];
            else if (refServiceLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@",
               refInstitutionLikeString?refInstitutionLikeString:@"",
               refServiceLikeString];
            else if (refInstitutionLikeString)
               regexp=[NSString stringWithString:refInstitutionLikeString];
            
            if (regexp) [filters appendFormat:pnFilterCompoundString,regexp];
         }
         else
         {
            //DB with pn detailed fields
            if (refInstitutionLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRead])[pnFilterFamily],refInstitutionLikeString];
            if (refServiceLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRead])[pnFilterGiven],refServiceLikeString];
            if (refUserLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRead])[pnFilterGiven],refUserLikeString];
            if (refIDLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRead])[pnFilterGiven],refIDLikeString];
            if (refIDTypeLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRead])[pnFilterGiven],refIDTypeLikeString];
         }
      }
      

      if (SOPClassInStudyRegexpString)
#pragma mark 8 Esc (SOPClassesInStudy)
         {
            for (NSString *moreJoin in (sqlDictionary[@"Ejoin"])[EcumulativeFilterEsc])
            {
                if ([sqlJoins indexOfObject:moreJoin]==NSNotFound)[sqlJoins addObject:moreJoin];
            }
            [filters appendFormat:(sqlDictionary[@"Eand"])[EcumulativeFilterEsc],SOPClassInStudyRegexpString];
         }

      
      
      if (ModalityInStudyRegexpString)
#pragma mark 9 (optional) ModalitiesInStudy Emo
         {
            for (NSString *moreJoin in (sqlDictionary[@"Ejoin"])[EcumulativeFilterEmo])
            {
                if ([sqlJoins indexOfObject:moreJoin]==NSNotFound)[sqlJoins addObject:moreJoin];
            }
            [filters appendFormat:(sqlDictionary[@"Eand"])[EcumulativeFilterEmo],SOPClassInStudyRegexpString];
         }
            
       //six parts: prolog,select,where,and,limit&order,format
       if (execUTF8Bash(
           sqlcredentials,
           [NSString stringWithFormat:@"%@%@%@%@%@%@%@",
            sqlprolog,
            EuiE?sqlDictionary[@"EselectEuiE"]:sqlDictionary[@"EselectEP"],
            [sqlJoins componentsJoinedByString:@""],
            sqlDictionary[@"Ewhere"],
            filters,
            @"",
            sqlTwoPks
           ],
           mutableData)
           !=0) return [RSErrorResponse responseWithClientError:404 message:@"studyToken StudyInstanceUID %@ db error",StudyInstanceUIDRegexpString];

      
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
                AccessionNumberEqualString,
                refInstitutionLikeString,
                refServiceLikeString,
                refUserLikeString,
                refIDLikeString,
                refIDTypeLikeString,
                readInstitutionSqlLikeString,
                readServiceSqlLikeString,
                readUserSqlLikeString,
                readIDSqlLikeString,
                readIDTypeSqlLikeString,
                StudyIDLikeString,
                PatientIDLikeString,
                patientFamilyLikeString,
                patientGivenLikeString,
                patientMiddleLikeString,
                patientPrefixLikeString,
                patientSuffixLikeString,
                issuerArray,
                StudyDateArray,
                SOPClassInStudyRegexpString,
                ModalityInStudyRegexpString,
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
                                 NSXMLElement *InstanceElement=[WeasisInstance pk:IProperties[0] weasisSOPInstanceUID:IProperties[1] weasisInstanceNumber:IProperties[2] weasisDirectDownloadFile:nil NumberOfFrames:IProperties[3]];

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
                   AccessionNumberEqualString,
                   refInstitutionLikeString,
                   refServiceLikeString,
                   refUserLikeString,
                   refIDLikeString,
                   refIDTypeLikeString,
                   readInstitutionSqlLikeString,
                   readServiceSqlLikeString,
                   readUserSqlLikeString,
                   readIDSqlLikeString,
                   readIDTypeSqlLikeString,
                   StudyIDLikeString,
                   PatientIDLikeString,
                   patientFamilyLikeString,
                   patientGivenLikeString,
                   patientMiddleLikeString,
                   patientPrefixLikeString,
                   patientSuffixLikeString,
                   issuerArray,
                   StudyDateArray,
                   SOPClassInStudyRegexpString,
                   ModalityInStudyRegexpString,
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
                     [JSONArray addObject:arc];
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
   [studyArray setArray:arc[@"studyList"]];
   if (!studyArray)
   {
      studyArray=[NSMutableArray array];
      [patient setObject:studyArray forKey:@"studyList"];
   }
}
else //no patient
{
   studyArray=[NSMutableArray array];
   patient=[NSMutableDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithLongLong:[(patientSqlPropertiesArray[0])[0] longLongValue]],@"key",
            (patientSqlPropertiesArray[0])[1], @"PatientID",
            [(patientSqlPropertiesArray[0])[2] removeTrailingCarets],@"PatientName",
            (patientSqlPropertiesArray[0])[3],@"IssuerOfPatientID",
            (patientSqlPropertiesArray[0])[4],@"PatientBirthDate",
            (patientSqlPropertiesArray[0])[5],@"PatientSex",
            studyArray,@"studyList",
            nil
           ];
    [patientArray addObject:patient];
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
                                                 sqlRecordElevenUnits
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
   [study  setObject:[(studySqlPropertiesArray[0])[7] removeTrailingCarets] forKey:@"ReferringPhysicianName"];
   [study  setObject:[(studySqlPropertiesArray[0])[8] removeTrailingCarets] forKey:@"NameOfPhysiciansReadingStudy"];
   if (!seriesArray)
   {
      seriesArray=[NSMutableArray array];
      [study setObject:seriesArray forKey:@"seriesList"];
   }
}
else //no study
{
#pragma mark TODO accessionNumber issuer
   seriesArray=[NSMutableArray array];
   study=[NSMutableDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithLongLong:[(studySqlPropertiesArray[0])[0] longLongValue]],@"key",
      (studySqlPropertiesArray[0])[1], @"StudyInstanceUID",
      (studySqlPropertiesArray[0])[2], @"studyDescription",
      [DICMTypes DAStringFromDAISOString:(studySqlPropertiesArray[0])[3]], @"studyDate",
      [DICMTypes TMStringFromTMISOString:(studySqlPropertiesArray[0])[4]],@"StudyTime",
      (studySqlPropertiesArray[0])[5],@"AccessionNumber",
      (studySqlPropertiesArray[0])[6],@"StudyID",
      [(studySqlPropertiesArray[0])[7] removeTrailingCarets],@"ReferringPhysicianName",
      [(studySqlPropertiesArray[0])[8] removeTrailingCarets],@"NameOfPhysiciansReadingStudy",
      (studySqlPropertiesArray[0])[9],@"modality",
      (patientSqlPropertiesArray[0])[1],@"patientId",
      [(patientSqlPropertiesArray[0])[2] removeTrailingCarets],@"PatientName",
      seriesArray,@"seriesList",
      nil
   ];
    [studyArray addObject:study];
}
                              
#pragma mark ...series loop

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
                           LOG_ERROR(@"studyToken series db error");
                           continue;
                        }
                        NSArray *seriesSqlPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:3 decreasing:NO];//NSUTF8StringEncoding
                        for (NSArray *seriesSqlProperties in seriesSqlPropertiesArray)
                        {
                           //if series exists in cache
                            NSMutableDictionary *series=[seriesArray firstMutableDictionaryWithKey:@"key" isEqualToNumber:[NSNumber numberWithLongLong:[seriesSqlProperties[0] longLongValue]]];
                           if (series)
                           {
                              //SOP Class already known
                              //loop series only if numImages doesn´t correspond
#pragma mark TODO
                              //find numImages for the series
                              //if ([series[@"numImages"] longLongValue]!=[seriesSqlProperties[10]longLongValue])
                              {
                                 //loop instances
                              }
                           }
                           else //series does not exist in cache
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
instanceArray,@"instanceList",
nil
];//not available [NSNumber numberWithLongLong:[seriesSqlProperties[10] longLongValue]], @"numImages",
[seriesArray addObject:series];

                                 //add institution to studies
[study setObject:seriesSqlProperties[5] forKey:@"institution"];
                                  
                                 
                              
#pragma mark instances depending on the SOP Class
/*
 pk, SOPInstanceUID and instance number are common to allo SOP Class
 
 In relation to Cornerstone, the number of frames is also important
 NumFrames=[NSNumber numberWithInt:[instanceSqlProperties[3] intValue]];
 
 This information is not available in non multiframe objects. Those shall have the value 0 if they are not frame based and 1 if they are always single frame.
 
 In the case of multiframe SOP Classes:
 Since number of frames may belong to some binary blog of dicom attrs, we allow postprocessing on sql raw data, and then on table-organized results.
 We reserve the value -1 to state that the info is not available at all in the DB.
 
 As seen some casuistics can be resolved before any query to the instance table, based on the SOP Class already obtained for series filters, we use specific query depending on the case:
 - I0 corresponde to a non frame based object where number of frames is forced to 0
 - I1 corresponds to a monoframe object where number of frames is forced to 1
 - I corresponds to an enhanced SOP Class potentially containing multiframes.
 */

[mutableData setData:[NSData data]];
NSArray *instanceSqlPropertiesArray;
if ([DRS.InstanceUniqueFrameSOPClass indexOfObject:SOPClass]!=NSNotFound)
{
   //I1
   if (execUTF8Bash(sqlcredentials,
                  [NSString stringWithFormat:
                     sqlDictionary[@"I1"],
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
   instanceSqlPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding stringUnitsPostProcessTitle:nil orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding

}
else if ([DRS.InstanceMultiFrameSOPClass indexOfObject:SOPClass]!=NSNotFound)
{
   //I
   // watch optional IpostprocessingCommandsSh
   if (execUTF8Bash(sqlcredentials,
                  [NSString stringWithFormat:
                     sqlDictionary[@"I"],
                     sqlprolog,
                     seriesSqlProperties[0],
                     @"",
                   [sqlDictionary[@"IpostprocessingCommandsSh"]length]?sqlDictionary[@"IpostprocessingCommandsSh"]:sqlRecordFourUnits
                     ],
                  mutableData)
       !=0)
   {
      LOG_ERROR(@"studyToken study db error");
      continue;
   }

   instanceSqlPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding stringUnitsPostProcessTitle:sqlDictionary[@"IpostprocessingTitleMain"] orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding

}
else
{
  //I0
   if (execUTF8Bash(sqlcredentials,
                  [NSString stringWithFormat:
                     sqlDictionary[@"I0"],
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
   instanceSqlPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding stringUnitsPostProcessTitle:nil orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding
}

                                 
                              
#pragma mark ...instance loop
for (NSArray *instanceSqlProperties in instanceSqlPropertiesArray)
{
   //imageId = (weasis) DirectDownloadFile


   
   
   NSString *wadouriInstance=[NSString stringWithFormat:
                           @"wadouri:%@?requestType=WADO&studyUID=%@&seriesUID=%@&objectUID=%@&session=%@&custodianOID=%@&arcId=%@%@",
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
                           @"numFrames":[NSNumber numberWithLongLong:[instanceSqlProperties[3] longLongValue]]
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
             NSString *cornerstonePath=[[DRS.tokentmpDir stringByAppendingPathComponent:canonicalQuerySHA512String]stringByAppendingPathExtension:@"json"];
         [cornerstoneJson writeToFile:cornerstonePath atomically:NO];

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
                    AccessionNumberEqualString,
                    refInstitutionLikeString,
                    refServiceLikeString,
                    refUserLikeString,
                    refIDLikeString,
                    refIDTypeLikeString,
                    readInstitutionSqlLikeString,
                    readServiceSqlLikeString,
                    readUserSqlLikeString,
                    readIDSqlLikeString,
                    readIDTypeSqlLikeString,
                    StudyIDLikeString,
                    PatientIDLikeString,
                    patientFamilyLikeString,
                    patientGivenLikeString,
                    patientMiddleLikeString,
                    patientPrefixLikeString,
                    patientSuffixLikeString,
                    issuerArray,
                    StudyDateArray,
                    SOPClassInStudyRegexpString,
                    ModalityInStudyRegexpString,
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
 NSMutableArray      * JSONArray,
 NSString            * canonicalQuerySHA512String,
 NSString            * proxyURIString,
 NSString            * sessionString,
 NSString            * tokenString,
 NSMutableArray      * lanArray,
 NSMutableArray      * wanArray,
 NSString            * StudyInstanceUIDRegexpString,
 NSString            * AccessionNumberEqualString,
 NSString            * refInstitutionLikeString,
 NSString            * refServiceLikeString,
 NSString            * refUserLikeString,
 NSString            * refIDLikeString,
 NSString            * refIDTypeLikeString,
 NSString            * readInstitutionLikeString,
 NSString            * readServiceLikeString,
 NSString            * readUserLikeString,
 NSString            * readIDLikeString,
 NSString            * readIDTypeLikeString,
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

#pragma mark - exclusive filters

#pragma mark StudyInstanceUID
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

#pragma mark AccessionNumber
    NSString *AccessionNumberEqualString=nil;
    NSInteger AccessionNumberIndex=[names indexOfObject:@"AccessionNumber"];
    if (AccessionNumberIndex!=NSNotFound)
    {
       AccessionNumberEqualString=[values[AccessionNumberIndex] sqlEqualEscapedString];
       [canonicalQuery appendFormat:@"\"AccessionNumber\":\"%@\",",AccessionNumberEqualString];
    }

    
#pragma mark - cumulative filters

#pragma mark 1. PatientID (Pid)
    NSString *PatientIDLikeString=nil;
    NSInteger PatientIDIndex=[names indexOfObject:@"PatientID"];
    if (PatientIDIndex!=NSNotFound)
    {
       PatientIDLikeString=[values[PatientIDIndex] sqlLikeEscapedString];
       [canonicalQuery appendFormat:@"\"PatientID\":\"%@\",",PatientIDLikeString];
    }

#pragma mark 2. PatientName (Ppn)
   
   BOOL patientNamePart=false;
   
   NSString *patientFamilyLikeString=nil;
   NSInteger patientFamilyIndex=[names indexOfObject:@"patientFamily"];
   if (patientFamilyIndex!=NSNotFound)
   {
      patientNamePart=true;
      patientFamilyLikeString=[values[patientFamilyIndex] regexQuoteEscapedString];
      [canonicalQuery appendFormat:@"\"patientFamily\":\"%@\",",patientFamilyLikeString];
   }

   NSString *patientGivenLikeString=nil;
   NSInteger patientGivenIndex=[names indexOfObject:@"patientGiven"];
   if (patientGivenIndex!=NSNotFound)
   {
      patientNamePart=true;
      patientGivenLikeString=[values[patientGivenIndex] regexQuoteEscapedString];
      [canonicalQuery appendFormat:@"\"patientGiven\":\"%@\",",patientGivenLikeString];
   }

   NSString *patientMiddleLikeString=nil;
   NSInteger patientMiddleIndex=[names indexOfObject:@"patientMiddle"];
   if (patientMiddleIndex!=NSNotFound)
   {
      patientNamePart=true;
      patientMiddleLikeString=[values[patientMiddleIndex] regexQuoteEscapedString];
      [canonicalQuery appendFormat:@"\"patientMiddle\":\"%@\",",patientMiddleLikeString];
   }

   NSString *patientPrefixLikeString=nil;
   NSInteger patientPrefixIndex=[names indexOfObject:@"patientPrefix"];
   if (patientPrefixIndex!=NSNotFound)
   {
      patientNamePart=true;
      patientPrefixLikeString=[values[patientPrefixIndex] regexQuoteEscapedString];
      [canonicalQuery appendFormat:@"\"patientPrefix\":\"%@\",",patientPrefixLikeString];
   }

   NSString *patientSuffixLikeString=nil;
   NSInteger patientSuffixIndex=[names indexOfObject:@"patientSuffix"];
   if (patientSuffixIndex!=NSNotFound)
   {
      patientNamePart=true;
      patientSuffixLikeString=[values[patientSuffixIndex] regexQuoteEscapedString];
      [canonicalQuery appendFormat:@"\"patientSuffix\":\"%@\",",patientSuffixLikeString];
   }

   if (!patientNamePart)
   {
      NSInteger PatientNameIndex=[names indexOfObject:@"PatientName"];
      if (PatientNameIndex!=NSNotFound)
      {
         NSString *PatientNameRegexString=[values[PatientNameIndex] regexQuoteEscapedString];
         NSArray *PatientNameParts=[PatientNameRegexString componentsSeparatedByString:@"^"];
         if (PatientNameParts.count>0)
         {
            patientFamilyLikeString=PatientNameParts[0];
            [canonicalQuery appendFormat:@"\"patientFamily\":\"%@\",",patientFamilyLikeString];
         }
         if (PatientNameParts.count>1)
         {
            patientGivenLikeString=PatientNameParts[1];
            [canonicalQuery appendFormat:@"\"patientGiven\":\"%@\",",patientGivenLikeString];
         }
         if (PatientNameParts.count>2)
         {
            patientMiddleLikeString=PatientNameParts[2];
            [canonicalQuery appendFormat:@"\"patientMiddle\":\"%@\",",patientMiddleLikeString];
         }
         if (PatientNameParts.count>3)
         {
            patientPrefixLikeString=PatientNameParts[3];
            [canonicalQuery appendFormat:@"\"patientPrefix\":\"%@\",",patientPrefixLikeString];
         }
         if (PatientNameParts.count>4)
         {
            patientSuffixLikeString=PatientNameParts[4];
            [canonicalQuery appendFormat:@"\"patientSuffix\":\"%@\",",patientSuffixLikeString];
         }
      }
   }
    
#pragma mark 3. StudyID (Eid)
    
    NSString *StudyIDLikeString=nil;
    NSInteger StudyIDIndex=[names indexOfObject:@"StudyID"];
    if (StudyIDIndex!=NSNotFound)
    {
       StudyIDLikeString=[values[StudyIDIndex] sqlLikeEscapedString];
       [canonicalQuery appendFormat:@"\"StudyID\":\"%@\",",StudyIDLikeString];
    }

    
#pragma mark 4. StudyDate (Eda)
    
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
             
             if (StudyDatePipeComponents.count ==1 )
             {
                 StudyDateArray=@[StudyDatePipeComponents[0]];
             }
             else
             {
               
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
    }

 
#pragma mark 5. StudyDescription (Elo)
    
    NSString *StudyDescriptionRegexpString=nil;
    NSInteger StudyDescriptionIndex=[names indexOfObject:@"StudyDescription"];
    if (StudyDescriptionIndex!=NSNotFound)
    {
       StudyDescriptionRegexpString=[values[StudyDescriptionIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"StudyDescription\":\"%@\",",StudyDescriptionRegexpString];
    }

    
#pragma mark 6. ref

    BOOL refPart=false;

    NSString *refInstitutionLikeString=nil;
    NSInteger refInstitutionIndex=[names indexOfObject:@"refInstitution"];
    if (refInstitutionIndex!=NSNotFound)
    {
       refPart=true;
       refInstitutionLikeString=[values[refInstitutionIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"refInstitution\":\"%@\",",refInstitutionLikeString];
    }

    NSString *refServiceLikeString=nil;
    NSInteger refServiceIndex=[names indexOfObject:@"refService"];
    if (refServiceIndex!=NSNotFound)
    {
       refPart=true;
       refServiceLikeString=[values[refServiceIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"refService\":\"%@\",",refServiceLikeString];
    }

    NSString *refUserLikeString=nil;
    NSInteger refUserIndex=[names indexOfObject:@"refUser"];
    if (refUserIndex!=NSNotFound)
    {
       refPart=true;
       refUserLikeString=[values[refUserIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"refUser\":\"%@\",",refUserLikeString];
    }

    NSString *refIDLikeString=nil;
    NSInteger refIDIndex=[names indexOfObject:@"refID"];
    if (refIDIndex!=NSNotFound)
    {
       refPart=true;
       refIDLikeString=[values[refIDIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"refID\":\"%@\",",refIDLikeString];
    }

    NSString *refIDTypeLikeString=nil;
    NSInteger refIDTypeIndex=[names indexOfObject:@"refIDType"];
    if (refIDTypeIndex!=NSNotFound)
    {
       refPart=true;
       refIDTypeLikeString=[values[refIDTypeIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"refIDType\":\"%@\",",refIDTypeLikeString];
    }
   
   if (!refPart)
   {
      NSInteger refIndex=[names indexOfObject:@"ref"];
      if (refIndex!=NSNotFound)
      {
         NSString *refRegexString=[values[refIndex] regexQuoteEscapedString];
         NSArray *refParts=[refRegexString componentsSeparatedByString:@"^"];
         if (refParts.count>0)
         {
            refInstitutionLikeString=refParts[0];
            [canonicalQuery appendFormat:@"\"refInstitution\":\"%@\",",refInstitutionLikeString];
         }
         if (refParts.count>1)
         {
            refServiceLikeString=refParts[1];
            [canonicalQuery appendFormat:@"\"refService\":\"%@\",",refServiceLikeString];
         }
         if (refParts.count>2)
         {
            refUserLikeString=refParts[2];
            [canonicalQuery appendFormat:@"\"refUser\":\"%@\",",refUserLikeString];
         }
         if (refParts.count>3)
         {
            refIDLikeString=refParts[3];
            [canonicalQuery appendFormat:@"\"refID\":\"%@\",",refIDLikeString];
         }
         if (refParts.count>4)
         {
            refIDTypeLikeString=refParts[4];
            [canonicalQuery appendFormat:@"\"patientSuffix\":\"%@\",",refIDTypeLikeString];
         }
      }
   }


#pragma mark 7. read
    
    BOOL readPart=false;

    NSString *readInstitutionLikeString=nil;
    NSInteger readInstitutionIndex=[names indexOfObject:@"readInstitution"];
    if (readInstitutionIndex!=NSNotFound)
    {
       readPart=true;
       readInstitutionLikeString=[values[readInstitutionIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"readInstitution\":\"%@\",",readInstitutionLikeString];
    }

    NSString *readServiceLikeString=nil;
    NSInteger readServiceIndex=[names indexOfObject:@"readService"];
    if (readServiceIndex!=NSNotFound)
    {
       readPart=true;
       readServiceLikeString=[values[readServiceIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"readService\":\"%@\",",readServiceLikeString];
    }

    NSString *readUserLikeString=nil;
    NSInteger readUserIndex=[names indexOfObject:@"readUser"];
    if (readUserIndex!=NSNotFound)
    {
       readPart=true;
       readUserLikeString=[values[readUserIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"readUser\":\"%@\",",readUserLikeString];
    }

    NSString *readIDLikeString=nil;
    NSInteger readIDIndex=[names indexOfObject:@"readID"];
    if (readIDIndex!=NSNotFound)
    {
       readPart=true;
       readIDLikeString=[values[readIDIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"readID\":\"%@\",",readIDLikeString];
    }
    
    NSString *readIDTypeLikeString=nil;
    NSInteger readIDTypeIndex=[names indexOfObject:@"readIDType"];
    if (readIDTypeIndex!=NSNotFound)
    {
       readPart=true;
       readIDTypeLikeString=[values[readIDTypeIndex] regexQuoteEscapedString];
       [canonicalQuery appendFormat:@"\"readIDType\":\"%@\",",readIDTypeLikeString];
    }

   if (!readPart)
   {
      NSInteger readIndex=[names indexOfObject:@"read"];
      if (readIndex!=NSNotFound)
      {
         NSString *readRegexString=[values[readIndex] regexQuoteEscapedString];
         NSArray *readParts=[readRegexString componentsSeparatedByString:@"^"];
         if (readParts.count>0)
         {
            readInstitutionLikeString=readParts[0];
            [canonicalQuery appendFormat:@"\"readInstitution\":\"%@\",",readInstitutionLikeString];
         }
         if (readParts.count>1)
         {
            readServiceLikeString=readParts[1];
            [canonicalQuery appendFormat:@"\"readService\":\"%@\",",readServiceLikeString];
         }
         if (readParts.count>2)
         {
            readUserLikeString=readParts[2];
            [canonicalQuery appendFormat:@"\"readUser\":\"%@\",",readUserLikeString];
         }
         if (readParts.count>3)
         {
            readIDLikeString=readParts[3];
            [canonicalQuery appendFormat:@"\"readID\":\"%@\",",readIDLikeString];
         }
         if (readParts.count>4)
         {
            readIDTypeLikeString=readParts[4];
            [canonicalQuery appendFormat:@"\"patientSuffix\":\"%@\",",readIDTypeLikeString];
         }
      }
   }

    
#pragma mark 8. SOPClassInStudyString
    
   NSString *SOPClassInStudyRegexpString=nil;
   NSInteger SOPClassInStudyIndex=[names indexOfObject:@"SOPClassInStudy"];
   if (SOPClassInStudyIndex!=NSNotFound)
   {
      if ([DICMTypes isSingleUIString:values[SOPClassInStudyIndex]]) SOPClassInStudyRegexpString=values[SOPClassInStudyIndex];
      [canonicalQuery appendFormat:@"\"SOPClassInStudy\":\"%@\",",SOPClassInStudyRegexpString];
   }

   
#pragma mark 9. ModalityInStudyString
   NSString *ModalityInStudyRegexpString=nil;
   NSInteger ModalityInStudyIndex=[names indexOfObject:@"ModalityInStudy"];
   if (ModalityInStudyIndex!=NSNotFound)
   {
      if ([DICMTypes isSingleCSString:values[ModalityInStudyIndex]]) ModalityInStudyRegexpString=values[ModalityInStudyIndex];
      [canonicalQuery appendFormat:@"\"ModalityInStudy\":\"%@\",",ModalityInStudyRegexpString];
   }

#pragma mark issuer
    
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


#pragma mark series restrictions

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
                 AccessionNumberEqualString,
                 refInstitutionLikeString,
                 refServiceLikeString,
                 refUserLikeString,
                 refIDLikeString,
                 refIDTypeLikeString,
                 readInstitutionLikeString,
                 readServiceLikeString,
                 readUserLikeString,
                 readIDLikeString,
                 readIDTypeLikeString,
                 StudyIDLikeString,
                 PatientIDLikeString,
                 patientFamilyLikeString,
                 patientGivenLikeString,
                 patientMiddleLikeString,
                 patientPrefixLikeString,
                 patientSuffixLikeString,
                 issuerArray,
                 StudyDateArray,
                 SOPClassInStudyRegexpString,
                 ModalityInStudyRegexpString,
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
                 AccessionNumberEqualString,
                 refInstitutionLikeString,
                 refServiceLikeString,
                 refUserLikeString,
                 refIDLikeString,
                 refIDTypeLikeString,
                 readInstitutionLikeString,
                 readServiceLikeString,
                 readUserLikeString,
                 readIDLikeString,
                 readIDTypeLikeString,
                 StudyIDLikeString,
                 PatientIDLikeString,
                 patientFamilyLikeString,
                 patientGivenLikeString,
                 patientMiddleLikeString,
                 patientPrefixLikeString,
                 patientSuffixLikeString,
                 issuerArray,
                 StudyDateArray,
                 SOPClassInStudyRegexpString,
                 ModalityInStudyRegexpString,
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
                    AccessionNumberEqualString,
                    refInstitutionLikeString,
                    refServiceLikeString,
                    refUserLikeString,
                    refIDLikeString,
                    refIDTypeLikeString,
                    readInstitutionLikeString,
                    readServiceLikeString,
                    readUserLikeString,
                    readIDLikeString,
                    readIDTypeLikeString,
                    StudyIDLikeString,
                    PatientIDLikeString,
                    patientFamilyLikeString,
                    patientGivenLikeString,
                    patientMiddleLikeString,
                    patientPrefixLikeString,
                    patientSuffixLikeString,
                    issuerArray,
                    StudyDateArray,
                    SOPClassInStudyRegexpString,
                    ModalityInStudyRegexpString,
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
                    AccessionNumberEqualString,
                    refInstitutionLikeString,
                    refServiceLikeString,
                    refUserLikeString,
                    refIDLikeString,
                    refIDTypeLikeString,
                    readInstitutionLikeString,
                    readServiceLikeString,
                    readUserLikeString,
                    readIDLikeString,
                    readIDTypeLikeString,
                    StudyIDLikeString,
                    PatientIDLikeString,
                    patientFamilyLikeString,
                    patientGivenLikeString,
                    patientMiddleLikeString,
                    patientPrefixLikeString,
                    patientSuffixLikeString,
                    issuerArray,
                    StudyDateArray,
                    SOPClassInStudyRegexpString,
                    ModalityInStudyRegexpString,
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
