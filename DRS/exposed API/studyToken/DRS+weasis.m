#import "DRS+weasis.h"
#import "DRS+studyToken.h"

#import "WeasisArcQuery.h"
#import "WeasisPatient.h"
#import "WeasisStudy.h"
#import "WeasisSeries.h"
#import "WeasisInstance.h"

@implementation DRS (weasis)

+(void)weasisSql4dictionary:(NSDictionary*)d
{
   NSDictionary *devDict=DRS.pacs[d[@"devOID"]];
   
//sql
   NSDictionary *sqlcredentials=@{devDict[@"sqlcredentials"]:devDict[@"sqlpassword"]};
   NSString *sqlprolog=devDict[@"sqlprolog"];
   NSDictionary *sqlDictionary=DRS.sqls[devDict[@"sqlmap"]];
   
//apply EP (Study Patient) filters
   NSMutableDictionary *EPDict=[NSMutableDictionary dictionary];
   RSResponse *sqlEPErrorReturned=sqlEP(
    EPDict,
    sqlcredentials,
    sqlDictionary,
    sqlprolog,
    false,
    d[@"StudyInstanceUIDRegexpString"],
    d[@"AccessionNumberEqualString"],
    d[@"refInstitutionLikeString"],
    d[@"refServiceLikeString"],
    d[@"refUserLikeString"],
    d[@"refIDLikeString"],
    d[@"refIDTypeLikeString"],
    d[@"readInstitutionSqlLikeString"],
    d[@"readServiceSqlLikeString"],
    d[@"readUserSqlLikeString"],
    d[@"readIDSqlLikeString"],
    d[@"readIDTypeSqlLikeString"],
    d[@"StudyIDLikeString"],
    d[@"PatientIDLikeString"],
    d[@"patientFamilyLikeString"],
    d[@"patientGivenLikeString"],
    d[@"patientMiddleLikeString"],
    d[@"patientPrefixLikeString"],
    d[@"patientSuffixLikeString"],
    d[@"issuerArray"],
    d[@"StudyDateArray"],
    d[@"SOPClassInStudyRegexpString"],
    d[@"ModalityInStudyRegexpString"],
    d[@"StudyDescriptionRegexpString"]
   );
   if (!sqlEPErrorReturned && EPDict.count)
   {
      //sql instance inits
      NSString *instanceANDSOPClass=nil;
      if (d[@"SOPClassRegexString"]) instanceANDSOPClass=
      [NSString stringWithFormat:
       sqlDictionary[@"ANDinstanceSOPClass"],
       d[@"SOPClassRegexString"]
      ];
      else instanceANDSOPClass=@"";

      NSString *instanceANDSOPClassOff=nil;
      if (d[@"SOPClassOffRegexString"]) instanceANDSOPClassOff=
      [NSString stringWithFormat:
       sqlDictionary[@"ANDinstanceSOPClassOff"],
       d[@"SOPClassOffRegexString"]
      ];
      else instanceANDSOPClassOff=@"";

      
      //get
      NSUInteger getTypeIndex=[@[@"file",@"folder",@"wado",@"wadors",@"cget",@"cmove"] indexOfObject:devDict[@"get"]];



      NSError  *error=nil;
      NSXMLElement *arcQueryElement=nil;
      NSString *XMLString=[NSString stringWithContentsOfFile:d[@"path"] encoding:NSUTF8StringEncoding error:&error];
      if (XMLString) arcQueryElement=[[NSXMLElement alloc]initWithXMLString:XMLString error:&error];
      else if (error) LOG_WARNING(@"reading %@. %@",d[@"path"],[error description]);
      if (!arcQueryElement)
      {
         if (error)
         {
            LOG_WARNING(@"parsing %@. %@",d[@"path"],[error description]);
            [[NSFileManager defaultManager] moveItemAtPath:d[@"path"] toPath:[d[@"path"] stringByAppendingPathExtension:@"badxml"] error:nil];
         }
         arcQueryElement=
         [WeasisArcQuery
          arcQueryId:d[@"sessionString"]
          weasisarcId:d[@"devOID"]
          weasisbaseUrl:d[@"proxyURIString"]
          weasiswebLogin:nil
          weasisrequireOnlySOPInstanceUID:nil
          weasisadditionnalParameters:nil
          weasisoverrideDicomTagsList:nil
          seriesFilterInstanceUID:d[@"SeriesInstanceUIDRegexString"]
          seriesFilterNumber:d[@"SeriesNumberRegexString"]
          seriesFilterDescription:d[@"SeriesDescriptionRegexString"]
          seriesFilterModality:d[@"ModalityRegexString"]
          seriesFilterSOPClass:d[@"SOPClassRegexString"]
          seriesFilterSOPClassOff:d[@"SOPClassOffRegexString"]
         ];
      }

      
      //prepare regex level series
       NSRegularExpression *SeriesInstanceUIDRegex = nil;
       NSRegularExpression *SeriesNumberRegex = nil;
       NSRegularExpression *SeriesDescriptionRegex = nil;
       NSRegularExpression *ModalityRegex = nil;
       NSRegularExpression *SOPClassRegex = nil;
       NSRegularExpression *SOPClassOffRegex = nil;
       if (d[@"hasRestriction"])
       {
           if (d[@"SeriesInstanceUIDRegexString"]) SeriesInstanceUIDRegex=[NSRegularExpression regularExpressionWithPattern:d[@"SeriesInstanceUIDRegexString"] options:0 error:NULL];
           if (d[@"SeriesNumberRegexString"]) SeriesNumberRegex=[NSRegularExpression regularExpressionWithPattern:d[@"SeriesNumberRegexString"] options:0 error:NULL];
           if (d[@"SeriesDescriptionRegexString"]) SeriesDescriptionRegex=[NSRegularExpression regularExpressionWithPattern:d[@"SeriesDescriptionRegexString"] options:0  error:NULL];
           if (d[@"ModalityRegexString"]) ModalityRegex=[NSRegularExpression regularExpressionWithPattern:d[@"ModalityRegexString"] options:0 error:NULL];
           if (d[@"SOPClassRegexString"]) SOPClassRegex=[NSRegularExpression regularExpressionWithPattern:d[@"SOPClassRegexString"] options:0 error:NULL];
           if (d[@"SOPClassOffRegexString"]) SOPClassOffRegex = [NSRegularExpression regularExpressionWithPattern:d[@"SOPClassOffRegexString"] options:0 error:NULL];
       }

#pragma mark patient loop
      NSArray *patientArray=[arcQueryElement elementsForName:@"Patient"];
      NSMutableDictionary *patientDictionary=[NSMutableDictionary dictionary];
      for (NSXMLElement *cachedPatient in patientArray)
      {
         [patientDictionary setObject:cachedPatient forKey:[[cachedPatient attributeForName:@"key"]stringValue]];
      }
         
      for (NSString *P in [NSSet setWithArray:[EPDict allValues]])
      {
         NSXMLElement *PatientElement=patientDictionary[P];
         if (!PatientElement)
         {
            NSMutableData *patientData=[NSMutableData data];
            if (execUTF8Bash(sqlcredentials,
                              [NSString stringWithFormat:
                               sqlDictionary[@"P"],
                               sqlprolog,
                               P,
                               @"",
                               sqlRecordSixUnits
                               ],
                              patientData)
                !=0)
            {
               LOG_ERROR(@"studyToken patient db error");
               continue;
            }
            NSArray *patientSqlPropertiesArray=[patientData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding
            PatientElement=
            [WeasisPatient key:(patientSqlPropertiesArray[0])[0]
             weasisPatientID:(patientSqlPropertiesArray[0])[1]
             weasisPatientName:(patientSqlPropertiesArray[0])[2]
             weasisIssuerOfPatientID:(patientSqlPropertiesArray[0])[3]
             weasisPatientBirthDate:(patientSqlPropertiesArray[0])[4]
             weasisPatientBirthTime:nil
             weasisPatientSex:(patientSqlPropertiesArray[0])[5]
             ];
            [arcQueryElement addChild:PatientElement];
         }

#pragma mark study loop
         NSArray *studyArray=[PatientElement elementsForName:@"Study"];
         NSMutableDictionary *studyDictionary=[NSMutableDictionary dictionary];
         for (NSXMLElement *cachedStudy in studyArray)
         {
            [studyDictionary setObject:cachedStudy forKey:[[cachedStudy attributeForName:@"key"]stringValue]];
         }
         for (NSString *E in EPDict)
         {
            if ([EPDict[E] isEqualToString:P])
            {
               NSXMLElement *StudyElement=studyDictionary[E];//Study=Exam
               if (!StudyElement)
               {
                  NSMutableData *studyData=[NSMutableData data];
                  if (execUTF8Bash(sqlcredentials,
                                    [NSString stringWithFormat:
                                     sqlDictionary[@"E"],
                                     sqlprolog,
                                     E,
                                     @"",
                                     sqlRecordTenUnits
                                     ],
                                    studyData)
                      !=0)
                  {
                     LOG_ERROR(@"studyToken study db error");
                     continue;
                  }
                  NSArray *studySqlPropertiesArray=[studyData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:3 decreasing:YES];//NSUTF8StringEncoding

                  StudyElement=
                  [WeasisStudy
                   key:(studySqlPropertiesArray[0])[0]
                   weasisStudyInstanceUID:(studySqlPropertiesArray[0])[1]
                   weasisStudyDescription:(studySqlPropertiesArray[0])[2]
                   weasisStudyDate:[DICMTypes DAStringFromDAISOString:(studySqlPropertiesArray[0])[3]]
                   weasisStudyTime:[DICMTypes TMStringFromTMISOString:(studySqlPropertiesArray[0])[4]]
                   weasisAccessionNumber:(studySqlPropertiesArray[0])[5]
                   weasisStudyId:(studySqlPropertiesArray[0])[6]
                   weasisReferringPhysicianName:(studySqlPropertiesArray[0])[7]
                   issuer:nil
                   issuerType:nil
                   series:(studySqlPropertiesArray[0])[8]
                   modalities:(studySqlPropertiesArray[0])[9]
                   ];
                  [PatientElement addChild:StudyElement];
               }
               
#pragma mark series loop
               NSArray *seriesArray=[StudyElement elementsForName:@"Series"];
               NSMutableDictionary *seriesDictionary=[NSMutableDictionary dictionary];
               for (NSXMLElement *cachedSeries in seriesArray)
               {
                  [seriesDictionary setObject:cachedSeries forKey:[[cachedSeries attributeForName:@"key"]stringValue]];
               }
               
               NSMutableData *seriesData=[NSMutableData data];
               if (execUTF8Bash(sqlcredentials,
                                 [NSString stringWithFormat:
                                  sqlDictionary[@"S"],
                                  sqlprolog,
                                  E,
                                  @"",
                                  sqlRecordElevenUnits
                                  ],
                                 seriesData)
                   !=0)
               {
                  LOG_ERROR(@"studyToken study db error");
                  continue;
               }
               NSArray *seriesSqlPropertiesArray=[seriesData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:3 decreasing:NO];//NSUTF8StringEncoding
               for (NSArray *seriesSqlProperties in seriesSqlPropertiesArray)
               {
                  NSXMLElement *SeriesElement=seriesDictionary[seriesSqlProperties[0]];
                  NSString *SOPClass=nil;
                  if (SeriesElement) //found in cache
                  {
                     if (![[[SeriesElement attributeForName:@"numImages"]stringValue] isEqualToString:seriesSqlProperties[10]]) SOPClass=[[SeriesElement attributeForName:@"SOPClassUID"]stringValue];//check instances
                  }
                  else //new series
                  {
                      //add it?
                      SOPClass=SOPCLassOfReturnableSeries(
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
                  }
                  if (SOPClass)
                  {
                     //did series exists
                     if (!SeriesElement)
                     {
                        SeriesElement=
                        [WeasisSeries
                         key:seriesSqlProperties[0]
                         weasisSeriesInstanceUID:seriesSqlProperties[1]
                         weasisSeriesDescription:seriesSqlProperties[2]
                         weasisSeriesNumber:seriesSqlProperties[3]
                         weasisModality:seriesSqlProperties[4]
                         weasisWadoTransferSyntaxUID:@"*"
                         weasisWadoCompressionRate:nil
                         weasisDirectDownloadThumbnail:nil
                         sop:SOPClass
                         institution:seriesSqlProperties[5]
                         department:seriesSqlProperties[6]
                         stationName:seriesSqlProperties[7]
                         performingPhysician:seriesSqlProperties[8]
                         laterality:seriesSqlProperties[9]
                         images:seriesSqlProperties[10]
                        ];
                        [StudyElement addChild:SeriesElement];
                     }
                     
                     //add institution to studies
                     [StudyElement addAttribute:[NSXMLNode attributeWithName:@"institution" stringValue:seriesSqlProperties[5]]];

                                                      
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
                     
                     NSMutableData *instanceData=[NSMutableData data];
                     if ([DRS.InstanceUniqueFrameSOPClass indexOfObject:SOPClass]!=NSNotFound)//I1
                     {
                        if (execUTF8Bash(sqlcredentials,
                                         [NSString stringWithFormat:
                                          sqlDictionary[@"I1"],
                                          sqlprolog,
                                          seriesSqlProperties[0],
                                          instanceANDSOPClass,
                                          instanceANDSOPClassOff,
                                          @"",
                                          sqlRecordFiveUnits
                                          ],
                                         instanceData)
                            !=0)
                        {
                           LOG_ERROR(@"studyToken study db error");
                           continue;
                        }
                     }
                     else if ([DRS.InstanceMultiFrameSOPClass indexOfObject:SOPClass]!=NSNotFound)//I
                     {
                        // watch optional IpostprocessingCommandsSh
                        if (execUTF8Bash(sqlcredentials,
                                         [NSString stringWithFormat:
                                          sqlDictionary[@"I"],
                                          sqlprolog,
                                          seriesSqlProperties[0],
                                          instanceANDSOPClass,
                                          instanceANDSOPClassOff,
                                          @"",
                                       [sqlDictionary[@"IpostprocessingCommandsSh"]length]
                                        ?sqlDictionary[@"IpostprocessingCommandsSh"]
                                        :sqlRecordFiveUnits
                                          ],
                                         instanceData)
                            !=0)
                        {
                           LOG_ERROR(@"studyToken study db error");
                           continue;
                        }
                     }
                     else //I0
                     {
                        if (execUTF8Bash(sqlcredentials,
                                         [NSString stringWithFormat:
                                          sqlDictionary[@"I0"],
                                          sqlprolog,
                                          seriesSqlProperties[0],
                                          instanceANDSOPClass,
                                          instanceANDSOPClassOff,
                                          @"",
                                          sqlRecordFiveUnits
                                          ],
                                         instanceData)
                            !=0)
                        {
                           LOG_ERROR(@"studyToken study db error");
                           continue;
                        }
                     }
                     NSArray *instanceSqlPropertiesArray=[instanceData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding stringUnitsPostProcessTitle:sqlDictionary[@"IpostprocessingTitleMain"] orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding


#pragma mark instance loop
                     for (NSArray *instanceSqlProperties in instanceSqlPropertiesArray)
                     {
                        //imageId = (weasis) DirectDownloadFile
                        switch (getTypeIndex)
                        {
                           case getTypeWado:
                           {
NSXMLElement *InstanceElement=
                        [WeasisInstance
                         key:instanceSqlProperties[0]
                         weasisInstanceNumber:instanceSqlProperties[3]
                         NumberOfFrames:instanceSqlProperties[4]
                         weasisSOPClassUID:instanceSqlProperties[1]
                         weasisSOPInstanceUID:instanceSqlProperties[2]
                         weasisDirectDownloadFile:nil];

                        [SeriesElement addChild:InstanceElement];
                           } break;//end of WADO
                        }//end of GET switch
                     }//end for each I
                  }//end if SOPClass
               }// end for each S
            }//end of ([EPDict[E] isEqualToString:P])
         }//end for each E
      }//end for each P

   NSXMLDocument *doc=[NSXMLDocument documentWithRootElement:arcQueryElement];
   doc.documentContentKind=NSXMLDocumentXMLKind;
   //doc.characterEncoding=@"UTF-8";
   doc.standalone=true;
   NSData *docData=[doc XMLData];
   [docData writeToFile:d[@"path"] atomically:YES];
   }
}
@end
