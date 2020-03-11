#import "DRS+cornerstone.h"
#import "DRS+studyToken.h"

@implementation DRS (cornerstone)

+(void)cornerstoneSql4dictionary:(NSDictionary*)d
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


      NSMutableDictionary *arc=[NSMutableDictionary dictionaryWithContentsOfFile:d[@"path"]];
      if (!arc)
      {
         arc=[NSMutableDictionary dictionaryWithObjectsAndKeys:
         d[@"devOID"], @"arcId",
         d[@"proxyURIString"],@"baseUrl",
         nil];
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
      NSMutableArray *patientArray=arc[@"patientList"];
      if (!patientArray) {
         patientArray=[NSMutableArray array];
         [arc setObject:patientArray forKey:@"patientList"];
      }
      
      for (NSString *P in [NSSet setWithArray:[EPDict allValues]])
      {
         NSMutableArray *studyArray=nil;
         
         NSMutableDictionary *patient=[patientArray firstMutableDictionaryWithKey:@"key" isEqualToNumber:[NSNumber numberWithLongLong:[P longLongValue]]];
         if (patient)
         {
            [studyArray setArray:arc[@"studyList"]];
            if (!studyArray)
            {
               studyArray=[NSMutableArray array];
               [patient setObject:studyArray forKey:@"studyList"];
            }
         }
         else
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
                              

#pragma mark study loop
         for (NSString *E in EPDict)
         {
            if ([EPDict[E] isEqualToString:P])
            {
               NSMutableArray *seriesArray=nil;

               NSMutableDictionary *study=[studyArray firstMutableDictionaryWithKey:@"key" isEqualToNumber:[NSNumber numberWithLongLong:[E longLongValue]]];

               if (study) //found in cache
               {
                  [seriesArray setArray:study[@"seriesList"]];
                  if (!seriesArray)
                  {
                     seriesArray=[NSMutableArray array];
                     [study setObject:seriesArray forKey:@"seriesList"];
                  }
               }
               else //new study
               {
                  NSMutableData *studyData=[NSMutableData data];
                  if (execUTF8Bash(sqlcredentials,
                                    [NSString stringWithFormat:
                                     sqlDictionary[@"E"],
                                     sqlprolog,
                                     E,
                                     @"",
                                     sqlRecordSixteenUnits
                                     ],
                                    studyData)
                      !=0)
                  {
                     LOG_ERROR(@"studyToken study db error");
                     continue;
                  }
                  NSArray *studySqlPropertiesArray=[studyData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:3 decreasing:YES];//NSUTF8StringEncoding
               
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
 patient[@"PatientID"],@"patientId",
 patient[@"PatientName"],@"patientName",
 seriesArray,@"seriesList",
nil];
                  [studyArray addObject:study];
               }
         
               
#pragma mark series loop
               NSMutableData *seriesData=[NSMutableData data];
               if (execUTF8Bash(sqlcredentials,
                                 [NSString stringWithFormat:
                                  sqlDictionary[@"S"],
                                  sqlprolog,
                                  E,
                                  @"",
                                  sqlRecordThirteenUnits
                                  ],
                                 seriesData)
                   !=0)
               {
                  LOG_ERROR(@"studyToken series db error");
                  continue;
               }
               NSArray *seriesSqlPropertiesArray=[seriesData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:3 decreasing:NO];//NSUTF8StringEncoding
               for (NSArray *seriesSqlProperties in seriesSqlPropertiesArray)
               {
                  NSMutableDictionary *series=[seriesArray firstMutableDictionaryWithKey:@"key" isEqualToNumber:[NSNumber numberWithLongLong:[seriesSqlProperties[0] longLongValue]]];
                  NSString *SOPClass=nil;
                  if (series) //found in cache
                  {
                     if ([series[@"numImages"] longLongValue]!=[seriesSqlProperties[10]longLongValue]) SOPClass=series[@"SOPClassUID"];//check instances
                  }
                  else //new series
                  {
                      //add it? (SOPClass = yes)
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
                     //add series and instances
                     
                     //instances
NSMutableArray *instanceArray=[NSMutableArray array];
series=[NSMutableDictionary dictionaryWithObjectsAndKeys:
[NSNumber numberWithLongLong:[seriesSqlProperties[0] longLongValue]],@"key",
seriesSqlProperties[2], @"seriesDescription",
seriesSqlProperties[3], @"seriesNumber",
seriesSqlProperties[1], @"SeriesInstanceUID",
SOPClass, @"SOPClassUID",
seriesSqlProperties[4], @"Modality",
@"*",@"WadoTransferSyntaxUID",
seriesSqlProperties[5], @"Institution",
seriesSqlProperties[6], @"Department",
seriesSqlProperties[7], @"StationName",
seriesSqlProperties[8], @"PerformingPhysician",
seriesSqlProperties[9], @"Laterality",
[NSNumber numberWithLongLong:[seriesSqlProperties[10] longLongValue]], @"numImages",
instanceArray,@"instanceList",
nil];
                     
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
                        switch (getTypeIndex)
                        {
                           case getTypeWado:
                           {
                              NSString *wadouriInstance=
                              [NSString
                               stringWithFormat:
                               @"wadouri:%@?requestType=WADO&studyUID=%@&seriesUID=%@&objectUID=%@&session=%%@&custodianOID=%@&arcId=%@%@",
                               d[@"proxyURIString"],
                               study[@"StudyInstanceUID"],
                               seriesSqlProperties[1],
                               instanceSqlProperties[2],
                               devDict[@"custodianoid"],
                               d[@"devOID"],
                               devDict[@"wadocornerstoneparameters"]
                              ];
                              [instanceArray addObject:
     @{
       @"key":[NSNumber numberWithLongLong: [instanceSqlProperties[0] longLongValue]],
       @"InstanceNumber":instanceSqlProperties[3],
       @"numFrames":[NSNumber numberWithLongLong:[instanceSqlProperties[4] longLongValue]],
       @"SOPClassUID":instanceSqlProperties[1],
       @"SOPInstanceUID":instanceSqlProperties[2],
       @"imageId":wadouriInstance
      }
                              ];
                           } break;//end of WADO
                        }//end of GET switch
                     }//end for each I
                  }//end if SOPClass
               }// end for each S
            }//end of ([EPDict[E] isEqualToString:P])
         }//end for each E
      }//end for each P
       
      NSData *docData=[NSJSONSerialization dataWithJSONObject:arc options:0 error:nil];
      [docData writeToFile:d[@"path"] atomically:YES];

   }//end EP
}
@end
