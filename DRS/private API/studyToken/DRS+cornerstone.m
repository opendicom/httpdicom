#import "DRS+cornerstone.h"
#import "DRS+studyToken.h"
#import "NSArray+PCS.h"

@implementation DRS (cornerstone)

+(void)cornerstoneSql4dictionary:(NSDictionary*)d
{
   NSDictionary *devDict=DRS.pacs[d[@"devOID"]];
   
#pragma mark sql inits
   NSDictionary *sqlcredentials=@{devDict[@"sqlcredentials"]:devDict[@"sqlpassword"]};
   NSString *sqlprolog=devDict[@"sqlprolog"];
   NSDictionary *sqlDictionary=DRS.sqls[devDict[@"sqlmap"]];
   

#pragma mark filter inits
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
   NSUInteger getTypeIndex=[@[@"wado",@"folderDcm4chee2",@"folderDcm4cheeArc"] indexOfObject:devDict[@"get"]];


   
   //prepare regex level series
    NSRegularExpression *SeriesInstanceUIDRegex = nil;
    NSRegularExpression *SeriesNumberRegex = nil;
    NSRegularExpression *SeriesDescriptionRegex = nil;
    NSRegularExpression *ModalityRegex = nil;
    NSRegularExpression *SOPClassRegex = nil;
    NSRegularExpression *SOPClassOffRegex = nil;
    if (d[@"hasSeriesFilter"])
    {
        if (d[@"SeriesInstanceUIDRegexString"]) SeriesInstanceUIDRegex=[NSRegularExpression regularExpressionWithPattern:d[@"SeriesInstanceUIDRegexString"] options:0 error:NULL];
        if (d[@"SeriesNumberRegexString"]) SeriesNumberRegex=[NSRegularExpression regularExpressionWithPattern:d[@"SeriesNumberRegexString"] options:0 error:NULL];
        if (d[@"SeriesDescriptionRegexString"]) SeriesDescriptionRegex=[NSRegularExpression regularExpressionWithPattern:d[@"SeriesDescriptionRegexString"] options:0  error:NULL];
        if (d[@"ModalityRegexString"]) ModalityRegex=[NSRegularExpression regularExpressionWithPattern:d[@"ModalityRegexString"] options:0 error:NULL];
        if (d[@"SOPClassRegexString"]) SOPClassRegex=[NSRegularExpression regularExpressionWithPattern:d[@"SOPClassRegexString"] options:0 error:NULL];
        if (d[@"SOPClassOffRegexString"]) SOPClassOffRegex = [NSRegularExpression regularExpressionWithPattern:d[@"SOPClassOffRegexString"] options:0 error:NULL];
    }

   
#pragma mark JSON root (from file or new)

   NSMutableDictionary *arc=[NSMutableDictionary dictionaryWithContentsOfFile:d[@"devOIDJSONPath"]];
   if (!arc)
   {
      arc=[NSMutableDictionary dictionaryWithObjectsAndKeys:
      d[@"devOID"], @"arcId",
      @"_proxyURIString_",@"baseUrl",
      nil];
   }

       
#pragma mark plist init
    NSArray *studyPlist=[NSArray arrayWithContentsOfFile:d[@"devOIDPLISTPath"]];
    NSArray *studiesSelected=nil;
    if (d[@"StudyInstanceUIDRegexpString"])
    {
        NSPredicate *studyPredicate = [NSPredicate predicateWithFormat:@"SELF[16] == %@", d[@"StudyInstanceUIDRegexpString"]];
        studiesSelected=[studyPlist filteredArrayUsingPredicate:studyPredicate];
    }
    else if (d[@"studyPredicate"])
    {
       studiesSelected=[studyPlist filteredArrayUsingPredicate:d[@"studyPredicate"]];
    }
    else studiesSelected=studyPlist;

    //patients key from datalist
    NSMutableSet *patientKeySet=[NSMutableSet set];
    for (NSArray *study in studiesSelected)
    {
        [patientKeySet addObject:study[19]];
    }

   
#pragma mark patient loop
   
   NSMutableArray *patientArray=arc[@"patientList"];
   if (!patientArray) {
      patientArray=[NSMutableArray array];
      [arc setObject:patientArray forKey:@"patientList"];
   }
   
   NSMutableArray *ESelected=[NSMutableArray array];
   for (NSString *P in patientKeySet)
   {
      NSMutableArray *studyArray=nil;
      
      NSMutableDictionary *patient=[patientArray firstMutableDictionaryWithKey:@"key" isEqualToNumber:[NSNumber numberWithLongLong:[P longLongValue]]];
      
      NSUInteger Eindex=[studiesSelected nextIndexOfE4P:P startingAtIndex:0];
      [ESelected setArray:studiesSelected[Eindex]];
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
         studyArray=[NSMutableArray array];
         patient=[NSMutableDictionary dictionaryWithObjectsAndKeys:
          [NSNumber numberWithLongLong:[ESelected[dtP] longLongValue]],@"key",
          ESelected[dtPI], @"PatientID",
          [ESelected[dtPN] removeTrailingCarets],@"PatientName",
          ESelected[dtPII],@"IssuerOfPatientID",
          ESelected[dtPdate],@"PatientBirthDate",
          ESelected[dtPsex],@"PatientSex",
          studyArray,@"studyList",
          nil
         ];
         [patientArray addObject:patient];
      }
                           

#pragma mark study loop
      while (Eindex != NSNotFound)
      {
         [ESelected setArray:studiesSelected[Eindex]];

         NSMutableArray *seriesArray=nil;

         NSMutableDictionary *study=[studyArray firstMutableDictionaryWithKey:@"key" isEqualToNumber:[NSNumber numberWithLongLong:[ESelected[dtE] longLongValue]]];

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
         
            seriesArray=[NSMutableArray array];
study=[NSMutableDictionary dictionaryWithObjectsAndKeys:
[NSNumber numberWithLongLong:[ESelected[dtE] longLongValue]],@"key",
ESelected[dtEU], @"StudyInstanceUID",
ESelected[dtEdesc], @"studyDescription",
[DICMTypes DAStringFromDAISOString:ESelected[dtEdate]], @"studyDate",
[DICMTypes TMStringFromTMISOString:ESelected[dtEtime]],@"StudyTime",
ESelected[dtEA],@"AccessionNumber",
ESelected[dtEI],@"StudyID",
[ESelected[dtERN] removeTrailingCarets],@"ReferringPhysicianName",
[ESelected[dtED] removeTrailingCarets],@"NameOfPhysiciansReadingStudy",
ESelected[dtEQAmods],@"modality",
ESelected[dtPI],@"patientId",
ESelected[dtPN],@"patientName",
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
                            ESelected[dtE],
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
                NSArray *instanceSqlPropertiesArray=[instanceData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding stringUnitsPostProcessTitle:sqlDictionary[@"IpostprocessingTitleMain"] dictionary:nil orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding

                           
                        
#pragma mark instance loop
               for (NSArray *instanceSqlProperties in instanceSqlPropertiesArray)
               {
                  switch (getTypeIndex)
                  {
                     case getTypeWado:
                     case getTypeFolderDcm4chee2:
                     case getTypeFolderDcm4cheeArc:
                     {
                        NSString *wadouriInstance=
                        [NSString
                         stringWithFormat:
                         @"_proxyURIString_?requestType=WADO&studyUID=%@&seriesUID=%@&objectUID=%@&session=_sessionString_&custodianOID=%@&arcId=%@%@",
                         study[@"StudyInstanceUID"],
                         seriesSqlProperties[1],
                         instanceSqlProperties[2],
                         devDict[@"custodianoid"],
                         d[@"devOID"],
                         devDict[@"wadouricornerstoneparameters"]
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
         Eindex=[studiesSelected nextIndexOfE4P:P startingAtIndex:Eindex + 1];
      }//end while Eindex != NSNotFound
   }//end for each P
    
   NSData *docData=[NSJSONSerialization dataWithJSONObject:arc options:0 error:nil];
   [docData writeToFile:d[@"devOIDJSONPath"] atomically:YES];
}
@end
