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
   NSString *devOID=d[@"devOID"];
   NSString *path=[d[@"path"] stringByAppendingPathComponent:devOID];
   NSError  *error=nil;
   NSXMLElement *arcQueryElement=nil;
   
   NSString *XMLString=[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
   if (XMLString) arcQueryElement=[[NSXMLElement alloc]initWithXMLString:XMLString error:&error];
   else if (error) LOG_WARNING(@"reading %@. %@",path,[error description]);
   if (!arcQueryElement)
   {
      if (error)
      {
         LOG_WARNING(@"parsing %@. %@",path,[error description]);
         [[NSFileManager defaultManager] moveItemAtPath:path toPath:[path stringByAppendingPathExtension:@"badxml"] error:nil];
      }
      arcQueryElement=
      [WeasisArcQuery
       arcQueryId:d[@"sessionString"]
       weasisarcId:devOID
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

   
   NSDictionary *devDict=DRS.pacs[devOID];
   NSDictionary *sqlcredentials=@{devDict[@"sqlcredentials"]:devDict[@"sqlpassword"]};
   NSString *sqlprolog=devDict[@"sqlprolog"];
   NSDictionary *sqlDictionary=DRS.sqls[devDict[@"sqlmap"]];
   NSUInteger getTypeIndex=[@[@"file",@"folder",@"wado",@"wadors",@"cget",@"cmove"] indexOfObject:devDict[@"get"]];

   
#pragma mark · apply EP (Study Patient) filters
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
   if (!sqlEPErrorReturned)
   {
      /*
      NSMutableArray *patientArray=nil;
                        patientArray=arc[@"patientList"];
      if (!patientArray)
      {
                           patientArray=[NSMutableArray array];
                           [arc setObject:patientArray forKey:@"patientList"];
      }

      //we prepare GET type
   
   
   switch (getTypeIndex) {
      case NSNotFound:{
         LOG_WARNING(@"studyToken pacs %@ lacks \"get\" property",devOID);
      } break;
      case getTypeWado:{
      } break;//end of WADO
   }// end of GET switch

                                NSRegularExpression *regex=[NSRegularExpression regularExpressionWithPattern:<#(nonnull NSString *)#> options:<#(NSRegularExpressionOptions)#> error:<#(NSError *__autoreleasing  _Nullable * _Nullable)#>];

         //we prepare the eventual additional filters at instance level
         NSString *instanceANDSOPClass=nil;
         if (SOPClassRegex)
         {
            instanceANDSOPClass=
            [NSString stringWithFormat:
             sqlDictionary[@"ANDinstanceSOPClass"],
             [SOPClassRegex pattern]
             ];
         } else instanceANDSOPClass=@"";

         NSString *instanceANDSOPClassOff=nil;
         if (SOPClassOffRegex)
         {
            instanceANDSOPClassOff=
            [NSString stringWithFormat:
             sqlDictionary[@"ANDinstanceSOPClassOff"],
             [SOPClassOffRegex pattern]
             ];
         } else instanceANDSOPClassOff=@"";

         
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
   [docData writeToFile:path atomically:YES];
       
       */

   }
}
@end
