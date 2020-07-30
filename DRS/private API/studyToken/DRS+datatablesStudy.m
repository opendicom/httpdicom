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

#pragma mark filter by E.access_control_id
       NSMutableString *access_control_id_filter=[NSMutableString string];
       if (d[@"aet"] && d[@"custodiantitle"])
       {
       if ([d[@"aet"] isEqualToString:d[@"custodiantitle"]])
        {
           /*
            [studiesWhere appendFormat:
            @" AND E.access_control_id in %@",
            custodianTitlesaetsStrings[q[@"custodiantitle"]]
            ];
            */
        }
        else
        {
            [access_control_id_filter appendFormat:
            @" AND E.access_control_id in ('%@','%@') ",
            d[@"aet"],
            d[@"custodiantitle"]
            ];
        }
       }
       
      
      NSMutableData * mutableData=[NSMutableData data];
      if (d[@"StudyInstanceUIDRegexpString"])
#pragma mark · Euid
      {
      //six parts: prolog,select,where,and,limit&order,format
         LOG_VERBOSE(sqlDictionary[@"EmatchEui"],
         d[@"StudyInstanceUIDRegexpString"]);
         /*LOG_VERBOSE(@"%@",
                     [NSString stringWithFormat:@"%@\"SELECT COUNT(*) %@%@%@\"",
                      sqlprolog,
                      sqlDictionary[@"Ewhere"],
                      access_control_id_filter,
                      [NSString stringWithFormat:
                       sqlDictionary[@"EmatchEui"],
                       d[@"StudyInstanceUIDRegexpString"]
                       ]
                     ]);
         */
            if (execUTF8Bash(
                sqlcredentials,
                [NSString stringWithFormat:@"%@\"%@%@%@%@%@\"%@",
                 sqlprolog,
                 sqlDictionary[@"Eselect4dt"],
                 sqlDictionary[@"Ewhere"],
                 access_control_id_filter,
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
               LOG_VERBOSE((sqlDictionary[@"EmatchEan"])[issuerNone],
                           d[@"AccessionNumberEqualString"]);
               /*LOG_VERBOSE(@"%@",
                           [NSString stringWithFormat:@"%@\"SELECT COUNT(*) %@%@%@\"",
                            sqlprolog,
                            sqlDictionary[@"Ewhere"],
                            access_control_id_filter,
                            [NSString stringWithFormat:
                               (sqlDictionary[@"EmatchEan"])[issuerNone],
                               d[@"AccessionNumberEqualString"]
                            ]
                           ]);
               */
               if (execUTF8Bash(
                   sqlcredentials,
                   [NSString stringWithFormat:@"%@\"%@%@%@%@%@\"%@",
                     sqlprolog,
                     sqlDictionary[@"Eselect4dt"],
                     sqlDictionary[@"Ewhere"],
                     access_control_id_filter,
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
               LOG_VERBOSE((sqlDictionary[@"EmatchEan"])[issuerLocal],
               d[@"AccessionNumberEqualString"],
               d[@"issuerArray"][0]);
               /*LOG_VERBOSE(@"%@",
                           [NSString stringWithFormat:@"%@\"SELECT COUNT(*) %@%@%@\"",
                            sqlprolog,
                            sqlDictionary[@"Ewhere"],
                            access_control_id_filter,
                            [NSString stringWithFormat:
                                (sqlDictionary[@"EmatchEan"])[issuerLocal],
                                d[@"AccessionNumberEqualString"],
                                d[@"issuerArray"][0]
                             ]
                            ]);
                */
               if (execUTF8Bash(
                   sqlcredentials,
                   [NSString stringWithFormat:@"%@\"%@%@%@%@%@\"%@",
                     sqlprolog,
                     sqlDictionary[@"Eselect4dt"],
                     sqlDictionary[@"Ewhere"],
                     access_control_id_filter,
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
               LOG_VERBOSE((sqlDictionary[@"EmatchEan"])[issuerUniversal],
               d[@"AccessionNumberEqualString"],
               d[@"issuerArray"][1],
               d[@"issuerArray"][2]);
               /*
               LOG_VERBOSE(@"%@",
                           [NSString stringWithFormat:@"%@\"SELECT COUNT(*) %@%@%@\"",
                            sqlprolog,
                            sqlDictionary[@"Ewhere"],
                            access_control_id_filter,
                            [NSString stringWithFormat:
                            (sqlDictionary[@"EmatchEan"])[issuerUniversal],
                            d[@"AccessionNumberEqualString"],
                            d[@"issuerArray"][1],
                            d[@"issuerArray"][2]
                            ]
                            ]);
                */
               if (execUTF8Bash(
                   sqlcredentials,
                   [NSString stringWithFormat:@"%@\"%@%@%@%@%@\"%@",
                    sqlprolog,
                    sqlDictionary[@"Eselect4dt"],
                    sqlDictionary[@"Ewhere"],
                    access_control_id_filter,
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
               LOG_VERBOSE((sqlDictionary[@"EmatchEan"])[issuerDivision],
               d[@"AccessionNumberEqualString"],
               d[@"issuerArray"][0],
               d[@"issuerArray"][1],
               d[@"issuerArray"][2]);
               /*
               LOG_VERBOSE(@"%@",
                           [NSString stringWithFormat:@"%@\"SELECT COUNT(*) %@%@%@\"",
                            sqlprolog,
                            sqlDictionary[@"Ewhere"],
                            access_control_id_filter,
                            [NSString stringWithFormat:
                            (sqlDictionary[@"EmatchEan"])[issuerDivision],
                            d[@"AccessionNumberEqualString"],
                            d[@"issuerArray"][0],
                            d[@"issuerArray"][1],
                            d[@"issuerArray"][2]
                            ]
                            ]);
                */
               if (execUTF8Bash(
                   sqlcredentials,
                   [NSString stringWithFormat:@"%@\"%@%@%@%@%@\"%@",
                    sqlprolog,
                    sqlDictionary[@"Eselect4dt"],
                    sqlDictionary[@"Ewhere"],
                    access_control_id_filter,
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
         
#pragma mark 2 PN
         if (d[@"patientArray"])
         {
            NSArray *patientArray=d[@"patientArray"];
            NSString *compoundFormat=((sqlDictionary[@"Eand"])[EcumulativeFilterPpn])[pnFilterCompound];
            if (compoundFormat.length)
            {
                NSMutableArray *jockerArray=[NSMutableArray array];
                for (NSString *component in patientArray)
                {
                    if (component.length) [jockerArray addObject:component];
                    else [jockerArray addObject:@".*"];
                }
                [filters appendFormat:compoundFormat,[jockerArray componentsJoinedByString:@"\\\\\\\\^"]];
            }
            else
            {
               //DB with pn detailed fields
               NSArray *formats=(sqlDictionary[@"Eand"])[EcumulativeFilterPpn];
               for (NSUInteger i=0;i<patientArray.count;i++)
               {
                  if (patientArray[0] && [patientArray[0] length]) [filters appendFormat:formats[i+1],patientArray[0]];
               }
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
         
/*
#pragma mark 6 ERN
         if (d[@"refArray"])
         {
            NSArray *refArray=d[@"refArray"];
            NSString *compoundFormat=((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterCompound];
            if (compoundFormat.length)
            {
                NSMutableArray *jockerArray=[NSMutableArray array];
                for (NSString *component in refArray)
                {
                    if (component.length) [jockerArray addObject:component];
                    else [jockerArray addObject:@".*"];
                }
                [filters appendFormat:compoundFormat,[jockerArray componentsJoinedByString:@"\\\\\\\\^"]];
            }
            else
            {
               //DB with pn detailed fields
               NSArray *formats=(sqlDictionary[@"Eand"])[EcumulativeFilterRef];
               for (NSUInteger i=0;i<refArray.count;i++)
               {
                  if (refArray[0] && [refArray[0] length]) [filters appendFormat:formats[i+1],refArray[0]];
               }
            }
         }
         
         
#pragma mark 7 ED
         if (d[@"readArray"])
         {
            NSArray *readArray=d[@"readArray"];
            NSString *compoundFormat=((sqlDictionary[@"Eand"])[EcumulativeFilterRead])[pnFilterCompound];
            if (compoundFormat.length)
            {
                NSMutableArray *jockerArray=[NSMutableArray array];
                for (NSString *component in readArray)
                {
                    if (component.length) [jockerArray addObject:component];
                    else [jockerArray addObject:@".*"];
                }
                [filters appendFormat:compoundFormat,[jockerArray componentsJoinedByString:@"\\\\\\\\^"]];
            }
            else
            {
               //DB with pn detailed fields
               NSArray *formats=(sqlDictionary[@"Eand"])[EcumulativeFilterRead];
               for (NSUInteger i=0;i<readArray.count;i++)
               {
                  if (readArray[0] && [readArray[0] length]) [filters appendFormat:formats[i+1],readArray[0]];
               }
            }
         }


#pragma mark 8 EQA (SOPClassesInStudy)
         if (d[@"SOPClassInStudyRegexpString"]) [filters appendFormat:(sqlDictionary[@"Eand"])[EcumulativeFilterEsc],d[@"SOPClassInStudyRegexpString"]];
         

#pragma mark 9 EQA ModalitiesInStudy
         if (d[@"ModalityInStudyRegexpString"])
            {
               [filters appendFormat:(sqlDictionary[@"Eand"])[EcumulativeFilterEmo],d[@"ModalityInStudyRegexpString"]];
            }
 */
         
#pragma mark - execute sql
          //six parts: prolog,select,where,and,limit&order,format
         LOG_VERBOSE(@"%@",filters);
         /*
          LOG_VERBOSE(@"%@",
                      [NSString stringWithFormat:@"%@\"SELECT COUNT(*) %@%@%@\"",
                       sqlprolog,
                       sqlDictionary[@"Ewhere"],
                       access_control_id_filter,
                       filters
                       ]);
          */
          if (execUTF8Bash(
              sqlcredentials,
              [NSString stringWithFormat:@"%@\"%@%@%@%@%@\"%@",
               sqlprolog,
               sqlDictionary[@"Eselect4dt"],
               sqlDictionary[@"Ewhere"],
               access_control_id_filter,
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
