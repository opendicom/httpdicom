#import "DRS+dicomzip.h"
#import "DRS+studyToken.h"

//#import "DRS+datatablesStudy.h"
#import "ResponseWadouri.h"

@implementation DRS (dicomzip)

+(void)dicomzipSql4d:(NSDictionary*)d
{
#pragma mark init
   NSFileManager *defaultManager=[NSFileManager defaultManager];
   NSDictionary *devDict=DRS.pacs[d[@"devOID"]];
      
   //sql
   NSDictionary *sqlcredentials=@{devDict[@"sqlcredentials"]:devDict[@"sqlpassword"]};
   NSString *sqlprolog=devDict[@"sqlprolog"];
   NSDictionary *sqlDictionary=DRS.sqls[devDict[@"sqlmap"]];

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

   
   //prepare regex level series
    NSRegularExpression *SeriesInstanceUIDRegex = nil;
    NSRegularExpression *SeriesNumberRegex = nil;
    NSRegularExpression *SeriesDescriptionRegex = nil;
    NSRegularExpression *ModalityRegex = nil;
    NSRegularExpression *SOPClassRegex = nil;
    NSRegularExpression *SOPClassOffRegex = nil;
    if (d[@"hasSeriesRestriction"])
    {
        if (d[@"SeriesInstanceUIDRegexString"]) SeriesInstanceUIDRegex=[NSRegularExpression regularExpressionWithPattern:d[@"SeriesInstanceUIDRegexString"] options:0 error:NULL];
        if (d[@"SeriesNumberRegexString"]) SeriesNumberRegex=[NSRegularExpression regularExpressionWithPattern:d[@"SeriesNumberRegexString"] options:0 error:NULL];
        if (d[@"SeriesDescriptionRegexString"]) SeriesDescriptionRegex=[NSRegularExpression regularExpressionWithPattern:d[@"SeriesDescriptionRegexString"] options:0  error:NULL];
        if (d[@"ModalityRegexString"]) ModalityRegex=[NSRegularExpression regularExpressionWithPattern:d[@"ModalityRegexString"] options:0 error:NULL];
        if (d[@"SOPClassRegexString"]) SOPClassRegex=[NSRegularExpression regularExpressionWithPattern:d[@"SOPClassRegexString"] options:0 error:NULL];
        if (d[@"SOPClassOffRegexString"]) SOPClassOffRegex = [NSRegularExpression regularExpressionWithPattern:d[@"SOPClassOffRegexString"] options:0 error:NULL];
    }

   
#pragma mark E from datatables plist
   NSArray *studyPlist=[NSArray arrayWithContentsOfFile:[d[@"devOIDPath"]stringByAppendingPathExtension:@"plist"]];
    
    NSArray *studiesSelected=nil;
    if (d[@"StudyInstanceUIDRegexpString"])
    {
        NSPredicate *studyPredicate = [NSPredicate predicateWithFormat:@"SELF[16] == %@", d[@"StudyInstanceUIDRegexpString"]];
        studiesSelected=[studyPlist filteredArrayUsingPredicate:studyPredicate];
    }
    else studiesSelected=studyPlist;
    for (NSArray *study in studiesSelected)
    {
#pragma mark loop E
       
       NSString *EPath=[d[@"devOIDPath"] stringByAppendingPathComponent:study[16]];//E
      
#pragma mark series loop
      NSMutableData *seriesData=[NSMutableData data];
      if (execUTF8Bash(sqlcredentials,
                        [NSString stringWithFormat:
                         sqlDictionary[@"S"],
                         sqlprolog,
                         [study[20] stringValue],
                         @"",
                         sqlRecordThirteenUnits
                         ],
                        seriesData)
          !=0)
      {
         LOG_ERROR(@"zip series db error");
         continue;
      }
      NSArray *seriesSqlPropertiesArray=[seriesData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:3 decreasing:NO];//NSUTF8StringEncoding
       
       NSArray *seriesSelected=nil;
       if (d[@"SeriesInstanceUIDRegexString"])
       {
           NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF[1] == %@", d[@"SeriesInstanceUIDRegexString"]];
           seriesSelected=[seriesSqlPropertiesArray filteredArrayUsingPredicate:predicate];
       }
       else seriesSelected=seriesSqlPropertiesArray;
       for (NSArray *seriesSqlProperties in seriesSelected)
       {
          //add it? (SOPClass = yes)
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
              NSString *SPath=[EPath stringByAppendingPathComponent:seriesSqlProperties[1]];
             NSError *error=nil;
             if (![defaultManager fileExistsAtPath:SPath])
             {
                 if (![defaultManager createDirectoryAtPath:SPath withIntermediateDirectories:YES attributes:nil error:&error]) LOG_ERROR(@"can not create series folder for zip. %@",[error description]);
             }

                        
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
                  LOG_ERROR(@"zip study db error");
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
                  LOG_ERROR(@"zip study db error");
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
                  LOG_ERROR(@"zip study db error");
                  continue;
               }
            }
            NSArray *instanceSqlPropertiesArray=[instanceData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding stringUnitsPostProcessTitle:sqlDictionary[@"IpostprocessingTitleMain"] orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding

                        
                     
#pragma mark instance loop
            for (NSArray *instanceSqlProperties in instanceSqlPropertiesArray)
            {
               NSString *instancePath=[[SPath stringByAppendingPathComponent:instanceSqlProperties[2]]stringByAppendingPathExtension:@"dcm"];
               if (![[NSFileManager defaultManager] fileExistsAtPath:instancePath])
               {
                  switch (getTypeIndex)
                  {
                     case getTypeWado:
                     {
                        NSData *DICMData=
                        [ResponseWadouri
                         DICMFromPacs:devDict
                         EUID:study[DEUID]
                         SUID:seriesSqlProperties[1]
                         IUID:instanceSqlProperties[2]
                         ];
                        if (DICMData)
                           [DICMData writeToFile:instancePath atomically:NO];
                     } break;//end of WADO
                  }//end of GET switch
               }
            }//end for each I
         }//end if SOPClass
      }// end for each S
   }
}

@end
