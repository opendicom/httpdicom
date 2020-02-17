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

      NSArray *patientArray=[arcQueryElement elementsForName:@"PatientElement"];
      NSMutableDictionary *patientDictionary=[NSMutableDictionary dictionary];
      for (NSXMLElement *cachedPatient in patientArray)
      {
         [patientDictionary setObject:cachedPatient forKey:[cachedPatient attributeForName:@"key"]];
      }
         
#pragma mark ...patient loop
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
               [WeasisPatient key:(patientSqlPropertiesArray[0])[0] weasisPatientID:(patientSqlPropertiesArray[0])[1] weasisPatientName:(patientSqlPropertiesArray[0])[2] weasisIssuerOfPatientID:(patientSqlPropertiesArray[0])[3] weasisPatientBirthDate:(patientSqlPropertiesArray[0])[4] weasisPatientBirthTime:nil weasisPatientSex:(patientSqlPropertiesArray[0])[5]
                ];
               [arcQueryElement addChild:PatientElement];
            }

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
                                     sqlRecordFiveUnits
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

   NSXMLDocument *doc=[NSXMLDocument documentWithRootElement:weasisArcQuery];
   doc.documentContentKind=NSXMLDocumentXMLKind;
   //doc.characterEncoding=@"UTF-8";
   doc.standalone=true;
   NSData *docData=[doc XMLData];
   [docData writeToFile:[[d[@"path"] stringByAppendingPathComponent:devOID]stringByAppendingPathExtension:@"xml"] atomically:YES];
       

   }
}
@end

//    NSRegularExpression *regex=[NSRegularExpression regularExpressionWithPattern:<#(nonnull NSString *)#> options:<#(NSRegularExpressionOptions)#> error:<#(NSError *__autoreleasing  _Nullable * _Nullable)#>];
