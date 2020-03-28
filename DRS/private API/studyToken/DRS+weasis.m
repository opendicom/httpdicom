#import "DRS+weasis.h"
#import "DRS+studyToken.h"

#import "WeasisArcQuery.h"
#import "WeasisPatient.h"
#import "WeasisStudy.h"
#import "WeasisSeries.h"
#import "WeasisInstance.h"

#import "NSArray+PCS.h"

@implementation DRS (weasis)

+(void)weasisSql4dictionary:(NSDictionary*)d
{
   NSDictionary *devDict=DRS.pacs[d[@"devOID"]];
   
#pragma mark sql inits
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
 
#pragma mark xml init
    NSError  *error=nil;
    NSXMLElement *arcQueryElement=nil;
    NSString *XMLString=[NSString stringWithContentsOfFile:d[@"devOIDXMLPath"] encoding:NSUTF8StringEncoding error:nil];
    if (XMLString) arcQueryElement=[[NSXMLElement alloc]initWithXMLString:XMLString error:&error];
    if (!arcQueryElement)
    {
       if (error) [[NSFileManager defaultManager] moveItemAtPath:d[@"devOIDXMLPath"] toPath:[d[@"devOIDXMLPath"] stringByAppendingPathExtension:@"badxml"] error:nil];
       arcQueryElement=
       [WeasisArcQuery
        weasisarcId:d[@"devOID"]
        weasiswebLogin:nil
        weasisrequireOnlySOPInstanceUID:nil
        weasisadditionnalParameters:d[@"wadoweasisparameters"]
        weasisoverrideDicomTagsList:nil
        seriesFilterInstanceUID:d[@"SeriesInstanceUIDRegexString"]
        seriesFilterNumber:d[@"SeriesNumberRegexString"]
        seriesFilterDescription:d[@"SeriesDescriptionRegexString"]
        seriesFilterModality:d[@"ModalityRegexString"]
        seriesFilterSOPClass:d[@"SOPClassRegexString"]
        seriesFilterSOPClassOff:d[@"SOPClassOffRegexString"]
       ];
    }
    NSArray *patientArray=[arcQueryElement elementsForName:@"Patient"];
    NSMutableDictionary *patientDictionary=[NSMutableDictionary dictionary];
    for (NSXMLElement *cachedPatient in patientArray)
    {
       [patientDictionary setObject:cachedPatient forKey:[[cachedPatient attributeForName:@"key"]stringValue]];
    }

    
    
#pragma mark plist init
    NSArray *studyPlist=[NSArray arrayWithContentsOfFile:d[@"devOIDPLISTPath"]];
    NSArray *studiesSelected=nil;
    if (d[@"StudyInstanceUIDRegexpString"])
    {
        NSPredicate *studyPredicate = [NSPredicate predicateWithFormat:@"SELF[16] == %@", d[@"StudyInstanceUIDRegexpString"]];
        studiesSelected=[studyPlist filteredArrayUsingPredicate:studyPredicate];
    }
    else studiesSelected=studyPlist;

    //patients key from datalist
    NSMutableSet *patientKeySet=[NSMutableSet set];
    for (NSArray *study in studiesSelected)
    {
        [patientKeySet addObject:study[19]];
    }


/*
 NSString *EPath=[d[@"devOIDPath"] stringByAppendingPathComponent:study[16]];
 */
#pragma mark patient loop
  NSMutableArray *ESelected=[NSMutableArray array];
  for (NSString *P in patientKeySet)
  {
     NSUInteger Eindex=[studiesSelected nextIndexOfE4P:P startingAtIndex:0];
     [ESelected setArray:studiesSelected[Eindex]];
     NSXMLElement *PatientElement=patientDictionary[P];
     if (!PatientElement)
     {
        PatientElement=
        [WeasisPatient key:ESelected[dtP]
         weasisPatientID:ESelected[dtPI]
         weasisPatientName:ESelected[dtPN]
         weasisIssuerOfPatientID:ESelected[dtPII]
         weasisPatientBirthDate:ESelected[dtPdate]
         weasisPatientBirthTime:nil
         weasisPatientSex:ESelected[dtPsex]
         ];
        [arcQueryElement addChild:PatientElement];
     }


     NSArray *studyArray=[PatientElement elementsForName:@"Study"];
     NSMutableDictionary *studyDictionary=[NSMutableDictionary dictionary];
     for (NSXMLElement *cachedStudy in studyArray)
     {
        [studyDictionary setObject:cachedStudy forKey:[[cachedStudy attributeForName:@"key"]stringValue]];
     }
      
#pragma mark study loop
     while (Eindex != NSNotFound)
     {
        [ESelected setArray:studiesSelected[Eindex]];

        NSXMLElement *StudyElement=studyDictionary[ESelected[dtE]];//Study=Exam
           if (!StudyElement)
           {
               // no issuer
               
              StudyElement=
              [WeasisStudy
               key:ESelected[dtE]
               weasisStudyInstanceUID:ESelected[dtEU]
               weasisStudyDescription:ESelected[dtEdesc]
               weasisStudyDate:[DICMTypes DAStringFromDAISOString:ESelected[dtEdate]]
               weasisStudyTime:[DICMTypes TMStringFromTMISOString:ESelected[dtEtime]]
               weasisAccessionNumber:ESelected[dtEA]
               weasisStudyId:ESelected[dtEI]
               weasisReferringPhysicianName:ESelected[dtERN]
               readingPhysicianName:ESelected[dtED]
               issuer:nil
               issuerType:nil
               series:ESelected[dtEQAseries]
               modalities:ESelected[dtEQAmods]
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
                              ESelected[dtE],
                              @"",
                              sqlRecordThirteenUnits
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
                 NSArray *instanceSqlPropertiesArray=[instanceData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding stringUnitsPostProcessTitle:sqlDictionary[@"IpostprocessingTitleMain"] dictionary:nil orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding


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
            
            Eindex=[studiesSelected nextIndexOfE4P:P startingAtIndex:Eindex + 1];
         }//end while Eindex != NSNotFound
      }//end for each P

   NSXMLDocument *doc=[NSXMLDocument documentWithRootElement:arcQueryElement];

//adds headers to the documents...DO NOT USE THEM to facilitate composition
   //doc.documentContentKind=NSXMLDocumentXMLKind;
   //doc.characterEncoding=@"UTF-8";
   //doc.standalone=true;
   NSData *docData=[doc XMLData];
   [docData writeToFile:d[@"devOIDXMLPath"] atomically:YES];
}
@end
