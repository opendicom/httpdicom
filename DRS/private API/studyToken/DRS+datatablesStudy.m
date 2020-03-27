#import "DRS+datatablesStudy.h"
#import "DRS+studyToken.h"

@implementation DRS (datatablesStudy)

+(void)datateblesStudySql4dictionary:(NSDictionary*)d
{
   long long maxCount=0;
   if ([d[@"max"] length]) maxCount=[d[@"max"] longLongValue];

#pragma mark studyArray from cache?
   BOOL doPerformSQL=true;
   NSMutableArray *studyArray=nil;
   
    studyArray=[NSMutableArray arrayWithContentsOfFile:d[@"devOIDPLISTPath"]];
    if (studyArray)
    {
      if (   (studyArray.count==1)
          && [studyArray[0] isKindOfClass:[NSNumber class]]
          && ([studyArray[0] longLongValue] < maxCount)
         )
          [studyArray removeObjectAtIndex:0];
      else
      {
         doPerformSQL=(studyArray.count <= maxCount);
         if (doPerformSQL)
         {
    #pragma mark TODO unverify it if there is no need to repeat the sql query
         }
      }
    }
    else studyArray=[NSMutableArray array];

   if (doPerformSQL)
   {
      
#pragma mark sql init
      NSDictionary *devDict=DRS.pacs[d[@"devOID"]];
      NSDictionary *sqlcredentials=@{devDict[@"sqlcredentials"]:devDict[@"sqlpassword"]};
      NSString *sqlprolog=devDict[@"sqlprolog"];
      NSDictionary *sqlDictionary=DRS.sqls[devDict[@"sqlmap"]];
   
      
      NSMutableData * mutableData=[NSMutableData data];
      if (d[@"StudyInstanceUIDRegexpString"])
#pragma mark · Euid
      {
      //six parts: prolog,select,where,and,limit&order,format
            if (execUTF8Bash(
                sqlcredentials,
                [NSString stringWithFormat:@"%@\"%@%@%@%@\"%@",
                 sqlprolog,
                 d[@"sqlselect"],
                 sqlDictionary[@"Ewhere"],
                 [NSString stringWithFormat:
                  sqlDictionary[@"EmatchEui"],
                  d[@"StudyInstanceUIDRegexpString"]
                  ],
                 @"",
                 sqlRecordTwentyNineUnits
                ],
                mutableData)
                !=0) LOG_WARNING(@"datatablesStudy StudyInstanceUID %@ db error",d[@"StudyInstanceUIDRegexpString"]);
         }
      else if (d[@"AccessionNumberEqualString"])
#pragma mark · EA
      {

         switch ([d[@"issuerArray"] count]) {
               
            case issuerNone:
            {
               if (execUTF8Bash(
                   sqlcredentials,
                   [NSString stringWithFormat:@"%@\"%@%@%@%@\"%@",
                     sqlprolog,
                     d[@"sqlselect"],
                     sqlDictionary[@"Ewhere"],
                     [NSString stringWithFormat:
                        (sqlDictionary[@"EmatchEan"])[issuerNone],
                        d[@"AccessionNumberEqualString"]
                     ],
                     @"",
                     sqlRecordTwentyNineUnits
                     ],
                     mutableData)
                   !=0) LOG_WARNING(@"studyToken accessionNumber db error. AN='%@' issuer='%@'",d[@"AccessionNumberEqualString"],[d[@"issuerArray"] componentsJoinedByString:@"^"]);
               } break;

            case issuerLocal:
            {
               if (execUTF8Bash(
                   sqlcredentials,
                   [NSString stringWithFormat:@"%@\"%@%@%@%@\"%@",
                     sqlprolog,
                     d[@"sqlselect"],
                     sqlDictionary[@"Ewhere"],
                     [NSString stringWithFormat:
                        (sqlDictionary[@"EmatchEan"])[issuerLocal],
                        d[@"AccessionNumberEqualString"],
                        d[@"issuerArray"][0]
                     ],
                     @"",
                     sqlRecordTwentyNineUnits
                    ],
                    mutableData)
                   !=0) LOG_WARNING(@"studyToken accessionNumber db error. AN='%@' issuer='%@'",d[@"AccessionNumberEqualString"],[d[@"issuerArray"] componentsJoinedByString:@"^"]);
            } break;
                     
            case issuerUniversal:
            {
               if (execUTF8Bash(
                   sqlcredentials,
                   [NSString stringWithFormat:@"%@\"%@%@%@%@\"%@",
                    sqlprolog,
                    d[@"sqlselect"],
                    sqlDictionary[@"Ewhere"],
                    [NSString stringWithFormat:
                     (sqlDictionary[@"EmatchEan"])[issuerUniversal],
                     d[@"AccessionNumberEqualString"],
                     d[@"issuerArray"][1],
                     d[@"issuerArray"][2]
                     ],
                    @"",
                    sqlRecordTwentyNineUnits
                    ],
                   mutableData)
                  !=0) LOG_WARNING(@"studyToken accessionNumber db error. AN='%@' issuer='%@'",d[@"AccessionNumberEqualString"],[d[@"issuerArray"] componentsJoinedByString:@"^"]);
            } break;

                        
            case issuerDivision:
            {
               if (execUTF8Bash(
                   sqlcredentials,
                   [NSString stringWithFormat:@"%@\"%@%@%@%@\"%@",
                    sqlprolog,
                    d[@"sqlselect"],
                    sqlDictionary[@"Ewhere"],
                    [NSString stringWithFormat:
                     (sqlDictionary[@"EmatchEan"])[issuerDivision],
                     d[@"AccessionNumberEqualString"],
                     d[@"issuerArray"][0],
                     d[@"issuerArray"][1],
                     d[@"issuerArray"][2]
                     ],
                    @"",
                    sqlTwoPks
                    ],
                    mutableData)
                  !=0) LOG_WARNING(@"studyToken accessionNumber db error. AN='%@' issuer='%@'",d[@"AccessionNumberEqualString"],[d[@"issuerArray"] componentsJoinedByString:@"^"]);
            } break;

            default:
               LOG_WARNING(@"studyToken accessionNumber issuer error '%@'",[d[@"issuerArray"] componentsJoinedByString:@"^"]);
               break;
         }
      }
      else
      {
         NSMutableString *filters=[NSMutableString string];
         
         if (d[@"PatientIDLikeString"])
#pragma mark 1 PI
         {
            switch ([d[@"issuerArray"] count]) {
                  
               case issuerNone:
                  [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPid])[issuerNone],d[@"PatientIDLikeString"]];
                  break;

               case issuerLocal:
                  [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPid])[issuerLocal],d[@"PatientIDLikeString"],d[@"issuerArray"][0]];
                  break;

               default:
                  LOG_WARNING(@"studyToken patientID issuer error '%@'",[d[@"issuerArray"] componentsJoinedByString:@"^"]);
                  break;
            }
         }
         

         if (   d[@"patientFamilyLikeString"]
             || d[@"patientGivenLikeString"]
             || d[@"patientMiddleLikeString"]
             || d[@"patientPrefixLikeString"]
             || d[@"patientSuffixLikeString"]
             )
#pragma mark 2 PN
         {
             NSString *pnFilterCompoundString=((sqlDictionary[@"Eand"])[EcumulativeFilterPpn])[pnFilterCompound];
            if (![pnFilterCompoundString isEqualToString:@""])
            {
               // DB with pn compound field
               NSString *regexp=nil;
               if (d[@"patientSuffixLikeString"])
                  regexp=[NSString stringWithFormat:@"%@^%@^%@^%@^%@",
                  d[@"patientFamilyLikeString"]?d[@"patientFamilyLikeString"]:@"",
                  d[@"patientGivenLikeString"]?d[@"patientGivenLikeString"]:@"",
                  d[@"patientMiddleLikeString"]?d[@"patientMiddleLikeString"]:@"",
                  d[@"patientPrefixLikeString"]?d[@"patientPrefixLikeString"]:@"",
                  d[@"patientSuffixLikeString"]];
               else if (d[@"patientPrefixLikeString"])
                  regexp=[NSString stringWithFormat:@"%@^%@^%@^%@",
                  d[@"patientFamilyLikeString"]?d[@"patientFamilyLikeString"]:@"",
                  d[@"patientGivenLikeString"]?d[@"patientGivenLikeString"]:@"",
                  d[@"patientMiddleLikeString"]?d[@"patientMiddleLikeString"]:@"",
                  d[@"patientPrefixLikeString"]];
               else if (d[@"patientMiddleLikeString"])
                  regexp=[NSString stringWithFormat:@"%@^%@^%@",
                  d[@"patientFamilyLikeString"]?d[@"patientFamilyLikeString"]:@"",
                  d[@"patientGivenLikeString"]?d[@"patientGivenLikeString"]:@"",
                  d[@"patientMiddleLikeString"]];
               else if (d[@"patientGivenLikeString"])
                  regexp=[NSString stringWithFormat:@"%@^%@",
                  d[@"patientFamilyLikeString"]?d[@"patientFamilyLikeString"]:@"",
                  d[@"patientGivenLikeString"]];
               else if (d[@"patientFamilyLikeString"])
                  regexp=[NSString stringWithString:d[@"patientFamilyLikeString"]];
               
               if (regexp) [filters appendFormat:pnFilterCompoundString,regexp];
            }
            else
            {
               //DB with pn detailed fields
               if (d[@"patientFamilyLikeString"]) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPpn])[pnFilterFamily],d[@"patientFamilyLikeString"]];
               if (d[@"patientGivenLikeString"]) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPpn])[pnFilterGiven],d[@"patientGivenLikeString"]];
               if (d[@"patientMiddleLikeString"]) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPpn])[pnFilterMiddle],d[@"patientMiddleLikeString"]];
               if (d[@"patientPrefixLikeString"]) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPpn])[pnFilterPrefix],d[@"patientPrefixLikeString"]];
               if (d[@"patientSuffixLikeString"]) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPpn])[pnFilterSuffix],d[@"patientSuffixLikeString"]];
            }

         }
         
#pragma mark 3 Eid
         if (d[@"StudyIDLikeString"]) [filters appendFormat:(sqlDictionary[@"Eand"])[EcumulativeFilterEid],d[@"StudyIDLikeString"]];

#pragma mark 4 Eda
         if (d[@"StudyDateArray"])
         {
            NSArray *Eda=nil;
            BOOL isoMatching=true;
            if ([((sqlDictionary[@"Eand"])[EcumulativeFilterEda])[0] count])
            {
                //isoMatching
                Eda=((sqlDictionary[@"Eand"])[EcumulativeFilterEda])[0];
            }
            else
            {
                isoMatching=false;//dicom DA matching
                Eda=((sqlDictionary[@"Eand"])[EcumulativeFilterEda])[1];
            }
            switch ([d[@"StudyDateArray"] count]) {
               case dateMatchAny:
                  break;
               case dateMatchOn:
               {
                  [filters appendFormat:Eda[dateMatchOn],
                   isoMatching?d[@"StudyDateArray"][0]:[DICMTypes DAStringFromDAISOString:d[@"StudyDateArray"][0]]
                   ];
               } break;
               case dateMatchSince:
               {
                  [filters appendFormat:Eda[dateMatchSince],
                   isoMatching?d[@"StudyDateArray"][0]:[DICMTypes DAStringFromDAISOString:d[@"StudyDateArray"][0]]
                   ];
               } break;
               case dateMatchUntil:
               {
                  [filters appendFormat:Eda[dateMatchUntil],
                   isoMatching?d[@"StudyDateArray"][2]:[DICMTypes DAStringFromDAISOString:d[@"StudyDateArray"][2]]
                   ];

               } break;
               case dateMatchBetween:
               {
                  [filters appendFormat:Eda[dateMatchBetween],
                   isoMatching?(d[@"StudyDateArray"])[0]:[DICMTypes DAStringFromDAISOString:d[@"StudyDateArray"][0]],
                   isoMatching?d[@"StudyDateArray"][3]:[DICMTypes DAStringFromDAISOString:d[@"StudyDateArray"][3]]
                   ];

               } break;
            }
         }


#pragma mark 5 Edesc
         if (d[@"StudyDescriptionRegexpString"]) [filters appendFormat:(sqlDictionary[@"Eand"])[EcumulativeFilterElo],d[@"StudyDescriptionRegexpString"]];
         
         
#pragma mark 6 ERN
         if (   d[@"refInstitutionLikeString"]
             || d[@"refServiceLikeString"]
             || d[@"refUserLikeString"]
             || d[@"refIDLikeString"]
             || d[@"refIDTypeLikeString"]
             )
         {
            NSString *pnFilterCompoundString=((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterCompound];
            if (![d[@"pnFilterCompoundString"] isEqualToString:@""])
            {
               // DB with pn compound field
               NSString *regexp=nil;
               if (d[@"refIDTypeLikeString"])
                  regexp=[NSString stringWithFormat:@"%@^%@^%@^%@^%@",
                  d[@"refInstitutionLikeString"]?d[@"refInstitutionLikeString"]:@"",
                  d[@"refServiceLikeString"]?d[@"refServiceLikeString"]:@"",
                  d[@"refUserLikeString"]?d[@"refUserLikeString"]:@"",
                  d[@"refIDLikeString"]?d[@"refIDLikeString"]:@"",
                  d[@"refIDTypeLikeString"]];
               else if (d[@"refIDLikeString"])
                  regexp=[NSString stringWithFormat:@"%@^%@^%@^%@",
                  d[@"refInstitutionLikeString"]?d[@"refInstitutionLikeString"]:@"",
                  d[@"refServiceLikeString"]?d[@"refServiceLikeString"]:@"",
                  d[@"refUserLikeString"]?d[@"refUserLikeString"]:@"",
                  d[@"refIDLikeString"]];
               else if (d[@"refUserLikeString"])
                  regexp=[NSString stringWithFormat:@"%@^%@^%@",
                  d[@"refInstitutionLikeString"]?d[@"refInstitutionLikeString"]:@"",
                  d[@"refServiceLikeString"]?d[@"refServiceLikeString"]:@"",
                  d[@"refUserLikeString"]];
               else if (d[@"refServiceLikeString"])
                  regexp=[NSString stringWithFormat:@"%@^%@",
                  d[@"refInstitutionLikeString"]?d[@"refInstitutionLikeString"]:@"",
                  d[@"refServiceLikeString"]];
               else if (d[@"refInstitutionLikeString"])
                  regexp=[NSString stringWithString:d[@"refInstitutionLikeString"]];
               
               if (regexp) [filters appendFormat:pnFilterCompoundString,regexp];
            }
            else
            {
               //DB with pn detailed fields
               if (d[@"refInstitutionLikeString"]) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterFamily],d[@"refInstitutionLikeString"]];
               if (d[@"refServiceLikeString"]) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterGiven],d[@"refServiceLikeString"]];
               if (d[@"refUserLikeString"]) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterGiven],d[@"refUserLikeString"]];
               if (d[@"refIDLikeString"]) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterGiven],d[@"refIDLikeString"]];
               if (d[@"refIDTypeLikeString"]) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterGiven],d[@"refIDTypeLikeString"]];
            }
         }
         
         
#pragma mark 7 ED
         if (   d[@"readInstitutionLikeString"]
             || d[@"readServiceLikeString"]
             || d[@"readUserLikeString"]
             || d[@"readIDLikeString"]
             || d[@"readIDTypeLikeString"]
             )
         {
            NSString *pnFilterCompoundString=((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterCompound];
            if (![d[@"pnFilterCompoundString"] isEqualToString:@""])
            {
               // DB with pn compound field
               NSString *regexp=nil;
               if (d[@"readIDTypeLikeString"])
                  regexp=[NSString stringWithFormat:@"%@^%@^%@^%@^%@",
                  d[@"readInstitutionLikeString"]?d[@"readInstitutionLikeString"]:@"",
                  d[@"readServiceLikeString"]?d[@"readServiceLikeString"]:@"",
                  d[@"readUserLikeString"]?d[@"readUserLikeString"]:@"",
                  d[@"readIDLikeString"]?d[@"readIDLikeString"]:@"",
                  d[@"readIDTypeLikeString"]];
               else if (d[@"readIDLikeString"])
                  regexp=[NSString stringWithFormat:@"%@^%@^%@^%@",
                  d[@"readInstitutionLikeString"]?d[@"readInstitutionLikeString"]:@"",
                  d[@"readServiceLikeString"]?d[@"readServiceLikeString"]:@"",
                  d[@"readUserLikeString"]?d[@"readUserLikeString"]:@"",
                  d[@"readIDLikeString"]];
               else if (d[@"readUserLikeString"])
                  regexp=[NSString stringWithFormat:@"%@^%@^%@",
                  d[@"readInstitutionLikeString"]?d[@"readInstitutionLikeString"]:@"",
                  d[@"readServiceLikeString"]?d[@"readServiceLikeString"]:@"",
                  d[@"readUserLikeString"]];
               else if (d[@"readServiceLikeString"])
                  regexp=[NSString stringWithFormat:@"%@^%@",
                  d[@"readInstitutionLikeString"]?d[@"readInstitutionLikeString"]:@"",
                  d[@"readServiceLikeString"]];
               else if (d[@"readInstitutionLikeString"])
                  regexp=[NSString stringWithString:d[@"readInstitutionLikeString"]];
               
               if (regexp) [filters appendFormat:pnFilterCompoundString,regexp];
            }
            else
            {
               //DB with pn detailed fields
               if (d[@"readInstitutionLikeString"]) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterFamily],d[@"readInstitutionLikeString"]];
               if (d[@"readServiceLikeString"]) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterGiven],d[@"readServiceLikeString"]];
               if (d[@"readUserLikeString"]) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterGiven],d[@"readUserLikeString"]];
               if (d[@"readIDLikeString"]) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterGiven],d[@"readIDLikeString"]];
               if (d[@"readIDTypeLikeString"]) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterGiven],d[@"readIDTypeLikeString"]];
            }
         }


#pragma mark 8 EQA (SOPClassesInStudy)
         if (d[@"SOPClassInStudyRegexpString"]) [filters appendFormat:(sqlDictionary[@"Eand"])[EcumulativeFilterEsc],d[@"SOPClassInStudyRegexpString"]];
         
         
#pragma mark 9 EQA ModalitiesInStudy
         if (d[@"ModalityInStudyRegexpString"])
            {
               [filters appendFormat:(sqlDictionary[@"Eand"])[EcumulativeFilterEmo],d[@"SOPClassInStudyRegexpString"]];
            }
#pragma mark - execute sql
          //six parts: prolog,select,where,and,limit&order,format
          if (execUTF8Bash(
              sqlcredentials,
              [NSString stringWithFormat:@"%@\"%@%@%@%@\"%@",
               sqlprolog,
               sqlDictionary[@"Eselect4dt"],
               sqlDictionary[@"Ewhere"],
               filters,
               @"",
               sqlRecordTwentyNineUnits
              ],
              mutableData)
              !=0) LOG_WARNING(@"studyToken StudyInstanceUID %@ db error",d[@"StudyInstanceUIDRegexpString"]);

         
       }

       if ([mutableData length])
       {
           NSArray *dtE=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding stringUnitsPostProcessTitle:@"replaceCacheInstitution" dictionary:@{@"_institution_":d[@"devOID"], @"_cache_":[[d[@"devOIDPLISTPath"] stringByDeletingLastPathComponent]lastPathComponent]} orderedByUnitIndex:dtPN decreasing:NO];//NSUTF8StringEncoding

          if (dtE.count)
          {
             if (maxCount < dtE.count) [[[NSString stringWithFormat:@"[%lu]",(unsigned long)dtE.count] dataUsingEncoding:NSUTF8StringEncoding] writeToFile:d[@"devOIDPLISTPath"] atomically:YES];
             else [dtE writeToFile:d[@"devOIDPLISTPath"] atomically:YES];
          }
      }
   }//doPerformSQL
}
@end
