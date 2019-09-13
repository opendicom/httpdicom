#import "DRS+studyToken.h"
#import "LFCGzipUtility.h"
#import "DICMTypes.h"
#import "NSData+PCS.h"
#import "WeasisManifest.h"
#import "WeasisArcQuery.h"
#import "WeasisPatient.h"
#import "WeasisStudy.h"
#import "WeasisSeries.h"
#import "WeasisInstance.h"

#pragma mark enums

enum accessType{
   accessTypeWeasis,
   accessTypeCornerstone,
   accessTypeDicomzip,
   accessTypeOsirix,
   accessTypeDatatablesSeries,
   accessTypeDatatablesPatient
   
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

#pragma mark static

static uint32 zipLocalFileHeader=0x04034B50;
static uint16 zipVersion=0x0A;
static uint32 zipNameLength=0x28;
static uint32 zipFileHeader=0x02014B50;
static uint32 zipEndOfCentralDirectory=0x06054B50;


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

static NSString *sqlRecordTenUnits=@"\" | awk -F\\t ' BEGIN{ ORS=\"\\x1E\\x0A\";OFS=\"\\x1F\\x7C\";}{print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10}'";


//prolog
//filters...(including eventual IOCM
//limit (or anything else in the MYSQL SELECT after filters)
//epilog


#pragma mark - E functions

RSResponse * sqlEP(
 NSMutableDictionary * EPDict,
 NSDictionary        * sqlcredentials,
 NSDictionary        * sqlDictionary,
 NSString            * sqlprolog,
 NSArray             * StudyInstanceUIDArray,
 NSString            * AccessionNumberString,
 NSString            * PatientIDString,
 NSString            * issuerString,
 NSArray             * StudyDateArray
)
{
   NSMutableData * mutableData=[NSMutableData data];
   
   if (StudyInstanceUIDArray)
   {
      for (NSString *uid in StudyInstanceUIDArray)
      {
         //find patient fk
         if (execUTF8Bash(sqlcredentials,
                           [NSString stringWithFormat:
                            sqlDictionary[@"sqlPE4Eui"],
                            sqlprolog,
                            uid,
                            @"",
                            sqlTwoPks
                            ],
                           mutableData)
             !=0)
         {
            LOG_ERROR(@"studyToken StudyInstanceUID %@ db error",uid);
            continue;
         }
         if ([mutableData length]==0)
         {
            LOG_VERBOSE(@"studyToken StudyInstanceUID %@ empty response",uid);
            continue;
         }
         NSString *EPString=[[[NSString alloc]initWithData:mutableData encoding:NSUTF8StringEncoding] stringByDeletingLastPathComponent];//record terminated by /
         [EPDict setObject:[EPString pathExtension] forKey:[EPString stringByDeletingPathExtension]];
         [mutableData setLength:0];
      }
   }
   else //AccessionNumber or PatientID + StudyDate
   {
       if (AccessionNumberString)
       {
          if (execUTF8Bash(sqlcredentials,
                            [NSString stringWithFormat:
                             sqlDictionary[@"sqlPE4Ean"],
                             sqlprolog,
                             AccessionNumberString,
                             @"",
                             sqlTwoPks
                             ],
                            mutableData)
              !=0)
          {
             LOG_ERROR(@"studyToken accessionNumber db error");
             return nil;//ignoring this node but not responding with an error
          }
       }
       else if (PatientIDString)
       {
           if (issuerString)
           {
              switch (StudyDateArray.count) {
                 case dateMatchAny:
                    {
                       if (execUTF8Bash(sqlcredentials,
                                        [NSString stringWithFormat:
                                         sqlDictionary[@"sqlEP4PidisEda0"],
                                         sqlprolog,
                                         PatientIDString,
                                         issuerString,
                                         @"",
                                         sqlTwoPks
                                         ],
                                        mutableData)
                           !=0)
                       {
                           LOG_ERROR(@"studyToken sqlEP4PidisEda0");
                           return nil;//ignoring this node but not responding with an error
                       }
                    }
                    break;

                 case dateMatchOn:
                    {
                       if (execUTF8Bash(sqlcredentials,
                                        [NSString stringWithFormat:
                                         sqlDictionary[@"sqlEP4PidisEda1"],
                                         sqlprolog,
                                         PatientIDString,
                                         issuerString,
                                         StudyDateArray[0],
                                         @"",
                                         sqlTwoPks
                                         ],
                                        mutableData)
                           !=0)
                       {
                           LOG_ERROR(@"studyToken sqlEP4PidisEda1");
                           return nil;//ignoring this node but not responding with an error
                       }
                    }
                    break;

                 case dateMatchSince:
                    {
                       if (execUTF8Bash(sqlcredentials,
                                        [NSString stringWithFormat:
                                         sqlDictionary[@"sqlEP4PidisEda2"],
                                         sqlprolog,
                                         PatientIDString,
                                         issuerString,
                                         StudyDateArray[0],
                                         @"",
                                         sqlTwoPks
                                         ],
                                        mutableData)
                           !=0)
                       {
                           LOG_ERROR(@"studyToken sqlEP4PidisEda2");
                           return nil;//ignoring this node but not responding with an error
                       }
                    }
                    break;

                 case dateMatchUntil:
                    {
                       if (execUTF8Bash(sqlcredentials,
                                        [NSString stringWithFormat:
                                         sqlDictionary[@"sqlEP4PidisEda3"],
                                         sqlprolog,
                                         PatientIDString,
                                         issuerString,
                                         StudyDateArray[2],
                                         @"",
                                         sqlTwoPks
                                         ],
                                        mutableData)
                           !=0)
                       {
                           LOG_ERROR(@"studyToken sqlEP4PidisEda3");
                           return nil;//ignoring this node but not responding with an error
                       }
                    }
                    break;

                 case dateMatchBetween:
                    {
                       if (execUTF8Bash(sqlcredentials,
                                        [NSString stringWithFormat:
                                         sqlDictionary[@"sqlEP4PidisEda4"],
                                         sqlprolog,
                                         PatientIDString,
                                         issuerString,
                                         StudyDateArray[0],
                                         StudyDateArray[3],
                                         @"",
                                         sqlTwoPks
                                         ],
                                        mutableData)
                           !=0)
                       {
                           LOG_ERROR(@"studyToken sqlEP4PidisEda4");
                           return nil;//ignoring this node but not responding with an error
                       }
                    }
                    break;
              }
           }
          else //no issuer
          {
             switch (StudyDateArray.count) {
                case dateMatchAny:
                   {
                      if (execUTF8Bash(sqlcredentials,
                                       [NSString stringWithFormat:
                                        sqlDictionary[@"sqlEP4PidEda0"],
                                        sqlprolog,
                                        PatientIDString,
                                        @"",
                                        sqlTwoPks
                                        ],
                                       mutableData)
                          !=0)
                      {
                          LOG_ERROR(@"studyToken sqlEP4PidEda0");
                          return nil;//ignoring this node but not responding with an error
                      }
                   }
                   break;

                case dateMatchOn:
                   {
                      if (execUTF8Bash(sqlcredentials,
                                       [NSString stringWithFormat:
                                        sqlDictionary[@"sqlEP4PidEda1"],
                                        sqlprolog,
                                        PatientIDString,
                                        StudyDateArray[0],
                                        @"",
                                        sqlTwoPks
                                        ],
                                       mutableData)
                          !=0)
                      {
                          LOG_ERROR(@"studyToken sqlEP4PidEda1");
                          return nil;//ignoring this node but not responding with an error
                      }
                   }
                   break;

                case dateMatchSince:
                   {
                      if (execUTF8Bash(sqlcredentials,
                                       [NSString stringWithFormat:
                                        sqlDictionary[@"sqlEP4PidEda2"],
                                        sqlprolog,
                                        PatientIDString,
                                        StudyDateArray[0],
                                        @"",
                                        sqlTwoPks
                                        ],
                                       mutableData)
                          !=0)
                      {
                          LOG_ERROR(@"studyToken sqlEP4PidEda2");
                          return nil;//ignoring this node but not responding with an error
                      }
                   }
                   break;

                case dateMatchUntil:
                   {
                      if (execUTF8Bash(sqlcredentials,
                                       [NSString stringWithFormat:
                                        sqlDictionary[@"sqlEP4PidEda3"],
                                        sqlprolog,
                                        PatientIDString,
                                        StudyDateArray[2],
                                        @"",
                                        sqlTwoPks
                                        ],
                                       mutableData)
                          !=0)
                      {
                          LOG_ERROR(@"studyToken sqlEP4PidEda3");
                          return nil;//ignoring this node but not responding with an error
                      }
                   }
                   break;

                case dateMatchBetween:
                   {
                      if (execUTF8Bash(sqlcredentials,
                                       [NSString stringWithFormat:
                                        sqlDictionary[@"sqlEP4PidEda4"],
                                        sqlprolog,
                                        PatientIDString,
                                        StudyDateArray[0],
                                        StudyDateArray[3],
                                        @"",
                                        sqlTwoPks
                                        ],
                                       mutableData)
                          !=0)
                      {
                          LOG_ERROR(@"studyToken sqlEP4PidEda4");
                          return nil;//ignoring this node but not responding with an error
                      }
                   }
                   break;
             }

          }
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
   }

   return nil;
}


RSResponse * sqlEuiE(
 NSMutableDictionary * EuiEDict,
 NSDictionary        * sqlcredentials,
 NSDictionary        * sqlDictionary,
 NSString            * sqlprolog,
 NSArray             * StudyInstanceUIDArray,
 NSString            * AccessionNumberString,
 NSString            * PatientIDString,
 NSString            * issuerString,
 NSArray             * StudyDateArray
)
{
   NSMutableData * mutableData=[NSMutableData data];
   
   if (StudyInstanceUIDArray)
   {
      for (NSString *uid in StudyInstanceUIDArray)
      {
         //find patient fk
         if (execUTF8Bash(sqlcredentials,
                           [NSString stringWithFormat:
                            sqlDictionary[@"sqlEuiE4Euid"],
                            sqlprolog,
                            uid,
                            @"",
                            sqlTwoPks
                            ],
                           mutableData)
             !=0)
         {
            LOG_ERROR(@"studyToken StudyInstanceUID %@ db error",uid);
            continue;
         }
         if ([mutableData length]==0)
         {
            LOG_VERBOSE(@"studyToken StudyInstanceUID %@ empty response",uid);
            continue;
         }
         NSString *EuiEString=[[[NSString alloc]initWithData:mutableData encoding:NSUTF8StringEncoding] stringByDeletingLastPathComponent];//record terminated by /
         [EuiEDict setObject:[EuiEString pathExtension] forKey:[EuiEString stringByDeletingPathExtension]];
         [mutableData setLength:0];
      }
   }
   else //AccessionNumber or PatientID + StudyDate
   {
       if (AccessionNumberString)
       {
          if (execUTF8Bash(sqlcredentials,
                            [NSString stringWithFormat:
                             sqlDictionary[@"sqlEuiE4Ean"],
                             sqlprolog,
                             AccessionNumberString,
                             @"",
                             sqlTwoPks
                             ],
                            mutableData)
              !=0)
          {
             LOG_ERROR(@"studyToken accessionNumber db error");
             return nil;//ignoring this node but not responding with an error
          }
       }
       else if (PatientIDString)
       {
           if (issuerString)
           {
              switch (StudyDateArray.count) {
                 case dateMatchAny:
                    {
                       if (execUTF8Bash(sqlcredentials,
                                        [NSString stringWithFormat:
                                         sqlDictionary[@"sqlEuiE4PidisEda0"],
                                         sqlprolog,
                                         PatientIDString,
                                         issuerString,
                                         @"",
                                         sqlTwoPks
                                         ],
                                        mutableData)
                           !=0)
                       {
                           LOG_ERROR(@"studyToken sqlEuiE4PidisEda0");
                           return nil;//ignoring this node but not responding with an error
                       }
                    }
                    break;

                 case dateMatchOn:
                    {
                       if (execUTF8Bash(sqlcredentials,
                                        [NSString stringWithFormat:
                                         sqlDictionary[@"sqlEuiE4PidisEda1"],
                                         sqlprolog,
                                         PatientIDString,
                                         issuerString,
                                         StudyDateArray[0],
                                         @"",
                                         sqlTwoPks
                                         ],
                                        mutableData)
                           !=0)
                       {
                           LOG_ERROR(@"studyToken sqlEuiE4PidisEda1");
                           return nil;//ignoring this node but not responding with an error
                       }
                    }
                    break;

                 case dateMatchSince:
                    {
                       if (execUTF8Bash(sqlcredentials,
                                        [NSString stringWithFormat:
                                         sqlDictionary[@"sqlEuiE4PidisEda2"],
                                         sqlprolog,
                                         PatientIDString,
                                         issuerString,
                                         StudyDateArray[0],
                                         @"",
                                         sqlTwoPks
                                         ],
                                        mutableData)
                           !=0)
                       {
                           LOG_ERROR(@"studyToken sqlEuiE4PidisEda2");
                           return nil;//ignoring this node but not responding with an error
                       }
                    }
                    break;

                 case dateMatchUntil:
                    {
                       if (execUTF8Bash(sqlcredentials,
                                        [NSString stringWithFormat:
                                         sqlDictionary[@"sqlEuiE4PidisEda3"],
                                         sqlprolog,
                                         PatientIDString,
                                         issuerString,
                                         StudyDateArray[2],
                                         @"",
                                         sqlTwoPks
                                         ],
                                        mutableData)
                           !=0)
                       {
                           LOG_ERROR(@"studyToken sqlEuiE4PidisEda3");
                           return nil;//ignoring this node but not responding with an error
                       }
                    }
                    break;

                 case dateMatchBetween:
                    {
                       if (execUTF8Bash(sqlcredentials,
                                        [NSString stringWithFormat:
                                         sqlDictionary[@"sqlEuiE4PidisEda4"],
                                         sqlprolog,
                                         PatientIDString,
                                         issuerString,
                                         StudyDateArray[0],
                                         StudyDateArray[3],
                                         @"",
                                         sqlTwoPks
                                         ],
                                        mutableData)
                           !=0)
                       {
                           LOG_ERROR(@"studyToken sqlEuiE4PidisEda4");
                           return nil;//ignoring this node but not responding with an error
                       }
                    }
                    break;
              }
           }
          else //no issuer
          {
             switch (StudyDateArray.count) {
                case dateMatchAny:
                   {
                      if (execUTF8Bash(sqlcredentials,
                                       [NSString stringWithFormat:
                                        sqlDictionary[@"sqlEuiE4PidEda0"],
                                        sqlprolog,
                                        PatientIDString,
                                        @"",
                                        sqlTwoPks
                                        ],
                                       mutableData)
                          !=0)
                      {
                          LOG_ERROR(@"studyToken sqlEuiE4PidEda0");
                          return nil;//ignoring this node but not responding with an error
                      }
                   }
                   break;

                case dateMatchOn:
                   {
                      if (execUTF8Bash(sqlcredentials,
                                       [NSString stringWithFormat:
                                        sqlDictionary[@"sqlEuiE4PidEda1"],
                                        sqlprolog,
                                        PatientIDString,
                                        StudyDateArray[0],
                                        @"",
                                        sqlTwoPks
                                        ],
                                       mutableData)
                          !=0)
                      {
                          LOG_ERROR(@"studyToken sqlEuiE4PidEda1");
                          return nil;//ignoring this node but not responding with an error
                      }
                   }
                   break;

                case dateMatchSince:
                   {
                      if (execUTF8Bash(sqlcredentials,
                                       [NSString stringWithFormat:
                                        sqlDictionary[@"sqlEuiE4PidEda2"],
                                        sqlprolog,
                                        PatientIDString,
                                        StudyDateArray[0],
                                        @"",
                                        sqlTwoPks
                                        ],
                                       mutableData)
                          !=0)
                      {
                          LOG_ERROR(@"studyToken sqlEuiE4PidEda2");
                          return nil;//ignoring this node but not responding with an error
                      }
                   }
                   break;

                case dateMatchUntil:
                   {
                      if (execUTF8Bash(sqlcredentials,
                                       [NSString stringWithFormat:
                                        sqlDictionary[@"sqlEuiE4PidEda3"],
                                        sqlprolog,
                                        PatientIDString,
                                        StudyDateArray[2],
                                        @"",
                                        sqlTwoPks
                                        ],
                                       mutableData)
                          !=0)
                      {
                          LOG_ERROR(@"studyToken sqlEuiE4PidEda3");
                          return nil;//ignoring this node but not responding with an error
                      }
                   }
                   break;

                case dateMatchBetween:
                   {
                      if (execUTF8Bash(sqlcredentials,
                                       [NSString stringWithFormat:
                                        sqlDictionary[@"sqlEuiE4PidEda4"],
                                        sqlprolog,
                                        PatientIDString,
                                        StudyDateArray[0],
                                        StudyDateArray[3],
                                        @"",
                                        sqlTwoPks
                                        ],
                                       mutableData)
                          !=0)
                      {
                          LOG_ERROR(@"studyToken sqlEuiE4PidEda4");
                          return nil;//ignoring this node but not responding with an error
                      }
                   }
                   break;
             }

          }
       }
   
       if ([mutableData length]==0)
       {
         LOG_VERBOSE(@"studyToken empty response");
         return nil;
       }
       for (NSString *pkdotpk in [[[NSString alloc]initWithData:mutableData encoding:NSUTF8StringEncoding]componentsSeparatedByString:@"/"])
       {
           if (pkdotpk.length) [EuiEDict setObject:[pkdotpk pathExtension] forKey:[pkdotpk stringByDeletingPathExtension]];
       }
       //record terminated by /
   }

   return nil;
}

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
                      @"\""
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
          !(    SeriesInstanceUIDRegex
            && [SeriesInstanceUIDRegex
                numberOfMatchesInString:SProperties[1]
                options:0
                range:NSMakeRange(0, [SProperties[1] length])
                ]
            )
       && !(    SeriesNumberRegex
            && [SeriesNumberRegex
                numberOfMatchesInString:SProperties[3]
                options:0
                range:NSMakeRange(0, [SProperties[3] length])
                ]
            )
       && !(    SeriesDescriptionRegex
            && [SeriesDescriptionRegex
                numberOfMatchesInString:SProperties[2]
                options:0
                range:NSMakeRange(0, [SProperties[2] length])
                ]
            )
       && !(    ModalityRegex
            && [ModalityRegex
                numberOfMatchesInString:SProperties[4]
                options:0
                range:NSMakeRange(0, [SProperties[4] length])
                ]
            )
       && !(    SOPClassRegex
            && [SOPClassRegex
                numberOfMatchesInString:SOPClassString
                options:0
                range:NSMakeRange(0, SOPClassString.length)
                ]
            )
       && !(    SOPClassOffRegex
            &&![SOPClassOffRegex
                numberOfMatchesInString:SOPClassString
                options:0
                range:NSMakeRange(0, SOPClassString.length)
                ]
            )
       ) return SOPClassString;
   return nil;
};

#pragma mark - accessType functions

RSResponse * weasis(
 NSString            * proxyURIString,
 NSString            * sessionString,
 NSMutableArray      * devCustodianOIDArray,
 NSMutableArray      * wanCustodianOIDArray,
 NSString            * transferSyntax,
 BOOL                  hasRestriction,
 NSRegularExpression * SeriesInstanceUIDRegex,
 NSRegularExpression * SeriesNumberRegex,
 NSRegularExpression * SeriesDescriptionRegex,
 NSRegularExpression * ModalityRegex,
 NSRegularExpression * SOPClassRegex,
 NSRegularExpression * SOPClassOffRegex,
 NSArray             * StudyInstanceUIDArray,
 NSString            * AccessionNumberString,
 NSString            * PatientIDString,
 NSArray             * StudyDateArray,
 NSString            * issuerString
)
{
   NSXMLElement *XMLRoot=[WeasisManifest manifest];
            
   if (devCustodianOIDArray.count > 1)
   {
      //add nodes and start corresponding processes
   }

   if (wanCustodianOIDArray.count > 0)
   {
      //add nodes and start corresponding processes
   }

   if (devCustodianOIDArray.count == 0)
   {
      //add nodes and start corresponding processes
   }
   else
   {
      while (1)
      {
         NSString *custodianString=devCustodianOIDArray[0];
         NSDictionary *custodianDict=DRS.pacs[custodianString];

#pragma mark · GET type index
         NSUInteger getTypeIndex=[@[@"file",@"folder",@"wado",@"wadors",@"cget",@"cmove"] indexOfObject:custodianDict[@"get"]];

#pragma mark · SELECT switch
         switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:custodianDict[@"select"]]) {
            
            case NSNotFound:{
               LOG_WARNING(@"studyToken pacs %@ lacks \"select\" type property",custodianString);
            } break;
               
            case selectTypeSql:{
   #pragma mark · SQL SELECT (unique option for now)
               NSDictionary *sqlcredentials=@{custodianDict[@"sqluser"]:custodianDict[@"sqlpassword"]};
               NSString *sqlprolog=custodianDict[@"sqlprolog"];
               NSDictionary *sqlDictionary=DRS.sqls[custodianDict[@"sqlmap"]];

               
#pragma mark · apply EP (Study Patient) filters
               NSMutableDictionary *EPDict=[NSMutableDictionary dictionary];
               RSResponse *sqlEPErrorReturned=sqlEP(
                EPDict,
                sqlcredentials,
                sqlDictionary,
                sqlprolog,
                StudyInstanceUIDArray,
                AccessionNumberString,
                PatientIDString,
                issuerString,
                StudyDateArray
               );
               if (sqlEPErrorReturned) return sqlEPErrorReturned;

               
               NSXMLElement *arcQueryElement=
                     [WeasisArcQuery
                      arcQueryOID:custodianString
                      session:sessionString
                      custodian:proxyURIString
                      transferSyntax:nil
                      seriesInstanceUID:SeriesInstanceUIDRegex.pattern
                      seriesNumber:SeriesNumberRegex.pattern
                      seriesDescription:SeriesDescriptionRegex.pattern
                      modality:ModalityRegex.pattern
                      SOPClass:SOPClassRegex.pattern
                      SOPClassOff:SOPClassOffRegex.pattern
                      overrideDicomTagsList:@""
                      ];
                     [XMLRoot addChild:arcQueryElement];

#pragma mark ·· GET switch
               switch (getTypeIndex) {
                     
                  case NSNotFound:{
                     LOG_WARNING(@"studyToken pacs %@ lacks \"get\" property",custodianString);
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
                                           sqlDictionary[@"sqlP"],
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
                        NSArray *patientPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding
                        PatientElement=
                        [WeasisPatient
                         pk:(patientPropertiesArray[0])[0]
                         pid:(patientPropertiesArray[0])[1]
                         name:(patientPropertiesArray[0])[2]
                         issuer:(patientPropertiesArray[0])[3]
                         birthdate:(patientPropertiesArray[0])[4]
                         sex:(patientPropertiesArray[0])[5]
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
                                                 sqlDictionary[@"sqlE"],
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
                              [WeasisStudy
                               pk:(EPropertiesArray[0])[0]
                               uid:(EPropertiesArray[0])[1]
                               desc:(EPropertiesArray[0])[2]
                               date:[DICMTypes DAStringFromDAISOString:(EPropertiesArray[0])[3]]
                               time:[DICMTypes TMStringFromTMISOString:(EPropertiesArray[0])[4]]
                               an:(EPropertiesArray[0])[5]
                               issuer:nil
                               type:nil
                               eid:(EPropertiesArray[0])[6]
                               ref:(EPropertiesArray[0])[7]
                               img:(EPropertiesArray[0])[8]
                               mod:(EPropertiesArray[0])[9]
                               ];
                              [PatientElement addChild:StudyElement];
                               
                        [mutableData setData:[NSData data]];
                        if (execUTF8Bash(sqlcredentials,
                                          [NSString stringWithFormat:
                                           sqlDictionary[@"sqlS"],
                                           sqlprolog,
                                           E,
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
                           NSString *SOPClass=SOPCLassOfReturnableSeries(
                            sqlcredentials,
                            sqlDictionary[@"sqlIci4S"],
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
                                                 sqlDictionary[@"sqlI"],
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
                              NSXMLElement *SeriesElement=[WeasisSeries
                               pk:SProperties[0]
                               uid:SProperties[1]
                               desc:SProperties[2]
                               num:SProperties[3]
                               mod:SProperties[4]
                               wts:@"*"
                               sop:SOPClass
                              ];//DirectDownloadThumbnail=\"%@\"
                              [StudyElement addChild:SeriesElement];
                                    

   //#pragma mark instance loop
                              for (NSArray *IProperties in IPropertiesArray)
                              {
   //#pragma mark instance loop
                                 NSXMLElement *InstanceElement=[WeasisInstance
                                  pk:IProperties[0]
                                  uid:IProperties[1]
                                  num:IProperties[2]
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
         return
         [RSDataResponse
          responseWithData:[LFCGzipUtility gzipData:[doc XMLData]]
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
 NSString            * proxyURIString,
 NSString            * sessionString,
 NSMutableArray      * devCustodianOIDArray,
 NSMutableArray      * wanCustodianOIDArray,
 NSString            * transferSyntax,
 BOOL                  hasRestriction,
 NSRegularExpression * SeriesInstanceUIDRegex,
 NSRegularExpression * SeriesNumberRegex,
 NSRegularExpression * SeriesDescriptionRegex,
 NSRegularExpression * ModalityRegex,
 NSRegularExpression * SOPClassRegex,
 NSRegularExpression * SOPClassOffRegex,
 NSArray             * StudyInstanceUIDArray,
 NSString            * AccessionNumberString,
 NSString            * PatientIDString,
 NSArray             * StudyDateArray,
 NSString            * issuerString
)
{
      NSMutableArray *JSONArray=[NSMutableArray array];

      if (devCustodianOIDArray.count > 1)
      {
         //add nodes and start corresponding processes
      }

      if (wanCustodianOIDArray.count > 0)
      {
         //add nodes and start corresponding processes
      }

      if (devCustodianOIDArray.count == 0)
      {
         //add nodes and start corresponding processes
      }
      else
      {
         while (1)
         {
            NSString *custodianString=devCustodianOIDArray[0];
            NSDictionary *custodianDict=DRS.pacs[custodianString];

   #pragma mark · GET type index
            NSUInteger getTypeIndex=[@[@"file",@"folder",@"wado",@"wadors",@"cget",@"cmove"] indexOfObject:custodianDict[@"get"]];

   #pragma mark · SELECT switch
            switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:custodianDict[@"select"]]) {
               
               case NSNotFound:{
                  LOG_WARNING(@"studyToken pacs %@ lacks \"select\" type property",custodianString);
               } break;
                  
               case selectTypeSql:{
      #pragma mark · SQL SELECT (unique option for now)
                  NSDictionary *sqlcredentials=@{custodianDict[@"sqluser"]:custodianDict[@"sqlpassword"]};
                  NSString *sqlprolog=custodianDict[@"sqlprolog"];
                  NSDictionary *sqlDictionary=DRS.sqls[custodianDict[@"sqlmap"]];

#pragma mark · apply EP (Study Patient) filters
                  NSMutableDictionary *EPDict=[NSMutableDictionary dictionary];
                  RSResponse *sqlEPErrorReturned=sqlEP(
                   EPDict,
                   sqlcredentials,
                   sqlDictionary,
                   sqlprolog,
                   StudyInstanceUIDArray,
                   AccessionNumberString,
                   PatientIDString,
                   issuerString,
                   StudyDateArray
                  );
                  if (sqlEPErrorReturned) return sqlEPErrorReturned;


                  NSMutableArray *patientArray=[NSMutableArray array];
                  [JSONArray addObject:
                   @{
                     @"arcId":custodianString,
                     @"baseUrl":proxyURIString,
                     @"additionnalParameters":
                        [NSString stringWithFormat:@"&amp;session=%@&amp;custodianOID=%@&amp;SeriesInstanceUID=%@&amp;SeriesNumber=%@&amp;SeriesDescription=%@&amp;Modality=%@&amp;SOPClass=%@&amp;SOPClassOff=%@",
                         sessionString,
                         custodianString,
                         SeriesInstanceUIDRegex.pattern,
                         SeriesNumberRegex.pattern,
                         SeriesDescriptionRegex.pattern,
                         ModalityRegex.pattern,
                         SOPClassRegex.pattern,
                         SOPClassOffRegex.pattern
                        ],
                     @"overrideDicomTagsList":@"",
                     @"patientList":patientArray
                     }
                   ];

   #pragma mark ·· GET switch
                  switch (getTypeIndex) {
                        
                     case NSNotFound:{
                        LOG_WARNING(@"studyToken pacs %@ lacks \"get\" property",custodianString);
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
                                              sqlDictionary[@"sqlP"],
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
                           NSArray *patientPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding
NSMutableArray *studyArray=[NSMutableArray array];
                           [patientArray addObject:
                            @{
                              @"PatientID":(patientPropertiesArray[0])[1],
                              @"PatientName":(patientPropertiesArray[0])[2],
                              @"IssuerOfPatientID":(patientPropertiesArray[0])[3],
                              @"PatientBirthDate":(patientPropertiesArray[0])[4],
                              @"PatientSex":(patientPropertiesArray[0])[5],
                              @"studyList":studyArray
                              }];
                                 

//#pragma mark study loop
                        for (NSString *E in EPDict)
                        {
                           if ([EPDict[E] isEqualToString:P])
                           {
                              [mutableData setData:[NSData data]];
                              if (execUTF8Bash(sqlcredentials,
                                                [NSString stringWithFormat:
                                                 sqlDictionary[@"sqlE"],
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
                              NSArray *EPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:3 decreasing:YES];//NSUTF8StringEncoding
                              
                              /*
                               patientName
                               patientId
                               studyDate
                               modality (in Study)
                               studyDescription
                               numImages
                               studyId
                               */
                              NSMutableArray *seriesArray=[NSMutableArray array];//Study=Exam
                              [studyArray addObject:
                               @{
                                 @"StudyInstanceUID":(EPropertiesArray[0])[1],
                                 @"studyDescription":(EPropertiesArray[0])[2],
                                 @"studyDate":[DICMTypes DAStringFromDAISOString:(EPropertiesArray[0])[3]],
                                 @"StudyTime":[DICMTypes TMStringFromTMISOString:(EPropertiesArray[0])[4]],
                                 @"AccessionNumber":(EPropertiesArray[0])[5],
                                 @"StudyID":(EPropertiesArray[0])[6],
                                 @"ReferringPhysicianName":(EPropertiesArray[0])[7],
                                 @"numImages":(EPropertiesArray[0])[8],
                                 @"modality":(EPropertiesArray[0])[9],
                                 @"patientId":(patientPropertiesArray[0])[1],
                                 @"patientName":(patientPropertiesArray[0])[2],
                                 @"seriesList":seriesArray
                                 }];

                        [mutableData setData:[NSData data]];
                        if (execUTF8Bash(sqlcredentials,
                                          [NSString stringWithFormat:
                                           sqlDictionary[@"sqlS"],
                                           sqlprolog,
                                           E,
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
                           //SOPClassUID check on the first instance
                           [mutableData setData:[NSData data]];
                           if (execUTF8Bash(sqlcredentials,
                                             [NSString stringWithFormat:
                                              sqlDictionary[@"sqlI"],
                                              sqlprolog,
                                              SProperties[0],
                                              @"limit 1",
                                              sqlRecordFourUnits
                                              ],
                                             mutableData)
                               !=0)
                           {
                              LOG_ERROR(@"studyToken study db error");
                              continue;
                           }
                           NSArray *IPropertiesFirstRecord=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding
                           
                                                   
#pragma mark ....series restrictions
//do not add empty series
if ([IPropertiesFirstRecord count]==0) continue;

/*
 //dicom cda
if ([(IPropertiesFirstRecord[0])[3] isEqualToString:@"1.2.840.10008.5.1.4.1.1.104.2"]) continue;
//SR
if ([(IPropertiesFirstRecord[0])[3] hasPrefix:@"1.2.840.10008.5.1.4.1.1.88"])continue;
 
 //replaced by SOPClassOff
*/

//if there is restriction and does't match
if (hasRestriction)
{
    if (
           !(    SeriesInstanceUIDRegex
             && [SeriesInstanceUIDRegex
                 numberOfMatchesInString:SProperties[1]
                 options:0
                 range:NSMakeRange(0, [SProperties[1] length])
                 ]
             )
        && !(    SeriesNumberRegex
             && [SeriesNumberRegex
                 numberOfMatchesInString:SProperties[3]
                 options:0
                 range:NSMakeRange(0, [SProperties[3] length])
                 ]
             )
        && !(    SeriesDescriptionRegex
             && [SeriesDescriptionRegex
                 numberOfMatchesInString:SProperties[2]
                 options:0
                 range:NSMakeRange(0, [SProperties[2] length])
                 ]
             )
        && !(    ModalityRegex
             && [ModalityRegex
                 numberOfMatchesInString:SProperties[4]
                 options:0
                 range:NSMakeRange(0, [SProperties[4] length])
                 ]
             )
        && !(    SOPClassRegex
             && [SOPClassRegex
                 numberOfMatchesInString:(IPropertiesFirstRecord[0])[3]
                 options:0
                 range:NSMakeRange(0, [(IPropertiesFirstRecord[0])[3] length])
                 ]
             )
        && !(    SOPClassOffRegex
             &&![SOPClassOffRegex
                 numberOfMatchesInString:(IPropertiesFirstRecord[0])[3]
                 options:0
                 range:NSMakeRange(0, [(IPropertiesFirstRecord[0])[3] length])
                 ]
             )
        ) continue;
}

                           
                           //instances
                           [mutableData setData:[NSData data]];
                           if (execUTF8Bash(sqlcredentials,
                                             [NSString stringWithFormat:
                                              sqlDictionary[@"sqlI"],
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
                           NSArray *IPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding

   //#pragma mark series loop
                           /*
                            seriesList
                            ==========
                            not for OT nor DOC
                            
                            seriesDescription
                            seriesNumber
                            */
NSMutableArray *instanceArray=[NSMutableArray array];
                           [seriesArray addObject:
                           @{
                             @"seriesDescription":SProperties[2],
                             @"seriesNumber":SProperties[3],
                             @"SeriesInstanceUID":SProperties[1],
                             @"Modality":SProperties[4],
                             @"WadoTransferSyntaxUID":@"*",
                             @"instanceList":instanceArray
                             }];
                                 

   //#pragma mark instance loop
                           for (NSArray *IProperties in IPropertiesArray)
                           {
                              /*
                               instanceList
                               ============
                               imageId = (weasis) DirectDownloadFile
                               
                               SOPInstanceUID
                               InstanceNumber
                               */
                              NSString *wadouriInstance=[NSString stringWithFormat:
                                                         @"%@?requestType=WADO&studyUID=%@&seriesUID=%@&objectUID=%@&session=%@&custodianOID=%@",
                                                         proxyURIString,
                                                         (EPropertiesArray[0])[1],
                                                         SProperties[1],
                                                         IProperties[1],
                                                         sessionString,
                                                         @"2.16.858.0.1.4.0"];
                              [instanceArray addObject:@{
                                                         @"imageId":wadouriInstance,
                                                         @"SOPInstanceUID":IProperties[1],
                                                         @"InstanceNumber":IProperties[2]
                                                         }
                               ];

                                 }//end for each I
                              }// end for each S
                           }//end for each E
                        }//end for each P
                     } break;//end of WADO
                  }// end of GET switch
               } break;//end of sql
            } //end of SELECT switch
            }
            NSData *cornerstoneJson=[NSJSONSerialization dataWithJSONObject:JSONArray options:0 error:nil];
            LOG_DEBUG(@"cornerstone manifest :\r\n%@",[[NSString alloc] initWithData:cornerstoneJson encoding:NSUTF8StringEncoding]);
            return [RSDataResponse responseWithData:cornerstoneJson contentType:@"application/json"];

         }//end while 1

      }//end at least one dev



   return [RSErrorResponse responseWithClientError:404 message:@"studyToken should not be here"];
}


RSResponse* dicomzip(
 NSString            * proxyURIString,
 NSString            * sessionString,
 NSMutableArray      * devCustodianOIDArray,
 NSMutableArray      * wanCustodianOIDArray,
 NSString            * transferSyntax,
 BOOL                  hasRestriction,
 NSRegularExpression * SeriesInstanceUIDRegex,
 NSRegularExpression * SeriesNumberRegex,
 NSRegularExpression * SeriesDescriptionRegex,
 NSRegularExpression * ModalityRegex,
 NSRegularExpression * SOPClassRegex,
 NSRegularExpression * SOPClassOffRegex,
 NSArray             * StudyInstanceUIDArray,
 NSString            * AccessionNumberString,
 NSString            * PatientIDString,
 NSArray             * StudyDateArray,
 NSString            * issuerString
)
{
   __block NSMutableArray *JSONArray=[NSMutableArray array];

   if (devCustodianOIDArray.count > 1)
   {
      //add nodes and start corresponding processes
   }

   if (wanCustodianOIDArray.count > 0)
   {
      //add nodes and start corresponding processes
   }

   if (devCustodianOIDArray.count == 0)
   {
      //add nodes and start corresponding processes
   }
   else
   {
      while (1)
      {
         NSString *custodianString=devCustodianOIDArray[0];
         NSDictionary *custodianDict=DRS.pacs[custodianString];

#pragma mark · GET type index
         NSUInteger getTypeIndex=[@[@"file",@"folder",@"wado",@"wadors",@"cget",@"cmove"] indexOfObject:custodianDict[@"get"]];

#pragma mark · SELECT switch
         switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:custodianDict[@"select"]]) {
            
            case NSNotFound:{
               LOG_WARNING(@"studyToken pacs %@ lacks \"select\" type property",custodianString);
            } break;
               
            case selectTypeSql:{
   #pragma mark · SQL SELECT (unique option for now)
               NSDictionary *sqlcredentials=@{custodianDict[@"sqluser"]:custodianDict[@"sqlpassword"]};
               NSString *sqlprolog=custodianDict[@"sqlprolog"];
               NSDictionary *sqlDictionary=DRS.sqls[custodianDict[@"sqlmap"]];

               

#pragma mark · apply EuiE (Study Patient) filters
                     NSMutableDictionary *EuiEDict=[NSMutableDictionary dictionary];
                     RSResponse *sqlEuiEErrorReturned=sqlEuiE(
                      EuiEDict,
                      sqlcredentials,
                      sqlDictionary,
                      sqlprolog,
                      StudyInstanceUIDArray,
                      AccessionNumberString,
                      PatientIDString,
                      issuerString,
                      StudyDateArray
                     );
                     if (sqlEuiEErrorReturned) return sqlEuiEErrorReturned;
             

#pragma mark ·· GET switch
               switch (getTypeIndex) {
                     
                  case NSNotFound:{
                     LOG_WARNING(@"studyToken pacs %@ lacks \"get\" property",custodianString);
                  } break;

                  case getTypeWado:{
#pragma mark ·· WADO (unique option for now)
                     
//#pragma mark study loop
                     NSMutableData *mutableData=[NSMutableData data];
                     for (NSString *Eui in EuiEDict)
                     {
//#pragma mark series loop
                        [mutableData setData:[NSData data]];
                        if (execUTF8Bash(sqlcredentials,
                                       [NSString stringWithFormat:
                                        sqlDictionary[@"sqlS"],
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
                           
                           //SOPClassUID check on the first instance
                           [mutableData setData:[NSData data]];
                           if (execUTF8Bash(sqlcredentials,
                                          [NSString stringWithFormat:
                                           sqlDictionary[@"sqlIci4S"],
                                           sqlprolog,
                                           SProperties[0],
                                           @"limit 1",
                                           @"\""
                                           ],
                                          mutableData)
                            !=0)
                        {
                           LOG_ERROR(@"studyToken instance db error");
                           continue;
                        }
                           
                        NSString *SOPClassString=[[NSString alloc] initWithData:mutableData  encoding:NSUTF8StringEncoding];

                                                
#pragma mark ....series restrictions
//do not add empty series
if (!SOPClassString.length) continue;

/*
 //dicom cda
if ([(IPropertiesFirstRecord[0])[3] isEqualToString:@"1.2.840.10008.5.1.4.1.1.104.2"]) continue;
//SR
if ([(IPropertiesFirstRecord[0])[3] hasPrefix:@"1.2.840.10008.5.1.4.1.1.88"])continue;
 
 //replaced by SOPClassOff
*/

//if there is restriction and does't match
if (hasRestriction)
{
    if (
           !(    SeriesInstanceUIDRegex
             && [SeriesInstanceUIDRegex
                 numberOfMatchesInString:SProperties[1]
                 options:0
                 range:NSMakeRange(0, [SProperties[1] length])
                 ]
             )
        && !(    SeriesNumberRegex
             && [SeriesNumberRegex
                 numberOfMatchesInString:SProperties[3]
                 options:0
                 range:NSMakeRange(0, [SProperties[3] length])
                 ]
             )
        && !(    SeriesDescriptionRegex
             && [SeriesDescriptionRegex
                 numberOfMatchesInString:SProperties[2]
                 options:0
                 range:NSMakeRange(0, [SProperties[2] length])
                 ]
             )
        && !(    ModalityRegex
             && [ModalityRegex
                 numberOfMatchesInString:SProperties[4]
                 options:0
                 range:NSMakeRange(0, [SProperties[4] length])
                 ]
             )
        && !(    SOPClassRegex
             && [SOPClassRegex
                 numberOfMatchesInString:SOPClassString
                 options:0
                 range:NSMakeRange(0, SOPClassString.length)
                 ]
             )
        && !(    SOPClassOffRegex
             &&![SOPClassOffRegex
                 numberOfMatchesInString:SOPClassString
                 options:0
                 range:NSMakeRange(0, SOPClassString.length)
                 ]
             )
        ) continue;
}

                        
                        //instances
                        [mutableData setData:[NSData data]];
                        if (execUTF8Bash(sqlcredentials,
                                       [NSString stringWithFormat:
                                        sqlDictionary[@"sqlIui4S"],
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
                           [JSONArray addObject:[NSString stringWithFormat:@"%@?requestType=WADO&studyUID=%@&seriesUID=%@&objectUID=%@&contentType=application/dicom%@",custodianDict[@"wadouri"],Eui,SProperties[1],sopuid,custodianDict[@"wadoadditionalparameters"]]];
                        }// end for each I
                           
                        //remove the / empty component at the end
                        [JSONArray removeLastObject];
                     }//end for each S
                     } break;//end of E and WADO
                  }// end of GET switch
               } break;//end of sql
            } //end of SELECT switch
         }
         break;
      }//end while 1

   }//end at least one dev

   //create the zipped response
   __block NSMutableData *directory=[NSMutableData data];
   __block uint32 entryPointer=0;
   __block uint16 entriesCount=0;
   
   // The RSAsyncStreamBlock works like the RSStreamBlock
   // The block must call "completionBlock" passing the new chunk of data when ready, an empty NSData when done, or nil on error and pass a NSError.
   // The block cannot call "completionBlock" more than once per invocation.
   return [RSStreamedResponse responseWithContentType:@"application/octet-stream" asyncStreamBlock:^(RSBodyReaderCompletionBlock completionBlock)
   {
     if (JSONArray.count>0)
     {
        //request, response and error
        NSString *wadoString=JSONArray.firstObject;
        __block NSData *wadoData=[NSData dataWithContentsOfURL:[NSURL URLWithString:wadoString]];
        if (!wadoData)
        {
           NSLog(@"could not retrive: %@",wadoString);
           completionBlock([NSData data], nil);
        }
        else
        {
           [JSONArray removeObjectAtIndex:0];
           unsigned long wadoLength=(unsigned long)[wadoData length];
           NSString *dcmUUID=[[[NSUUID UUID]UUIDString]stringByAppendingPathExtension:@"dcm"];
           NSData *dcmName=[dcmUUID dataUsingEncoding:NSUTF8StringEncoding];
           //LOG_INFO(@"dcm (%lu bytes):%@",dcmLength,dcmUUID);
           
           __block NSMutableData *entry=[NSMutableData data];
           [entry appendBytes:&zipLocalFileHeader length:4];//0x04034B50
           [entry appendBytes:&zipVersion length:2];//0x000A
           [entry increaseLengthBy:8];//uint32 flagCompression,zipTimeDate
           uint32 zipCrc32=[wadoData crc32];
           [entry appendBytes:&zipCrc32 length:4];
           [entry appendBytes:&wadoLength length:4];//zipCompressedSize
           [entry appendBytes:&wadoLength length:4];//zipUncompressedSize
           [entry appendBytes:&zipNameLength length:4];//0x28
           [entry appendData:dcmName];
           //extra param
           [entry appendData:wadoData];
           
           completionBlock(entry, nil);
           
           //directory
           [directory appendBytes:&zipFileHeader length:4];//0x02014B50
           [directory appendBytes:&zipVersion length:2];//0x000A
           [directory appendBytes:&zipVersion length:2];//0x000A
           [directory increaseLengthBy:8];//uint32 flagCompression,zipTimeDate
           [directory appendBytes:&zipCrc32 length:4];
           [directory appendBytes:&wadoLength length:4];//zipCompressedSize
           [directory appendBytes:&wadoLength length:4];//zipUncompressedSize
           [directory appendBytes:&zipNameLength length:4];//0x28
           /*
            uint16 zipFileCommLength=0x0;
            uint16 zipDiskStart=0x0;
            uint16 zipInternalAttr=0x0;
            uint32 zipExternalAttr=0x0;
            */
           [directory increaseLengthBy:10];
           
           [directory appendBytes:&entryPointer length:4];//offsetOfLocalHeader
           entryPointer+=wadoLength+70;
           entriesCount++;
           [directory appendData:dcmName];
           //extra param
        }
     }
     else if (directory.length) //chunk with directory
     {
        //ZIP "end of central directory record"
        
        //uint32 zipEndOfCentralDirectory=0x06054B50;
        [directory appendBytes:&zipEndOfCentralDirectory length:4];
        [directory increaseLengthBy:4];//zipDiskNumber
        [directory appendBytes:&entriesCount length:2];//disk zipEntries
        [directory appendBytes:&entriesCount length:2];//total zipEntries
        uint32 directorySize=86 * entriesCount;
        [directory appendBytes:&directorySize length:4];
        [directory appendBytes:&entryPointer length:4];
        [directory increaseLengthBy:2];//zipCommentLength
        completionBlock(directory, nil);
        [directory setData:[NSData data]];
     }
     else completionBlock([NSData data], nil);//last chunck
     
  }];
}


RSResponse* osirixdcmURLs(
 NSString            * proxyURIString,
 NSString            * sessionString,
 NSMutableArray      * devCustodianOIDArray,
 NSMutableArray      * wanCustodianOIDArray,
 NSString            * transferSyntax,
 BOOL                  hasRestriction,
 NSRegularExpression * SeriesInstanceUIDRegex,
 NSRegularExpression * SeriesNumberRegex,
 NSRegularExpression * SeriesDescriptionRegex,
 NSRegularExpression * ModalityRegex,
 NSRegularExpression * SOPClassRegex,
 NSRegularExpression * SOPClassOffRegex,
 NSArray             * StudyInstanceUIDArray,
 NSString            * AccessionNumberString,
 NSString            * PatientIDString,
 NSArray             * StudyDateArray,
 NSString            * issuerString
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
    regex:[NSRegularExpression regularExpressionWithPattern:@"^/(studyToken|osirix.dcmURLs|weasis.xml|dicom.zip|datatablesseries.json|datatablespatient.json|cornerstone.json)$" options:0 error:NULL]
    processBlock:^(RSRequest* request,RSCompletionBlock completionBlock)
    {
       completionBlock(^RSResponse* (RSRequest* request) {return [DRS studyToken:request];}(request));
    }
   ];

   [self
    addHandler:@"GET"
    regex:[NSRegularExpression regularExpressionWithPattern:@"^/(studyToken|osirix.dcmURLs|weasis.xml|dicom.zip|datatablesseries.json|datatablespatient.json|cornerstone.json)$" options:0 error:NULL]
    processBlock:^(RSRequest* request,RSCompletionBlock completionBlock)
    {
       completionBlock(^RSResponse* (RSRequest* request) {return [DRS studyToken:request];}(request));
    }
   ];
}


+(RSResponse*)studyToken:(RSRequest*)request
{
   //read json
   NSMutableArray *names=[NSMutableArray array];
   NSMutableArray *values=[NSMutableArray array];
   NSMutableArray *types=[NSMutableArray array];
   NSString *jsonString;
   NSString *errorString;
   if (!parseRequestParams(request, names, values, types, &jsonString, &errorString))
   {
      LOG_WARNING(@"studyToken PARAMS error: %@",errorString);
      return [RSErrorResponse responseWithClientError:404 message:@"%@",errorString];
   }
   for (NSUInteger idx=0;idx<[names count];idx++)
   {
      LOG_VERBOSE(@"studyToken PARAM \"%@\" = \"%@\"",names[idx],values[idx]);
   }

   //proxyURI
   NSString *proxyURIString=nil;
   NSInteger proxyURIIndex=[names indexOfObject:@"proxyURI"];
   if (proxyURIIndex!=NSNotFound) proxyURIString=values[proxyURIIndex];
   else proxyURIString=@"whatIsTheURLToBeInvoked?";
   
   //session
   NSString *sessionString=nil;
   NSInteger sessionIndex=[names indexOfObject:@"session"];
   if (sessionIndex!=NSNotFound) sessionString=values[sessionIndex];
   else sessionString=@"";
   

   
#pragma mark custodianOID?
   NSInteger custodianOIDIndex=[names indexOfObject:@"custodianOID"];
   if (custodianOIDIndex==NSNotFound)
   {
      LOG_WARNING(@"studyToken custodianOID not available");
      return [RSErrorResponse responseWithClientError:404 message:@"studyToken custloianOID not available"];
   }
   
   NSMutableArray *wanCustodianOIDArray=[NSMutableArray array];
   NSMutableArray *devCustodianOIDArray=[NSMutableArray array];
   NSArray *custodianOIDArray=[values[custodianOIDIndex] componentsSeparatedByString:@"~"];
   for (NSInteger i=[custodianOIDArray count]-1;i>=0;i--)
   {
      if ([DRS.wan indexOfObject:custodianOIDArray[i]]!=NSNotFound)
      {
         [wanCustodianOIDArray addObject:custodianOIDArray[i]];
         LOG_DEBUG(@"studyToken custodianOID wan %@",custodianOIDArray[i]);
      }
      else if ([DRS.dev indexOfObject:custodianOIDArray[i]]!=NSNotFound)
      {
         [devCustodianOIDArray addObject:custodianOIDArray[i]];
         LOG_DEBUG(@"studyToken custodianOID dev %@",custodianOIDArray[i]);
      }
      else if ([DRS.lan indexOfObject:custodianOIDArray[i]]!=NSNotFound)
      {
         //find all dev of local custodian
         if (DRS.oidsaeis[custodianOIDArray[i]])
         {
            [devCustodianOIDArray addObjectsFromArray:DRS.oidsaeis[custodianOIDArray[i]]];
            LOG_VERBOSE(@"studyToken custodianOID for dev %@:\r\n%@",custodianOIDArray[i],[DRS.oidsaeis[custodianOIDArray[i]]description]);
         }
         else
         {
            [devCustodianOIDArray addObjectsFromArray:DRS.titlestitlesaets[custodianOIDArray[i]]];
            LOG_VERBOSE(@"studyToken custodianOID for dev %@:\r\n%@",custodianOIDArray[i],[DRS.titlestitlesaets[custodianOIDArray[i]]description]);
         }
      }
      else
      {
         LOG_WARNING(@"studyToken custodianOID '%@' not registered",custodianOIDArray[i]);
      }
   }
   if (![devCustodianOIDArray count] && ![wanCustodianOIDArray count]) return [RSErrorResponse responseWithClientError:404 message:@"no known pacs in:\r\n%@",[custodianOIDArray description]];


#pragma mark series restriction in query?

//#pragma mark SeriesNumber
   NSRegularExpression *SeriesInstanceUIDRegex=nil;
   NSInteger SeriesInstanceUIDIndex=[names indexOfObject:@"SeriesInstanceUID"];
   if (SeriesInstanceUIDIndex!=NSNotFound) SeriesInstanceUIDRegex=[NSRegularExpression regularExpressionWithPattern:values[SeriesInstanceUIDIndex] options:0 error:NULL];
//#pragma mark SeriesNumber
   NSRegularExpression *SeriesNumberRegex=nil;
   NSInteger SeriesNumberIndex=[names indexOfObject:@"SeriesNumber"];
   if (SeriesNumberIndex!=NSNotFound) SeriesNumberRegex=[NSRegularExpression regularExpressionWithPattern:values[SeriesNumberIndex] options:0 error:NULL];
//#pragma mark SeriesDescription
   NSRegularExpression *SeriesDescriptionRegex=nil;
   NSInteger SeriesDescriptionIndex=[names indexOfObject:@"SeriesDescription"];
   if (SeriesDescriptionIndex!=NSNotFound) SeriesDescriptionRegex=[NSRegularExpression regularExpressionWithPattern:values[SeriesDescriptionIndex] options:0 error:NULL];
//#pragma mark Modality
   NSRegularExpression *ModalityRegex=nil;
   NSInteger ModalityIndex=[names indexOfObject:@"Modality"];
   if (ModalityIndex!=NSNotFound) ModalityRegex=[NSRegularExpression regularExpressionWithPattern:values[ModalityIndex] options:0 error:NULL];
//#pragma mark SOPClass
   NSRegularExpression *SOPClassRegex=nil;
   NSInteger SOPClassIndex=[names indexOfObject:@"SOPClass"];
   if (SOPClassIndex!=NSNotFound) SOPClassRegex=[NSRegularExpression regularExpressionWithPattern:values[SOPClassIndex] options:0 error:NULL];
   BOOL hasRestriction=
      SeriesInstanceUIDRegex
   || SeriesNumberRegex
   || SeriesDescriptionRegex
   || ModalityRegex
   || SOPClassRegex;


//#pragma mark SOPClassOff
   NSRegularExpression *SOPClassOffRegex=nil;
   NSInteger SOPClassOffIndex=[names indexOfObject:@"SOPClassOff"];
   if (SOPClassOffIndex!=NSNotFound) SOPClassOffRegex=[NSRegularExpression regularExpressionWithPattern:values[SOPClassOffIndex] options:0 error:NULL];

   
#pragma mark Patient Study filter formal validity?
   NSInteger StudyInstanceUIDsIndex=[names indexOfObject:@"StudyInstanceUID"];
   NSArray *StudyInstanceUIDArray=nil;
   NSInteger AccessionNumberIndex=[names indexOfObject:@"AccessionNumber"];
   NSString *AccessionNumberString=nil;
   NSInteger PatientIDIndex=[names indexOfObject:@"PatientID"];
   NSString *PatientIDString=nil;
   NSInteger StudyDateIndex=[names indexOfObject:@"StudyDate"];
   NSMutableArray *StudyDateArray=[NSMutableArray array];
   if ((StudyInstanceUIDsIndex!=NSNotFound)&&([values[StudyInstanceUIDsIndex] length]))
   {
      if (
            ((AccessionNumberIndex!=NSNotFound)&&([values[AccessionNumberIndex] length]))
          ||((StudyDateIndex!=NSNotFound)&&([values[StudyDateIndex] length]))
          ||((PatientIDIndex!=NSNotFound)&&([values[PatientIDIndex] length]))
          ) return [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken StudyInstanceUID shoud not be present together with AccessionNumber or StudyDate or PatientID"];
      for (NSString *uid in [values[StudyInstanceUIDsIndex]componentsSeparatedByString:@"~"])
      {
         if (![DICMTypes isSingleUIString:uid]) return [RSErrorResponse responseWithClientError:404 message:@"studyToken no StudyInstanceUID found in %@",uid];
      }
      StudyInstanceUIDArray=[values[StudyInstanceUIDsIndex]componentsSeparatedByString:@"~"];
   }
   else if ((AccessionNumberIndex!=NSNotFound)&&([values[AccessionNumberIndex] length]))
   {
      if (
            ((StudyDateIndex!=NSNotFound)&&([values[StudyDateIndex] length]))
          ||((PatientIDIndex!=NSNotFound)&&([values[StudyDateIndex] length]))
          ) return [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken AccessionNumber should not be present together with StudyDate or PatientID"];
       AccessionNumberString=values[AccessionNumberIndex];
   }
   else if ((PatientIDIndex!=NSNotFound)&&[values[PatientIDIndex] length])
   {
       PatientIDString=values[PatientIDIndex];
      
       if (StudyDateIndex!=NSNotFound)
       {
          NSString *StudyDateString=values[StudyDateIndex];
          /*
           input options are:
           ()
           |aaaa-mm-dd
           aaaa-mm-dd
           aaaa-mm-dd|
           aaaa-mm-dd|aaaa-mm-dd
           
           output format options are:
           sqlEP4PidEda0 (empty) = whichever date
           sqlEP4PidEda1 [aaaa-mm-dd] = on
           sqlEP4PidEda2 [aaaa-mm-dd][] = since
           sqlEP4PidEda3 [][][aaaa-mm-dd] = until
           sqlEP4PidEda4 [aaaa-mm-dd][][][aaaa-mm-dd] = between
           */
          if (StudyDateString.length)
          {
             //>0
             [StudyDateArray addObjectsFromArray:[StudyDateString componentsSeparatedByString:@"|"]];
             BOOL date0=NO;
             if (StudyDateArray.count > 0) date0=[DICMTypes isSingleDAISOString:StudyDateArray[0]];
             BOOL date1=NO;
             if (StudyDateArray.count > 1) date1=[DICMTypes isSingleDAISOString:StudyDateArray[1]];

             if ((StudyDateArray.count==1) && date0)
             {
                //aaaa-mm-dd
                //1 [aaaa-mm-dd] -> on
                [StudyDateArray insertObject:@"" atIndex:0];
                [StudyDateArray insertObject:@"" atIndex:0];
             }
             else if ((StudyDateArray.count==2) && date0 && date1)
             {
                //aaaa-mm-dd|aaaa-mm-dd
                //4 [aaaa-mm-dd][][][aaaa-mm-dd] -> since / until
                [StudyDateArray insertObject:@"" atIndex:1];
                [StudyDateArray insertObject:@"" atIndex:1];
             }
             else if (     (StudyDateArray.count==2)
                       &&  date0
                       && ![StudyDateArray[1] length]
                      )
             {
                //aaaa-mm-dd|
                //2 [aaaa-mm-dd][] -> since
             }
             else if (     (StudyDateArray.count==2)
                       && ![StudyDateArray[0] length]
                       &&  date1
                      )
             {
                //|aaaa-mm-dd
                //3 [][][aaaa-mm-dd] -> until
                [StudyDateArray insertObject:@"" atIndex:0];
             }
             else return [RSErrorResponse responseWithClientError:404 message:@"studyToken bad StudyDate %@",StudyDateString];
          }
       }
   }
   else return [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken one of StudyInstanceUID, AccessionNumber or PatientID+StudyDate should be present"];
  

   //issuer (may be nil)
   NSString *issuerString=nil;
   NSInteger issuerIndex=[names indexOfObject:@"issuer"];
   if (issuerIndex!=NSNotFound) issuerString=values[issuerIndex];


#pragma mark ACCESS switch
   NSInteger accessType=NSNotFound;
   NSString *requestPath=request.path;
   if (![requestPath isEqualToString:@"/studyToken"])  accessType=[@[@"/weasis.xml", @"/cornerstone.json", @"/dicom.zip", @"/osirix.dcmURLs", @"/datatablesseries.json", @"/datatablespatient.json"]  indexOfObject:requestPath];
   else
   {
      NSInteger accessTypeIndex=[names indexOfObject:@"accessType"];
      if (accessTypeIndex==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessType required in request"];
      accessType=[@[@"weasis.xml", @"cornerstone.json", @"dicom.zip", @"osirix.dcmURLs", @"datatablesseries.json", @"datatablespatient.json"] indexOfObject:values[accessTypeIndex]];
      if (accessType==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessType %@ unknown",values[accessTypeIndex]];
   }
   switch (accessType) {
      case accessTypeWeasis:{
         return weasis(
                 proxyURIString,
                 sessionString,
                 devCustodianOIDArray,
                 wanCustodianOIDArray,
                 nil,
                 hasRestriction,
                 SeriesInstanceUIDRegex,
                 SeriesNumberRegex,
                 SeriesDescriptionRegex,
                 ModalityRegex,
                 SOPClassRegex,
                 SOPClassOffRegex,
                 StudyInstanceUIDArray,
                 AccessionNumberString,
                 PatientIDString,
                 StudyDateArray,
                 issuerString
                 );
         } break;//end of sql wado weasis
      case accessTypeCornerstone:{
         return cornerstone(
                 proxyURIString,
                 sessionString,
                 devCustodianOIDArray,
                 wanCustodianOIDArray,
                 nil,
                 hasRestriction,
                 SeriesInstanceUIDRegex,
                 SeriesNumberRegex,
                 SeriesDescriptionRegex,
                 ModalityRegex,
                 SOPClassRegex,
                 SOPClassOffRegex,
                 StudyInstanceUIDArray,
                 AccessionNumberString,
                 PatientIDString,
                 StudyDateArray,
                 issuerString
                 );
         } break;//end of sql wado cornerstone
      case accessTypeDicomzip:{
            return dicomzip(
                    proxyURIString,
                    sessionString,
                    devCustodianOIDArray,
                    wanCustodianOIDArray,
                    nil,
                    hasRestriction,
                    SeriesInstanceUIDRegex,
                    SeriesNumberRegex,
                    SeriesDescriptionRegex,
                    ModalityRegex,
                    SOPClassRegex,
                    SOPClassOffRegex,
                    StudyInstanceUIDArray,
                    AccessionNumberString,
                    PatientIDString,
                    StudyDateArray,
                    issuerString
                    );
         
         } break;//end of sql wado dicomzip
      case accessTypeOsirix:{
            return osirixdcmURLs(
                    proxyURIString,
                    sessionString,
                    devCustodianOIDArray,
                    wanCustodianOIDArray,
                    nil,
                    hasRestriction,
                    SeriesInstanceUIDRegex,
                    SeriesNumberRegex,
                    SeriesDescriptionRegex,
                    ModalityRegex,
                    SOPClassRegex,
                    SOPClassOffRegex,
                    StudyInstanceUIDArray,
                    AccessionNumberString,
                    PatientIDString,
                    StudyDateArray,
                    issuerString
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
