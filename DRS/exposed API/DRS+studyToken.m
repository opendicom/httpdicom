#import "DRS+studyToken.h"
#import "LFCGzipUtility.h"
#import "DICMTypes.h"
#import "NSData+PCS.h"
#import "WeasisDocument.h"
#import "WeasisManifest.h"
#import "WeasisArcQuery.h"
#import "WeasisPatient.h"
#import "WeasisStudy.h"
#import "WeasisSeries.h"
#import "WeasisInstance.h"

const NSInteger selectTypeSql=0;
const NSInteger selectTypeQido=1;
const NSInteger selectTypeCfind=2;

const NSInteger getTypeFile=0;
const NSInteger getTypeFolder=1;
const NSInteger getTypeWado=2;
const NSInteger getTypeWadors=3;
const NSInteger getTypeCget=4;
const NSInteger getTypeCmove=5;

enum accessType{accessTypeWeasis, accessTypeCornerstone, accessTypeDicomzip, accessTypeOsirix, accessTypeDatatablesSeries};

@implementation DRS (studyToken)


// pk.pk/
static NSString *sqlTwoPks=@"\" | awk -F\\t ' BEGIN{ ORS=\"/\"; OFS=\".\";}{print $1, $2}'";



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



-(void)addPostAndGetStudyTokenHandler
{
   [self
    addHandler:@"POST"
    regex:[NSRegularExpression regularExpressionWithPattern:@"/studyToken" options:0 error:NULL]
    processBlock:^(RSRequest* request,RSCompletionBlock completionBlock)
    {
       completionBlock(^RSResponse* (RSRequest* request) {return [DRS studyToken:request];}(request));
    }
   ];

   [self
    addHandler:@"GET"
    regex:[NSRegularExpression regularExpressionWithPattern:@"^/studyToken$" options:0 error:NULL]
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
      LOG_WARNING(@"stuyToken PARAMS error: %@",errorString);
      return [RSErrorResponse responseWithClientError:404 message:@"%@",errorString];
   }
   for (NSUInteger idx=0;idx<[names count];idx++)
   {
      LOG_VERBOSE(@"stuyToken PARAM \"%@\" = \"%@\"",names[idx],values[idx]);
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
   
   //filters
   NSInteger StudyInstanceUIDsIndex=[names indexOfObject:@"StudyInstanceUID"];
   NSInteger AccessionNumberIndex=[names indexOfObject:@"AccessionNumber"];
   NSInteger StudyDateIndex=[names indexOfObject:@"StudyDate"];
   NSInteger PatientIDIndex=[names indexOfObject:@"PatientID"];

   
#pragma mark custodianOID?
   NSInteger custodianOIDIndex=[names indexOfObject:@"custodianOID"];
   if (custodianOIDIndex==NSNotFound)
   {
      LOG_WARNING(@"stuyToken custloianOID not available");
      return [RSErrorResponse responseWithClientError:404 message:@"stuyToken custloianOID not available"];
   }
   
   NSMutableArray *wanCustodianOIDArray=[NSMutableArray array];
   NSMutableArray *devCustodianOIDArray=[NSMutableArray array];
   NSArray *custodianOIDArray=[values[custodianOIDIndex] componentsSeparatedByString:@"\\"];
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
   NSArray *SeriesNumberArray=nil;
   NSInteger SeriesNumberIndex=[names indexOfObject:@"SeriesNumber"];
   if (SeriesNumberIndex!=NSNotFound) SeriesNumberArray=[values[SeriesNumberIndex] componentsSeparatedByString:@"\\"];
   BOOL hasSeriesNumberRestriction=
   (
    SeriesNumberArray
    && [SeriesNumberArray count]
    && [SeriesNumberArray[0] length]
    );

//#pragma mark SeriesDescription
   NSArray *SeriesDescriptionArray=nil;
   NSInteger SeriesDescriptionIndex=[names indexOfObject:@"SeriesDescription"];
   if (SeriesDescriptionIndex!=NSNotFound) SeriesDescriptionArray=[values[SeriesDescriptionIndex] componentsSeparatedByString:@"\\"];
   BOOL hasSeriesDescriptionRestriction=
   (
    SeriesDescriptionArray
    && [SeriesDescriptionArray count]
    && [SeriesDescriptionArray[0] length]
    );

//#pragma mark Modality
   NSArray *ModalityArray=nil;
   NSInteger ModalityIndex=[names indexOfObject:@"Modality"];
   if (ModalityIndex!=NSNotFound) ModalityArray=[values[ModalityIndex]componentsSeparatedByString:@"\\"];
   BOOL hasModalityRestriction=
   (
    ModalityArray
    && [ModalityArray count]
    && [ModalityArray[0] length]
    );

//#pragma mark SOPClass
   NSArray *SOPClassArray=nil;
   NSInteger SOPClassIndex=[names indexOfObject:@"SOPClass"];
   if (SOPClassIndex!=NSNotFound) SOPClassArray=[values[SOPClassIndex]componentsSeparatedByString:@"\\"];
   BOOL hasSOPClassRestriction=
   (
    SOPClassArray
    && [SOPClassArray count]
    && [SOPClassArray[0] length]
    );
   
   
   BOOL hasRestriction=
      hasSeriesNumberRestriction
   || hasSeriesDescriptionRestriction
   || hasModalityRestriction
   || hasSOPClassRestriction;

#pragma mark Patient Study filter formal validity?
   if (StudyInstanceUIDsIndex!=NSNotFound)
   {
      if (
            (AccessionNumberIndex!=NSNotFound)
          ||(StudyDateIndex!=NSNotFound)
          ||(PatientIDIndex!=NSNotFound)
          ) [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken StudyInstanceUID shoud not be present together with AccessionNumber or StudyDate or PatientID"];
      for (NSString *uid in [values[StudyInstanceUIDsIndex]componentsSeparatedByString:@"\\"])
      {
         if (![DICMTypes isSingleUIString:uid])[RSErrorResponse responseWithClientError:404 message:@"studyToken no StudyInstanceUID found in %@",uid];
      }
   }
   else if (AccessionNumberIndex!=NSNotFound)
   {
      if (
            (StudyDateIndex!=NSNotFound)
          ||(PatientIDIndex!=NSNotFound)
          ) [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken AccessionNumber shoud not be present together with StudyDate or PatientID"];
   }
   else if ((PatientIDIndex==NSNotFound)||(StudyDateIndex==NSNotFound)) [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken one of StudyInstanceUID, AccessionNumber or PatientID+StudyDate should be present"];

   



#pragma mark -
#pragma mark ACCESS switch

   NSInteger accessTypeIndex=[names indexOfObject:@"accessType"];
   if (accessTypeIndex==NSNotFound) [RSErrorResponse responseWithClientError:404 message:@"studyToken accessType required in request"];
   NSInteger accessType=[@[@"weasis",@"cornerstone",@"dicomzip",@"osirix",@"datatablesSeries"]  indexOfObject:values[accessTypeIndex]];
   if (accessType==NSNotFound) [RSErrorResponse responseWithClientError:404 message:@"studyToken accessType %@ unknown",values[accessTypeIndex]];

   
/*
 switch (accessType) {
    case accessTypeWeasis:{
       } break;//end of sql wado weasis
    case accessTypeCornerstone:{
       } break;//end of sql wado cornerstone
    case accessTypeDicomzip:{
       } break;//end of sql wado dicomzip
    case accessTypeOsirix:{
       } break;//end of sql wado osirix
    case accessTypeDatatablesSeries:{
       } break;//end of sql wado osirix
 }
 */
   NSXMLElement *XMLRoot=nil;
   switch (accessType) {
      case accessTypeWeasis:{
         XMLRoot=[WeasisManifest manifest];
      } break;//end of sql wado weasis
   }
   
   NSMutableArray *JSONArray=nil;

         
#pragma mark dev loop
   
   for (NSString *custodianOIDString in devCustodianOIDArray)
   {
      
NSXMLElement *arcQueryElement=nil;
NSMutableArray *patientArray=nil;
      
      switch (accessType) {
         case accessTypeWeasis:{
            arcQueryElement=
            [WeasisArcQuery
             arcQueryOID:custodianOIDString
             custodian:proxyURIString
             session:sessionString
             seriesIds:SeriesNumberArray
             seriesDescriptions:SeriesDescriptionArray
             modalities:ModalityArray
             SOPClasses:SOPClassArray
             overrideDicomTagsList:@""
             ];
            [XMLRoot addChild:arcQueryElement];
            } break;//end of sql wado weasis
         case accessTypeCornerstone:{
            patientArray=[NSMutableArray array];
            [JSONArray addObject:
             @{
               @"arcId":custodianOIDString,
               @"baseUrl":proxyURIString,
               @"additionnalParameters":[NSString stringWithFormat:@"&amp;session=%@&amp;custodianOID=%@&amp;SeriesDescription=%@&amp;Modality=%@&amp;SOPClass=%@",
                                         sessionString,
                                         custodianOIDString,
                                         [SeriesDescriptionArray componentsJoinedByString:@"\\"],
                                         [ModalityArray componentsJoinedByString:@"\\"],
                                         [SOPClassArray componentsJoinedByString:@"\\"]
                                         ],
               @"overrideDicomTagsList":@"",
               @"patientList":patientArray
               }
             ];

            } break;//end of sql wado cornerstone
         case accessTypeDicomzip:{
            patientArray=[NSMutableArray array];
            /*
             - create
             {
               pacsUID:[{
                  studyUID:[{
                     seriesUID:[
                        instanceUID,
             */
            
            } break;//end of sql wado dicomzip
         case accessTypeOsirix:{
            patientArray=[NSMutableArray array];
            } break;//end of sql wado osirix
         case accessTypeDatatablesSeries:{
            patientArray=[NSMutableArray array];
            } break;//end of sql wado osirix
      }
      
      
#pragma mark · SELECT switch
      switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:(DRS.pacs[custodianOIDString])[@"select"]]) {
         
         case NSNotFound:{
            LOG_WARNING(@"studyToken pacs %@ lacks \"select\" property",custodianOIDString);
         } break;
            
         case selectTypeSql:{
#pragma mark · SQL SELECT (unique option for now)
            NSDictionary *sqlcredentials=@{(DRS.pacs[custodianOIDString])[@"sqluser"]:(DRS.pacs[custodianOIDString])[@"sqlpassword"]};
            NSString *sqlprolog=(DRS.pacs[custodianOIDString])[@"sqlprolog"];
            NSDictionary *sqlDictionary=DRS.sqls[(DRS.pacs[custodianOIDString])[@"sqlmap"]];

            
#pragma mark · apply Patient Study filters
      
            NSMutableDictionary *EPDict=[NSMutableDictionary dictionary];
            NSMutableData *mutableData=[NSMutableData data];

//#pragma mark StudyInstanceUID
            
            if (StudyInstanceUIDsIndex!=NSNotFound)
            {
               for (NSString *uid in [values[StudyInstanceUIDsIndex]componentsSeparatedByString:@"\\"])
               {
                  //find patient fk
                  [mutableData setData:[NSData data]];
                  
                  if (execUTF8Bash(sqlcredentials,
                                    [NSString stringWithFormat:
                                     sqlDictionary[@"sqlPE4Euid"],
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
               }
            }
            else //AccessionNumber or PatientID + StudyDate
            {
                if (AccessionNumberIndex!=NSNotFound)
                {
                   [mutableData setData:[NSData data]];
                   if (execUTF8Bash(sqlcredentials,
                                     [NSString stringWithFormat:
                                      sqlDictionary[@"sqlPE4Ean"],
                                      sqlprolog,
                                      values[AccessionNumberIndex],
                                      @"",
                                      sqlTwoPks
                                      ],
                                     mutableData)
                       !=0)
                   {
                      LOG_ERROR(@"studyToken accessionNumber db error");
                      continue;
                   }
                }
                else if ((PatientIDIndex!=NSNotFound)&&(StudyDateIndex!=NSNotFound))
                {
                    //issuer?
                    [mutableData setData:[NSData data]];
                    if (execUTF8Bash(sqlcredentials,
                                     [NSString stringWithFormat:
                                      sqlDictionary[@"sqlPE4PidEda"],
                                      sqlprolog,
                                      values[PatientIDIndex],
                                      values[StudyDateIndex],
                                      @"",
                                      sqlTwoPks
                                      ],
                                     mutableData)
                        !=0)
                    {
                        LOG_ERROR(@"studyToken PatientID or StudyDate db error");
                        continue;
                    }
                }
            
                if ([mutableData length]==0)
                {
                  LOG_VERBOSE(@"studyToken empty response");
                  continue;
                }
                for (NSString *pkdotpk in [[[NSString alloc]initWithData:mutableData encoding:NSUTF8StringEncoding]componentsSeparatedByString:@"/"])
                {
                    if (pkdotpk.length) [EPDict setObject:[pkdotpk pathExtension] forKey:[pkdotpk stringByDeletingPathExtension]];
                }
                //record terminated by /
            }
      
      
#pragma mark ·· GET switch
            switch ([@[@"file",@"folder",@"wado",@"wadors",@"cget",@"cmove"] indexOfObject:(DRS.pacs[custodianOIDString])[@"get"]]) {
                  
               case NSNotFound:{
                  LOG_WARNING(@"studyToken pacs %@ lacks \"get\" property",custodianOIDString);
               } break;

               case getTypeWado:{
#pragma mark ·· WADO (unique option for now)
                  
#pragma mark ...patient loop
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
NSMutableArray *studyArray=nil;
                        
                     NSArray *patientPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding

                     switch (accessType) {
                           
                        case accessTypeWeasis:{
                           PatientElement=
                           [
                            WeasisPatient
                            pk:(patientPropertiesArray[0])[0]
                            pid:(patientPropertiesArray[0])[1]
                            name:(patientPropertiesArray[0])[2]
                            issuer:(patientPropertiesArray[0])[3]
                            birthdate:(patientPropertiesArray[0])[4]
                            sex:(patientPropertiesArray[0])[5]
                            ];
                           [arcQueryElement addChild:PatientElement];
                           } break;//end of sql wado weasis
                        case accessTypeCornerstone:{
                           studyArray=[NSMutableArray array];
                           [patientArray addObject:
                            @{
                              @"PatientID":(patientPropertiesArray[0])[1],
                              @"PatientName":(patientPropertiesArray[0])[2],
                              @"IssuerOfPatientID":(patientPropertiesArray[0])[3],
                              @"PatientBirthDate":(patientPropertiesArray[0])[4],
                              @"PatientSex":(patientPropertiesArray[0])[5],
                              @"studyList":studyArray
                              }];
                           
                           } break;//end of sql wado cornerstone
                        case accessTypeDicomzip:{
                           studyArray=[NSMutableArray array];
                           } break;//end of sql wado dicomzip
                        case accessTypeOsirix:{
                           studyArray=[NSMutableArray array];
                           } break;//end of sql wado osirix
                        case accessTypeDatatablesSeries:{
                           studyArray=[NSMutableArray array];
                           } break;//end of sql wado osirix
                     }

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
NSMutableArray *seriesArray=nil;
                        NSArray *EPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:3 decreasing:YES];//NSUTF8StringEncoding
                        
                        
                        NSString *StudyDateString=[NSString stringWithFormat:@"%@%@%@",
                                                   [(EPropertiesArray[0])[3]substringWithRange:NSMakeRange(0,4)],
                                                   [(EPropertiesArray[0])[3]substringWithRange:NSMakeRange(5,2)],
                                                   [(EPropertiesArray[0])[3]substringWithRange:NSMakeRange(8,2)]
                                                   ];
                        NSString *StudyTimeString=[NSString stringWithFormat:@"%@%@%@",
                                                   [(EPropertiesArray[0])[4]substringWithRange:NSMakeRange(0,2)],
                                                   [(EPropertiesArray[0])[4]substringWithRange:NSMakeRange(3,2)],
                                                   [(EPropertiesArray[0])[4]substringWithRange:NSMakeRange(6,2)]
                                                   ];
                        switch (accessType) {
                              
                           case accessTypeWeasis:{
                              StudyElement=
                              [
                               WeasisStudy
                               pk:(EPropertiesArray[0])[0]
                               uid:(EPropertiesArray[0])[1]
                               desc:(EPropertiesArray[0])[2]
                               date:StudyDateString
                               time:StudyTimeString
                               an:(EPropertiesArray[0])[5]
                               issuer:nil
                               type:nil
                               eid:(EPropertiesArray[0])[6]
                               ref:(EPropertiesArray[0])[7]
                               img:(EPropertiesArray[0])[8]
                               mod:(EPropertiesArray[0])[9]
                               ];
                              [PatientElement addChild:StudyElement];
                               } break;//end of sql wado weasis
                           case accessTypeCornerstone:{
#pragma mark ··· CORNERSTONE (TODO remove limitation)
                              if ([EPDict count]>1) [RSErrorResponse responseWithClientError:404 message:@"%@",@"accessType cornerstone can not be applied to more than a study"];
                              /*
                               cornerstone
                               ============
                               patientName
                               patientId
                               studyDate
                               modality (in Study)
                               studyDescription
                               numImages
                               studyId
                               */
                              seriesArray=[NSMutableArray array];
                              [studyArray addObject:
                               @{
                                 @"StudyInstanceUID":(EPropertiesArray[0])[1],
                                 @"studyDescription":(EPropertiesArray[0])[2],
                                 @"studyDate":StudyDateString,
                                 @"StudyTime":StudyTimeString,
                                 @"AccessionNumber":(EPropertiesArray[0])[5],
                                 @"StudyID":(EPropertiesArray[0])[6],
                                 @"ReferringPhysicianName":(EPropertiesArray[0])[7],
                                 @"numImages":(EPropertiesArray[0])[8],
                                 @"modality":(EPropertiesArray[0])[9],
                                 @"patientId":(patientPropertiesArray[0])[1],
                                 @"patientName":(patientPropertiesArray[0])[2],
                                 @"seriesList":seriesArray
                                 }];
                              } break;//end of sql wado cornerstone
                           case accessTypeDicomzip:{
                              seriesArray=[NSMutableArray array];
                              } break;//end of sql wado dicomzip
                           case accessTypeOsirix:{
                              seriesArray=[NSMutableArray array];
                              } break;//end of sql wado osirix
                           case accessTypeDatatablesSeries:{
                              seriesArray=[NSMutableArray array];
                              } break;//end of sql wado osirix
                        }

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
                           
                           //do not add empty series
                           if ([IPropertiesFirstRecord count]==0) continue;

                            //dicom cda
                           if ([(IPropertiesFirstRecord[0])[3] isEqualToString:@"1.2.840.10008.5.1.4.1.1.104.2"]) continue;
                           //SR
                           if ([(IPropertiesFirstRecord[0])[3] hasPrefix:@"1.2.840.10008.5.1.4.1.1.88"])continue;
                          
                          //if there is restriction and does't match
                           if (
                               hasRestriction
                               &&(hasSeriesDescriptionRestriction && [SeriesDescriptionArray indexOfObject:SProperties[2]]==NSNotFound)
                               &&(hasModalityRestriction && [ModalityArray indexOfObject:SProperties[4]]==NSNotFound)
                               &&(hasSOPClassRestriction && [SOPClassArray indexOfObject:IPropertiesFirstRecord[3]]==NSNotFound)
                               ) continue;
                           
                           
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
NSXMLElement *SeriesElement=nil;//Study=Exam
NSMutableArray *instanceArray=nil;                                                                                    switch (accessType) {
                              case accessTypeWeasis:{
                                 SeriesElement=[WeasisSeries pk:SProperties[0]
                                  uid:SProperties[1]
                                 desc:SProperties[2]
                                  num:SProperties[3]
                                  mod:SProperties[4]
                                  wts:@"*"
                                  sop:(IPropertiesFirstRecord[0])[3]
                                                ];//DirectDownloadThumbnail=\"%@\"
                                 [StudyElement addChild:SeriesElement];
                                 } break;//end of sql wado weasis
                              case accessTypeCornerstone:{
                                 /*
                                  seriesList
                                  ==========
                                  not for OT nor DOC
                                  
                                  seriesDescription
                                  seriesNumber
                                  */
                                 instanceArray=[NSMutableArray array];
                                 [seriesArray addObject:
                                 @{
                                   @"seriesDescription":SProperties[2],
                                   @"seriesNumber":SProperties[3],
                                   @"SeriesInstanceUID":SProperties[1],
                                   @"Modality":SProperties[4],
                                   @"WadoTransferSyntaxUID":@"*",
                                   @"instanceList":instanceArray
                                   }];
                              } break;//end of sql wado cornerstone
                              case accessTypeDicomzip:{
                                 instanceArray=[NSMutableArray array];
                                 } break;//end of sql wado dicomzip
                              case accessTypeOsirix:{
                                 instanceArray=[NSMutableArray array];
                                 } break;//end of sql wado osirix
                              case accessTypeDatatablesSeries:{
                                 instanceArray=[NSMutableArray array];
                                 } break;//end of sql wado osirix
                           }


//#pragma mark instance loop
                           for (NSArray *IProperties in IPropertiesArray)
                           {
//#pragma mark instance loop
NSXMLElement *InstanceElement=nil;//Study=Exam
                              switch (accessType) {
                                 case accessTypeWeasis:{
                                    InstanceElement=[WeasisInstance pk:IProperties[0]
                                     uid:IProperties[1]
                                     num:IProperties[2]
                                                     ];//DirectDownloadFile
                                    [SeriesElement addChild:InstanceElement];
                                    } break;//end of sql wado weasis
                                 case accessTypeCornerstone:{
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

                                    } break;//end of sql wado cornerstone
                                 case accessTypeDicomzip:{
                                    } break;//end of sql wado dicomzip
                                 case accessTypeOsirix:{
                                    } break;//end of sql wado osirix
                                 case accessTypeDatatablesSeries:{
                                    } break;//end of sql wado osirix
                                 }
                              }
                           }//end for each I
                        }// end for each S
                     }//end for each E
                  }//end for each P
               } break;//end of WADO
            }// end of GET switch
         } break;//end of sql
      } //end of SELECT switch
   }
#pragma mark wan loop
    NSLog(@"%@",[XMLRoot description]);
   for (NSString *custodianOIDString in wanCustodianOIDArray)
   {
      NSLog(@"%@",custodianOIDString);
   }
   
   return [RSErrorResponse responseWithClientError:404 message:@"studyToken should not be here"];

   }
@end

/*
                     return [RSDataResponse
                             responseWithData:[LFCGzipUtility gzipData:[xmlweasismanifest dataUsingEncoding:NSUTF8StringEncoding]]
                             contentType:@"application/x-gzip"
                             ];

 //base64 dicom:get -i does not work
 
 RSDataResponse *response=[RSDataResponse responseWithData:[[[LFCGzipUtility gzipData:[xmlweasismanifest dataUsingEncoding:NSUTF8StringEncoding]] base64EncodedStringWithOptions:0]dataUsingEncoding:NSUTF8StringEncoding] contentType:@"application/x-gzip"];
 [response setValue:@"Base64" forAdditionalHeader:@"Content-Transfer-Encoding"];//https://tools.ietf.org/html/rfc2045
 return response;
 
 //xml dicom:get -iw works also, like with gzip
 return [RSDataResponse
 responseWithData:[xmlweasismanifest dataUsingEncoding:NSUTF8StringEncoding]
 contentType:@"text/xml"];
 
 
 NSData *cornerstoneJson=[NSJSONSerialization dataWithJSONObject:responseArray options:0 error:nil];
 LOG_DEBUG(@"cornerstone manifest :\r\n%@",[[NSString alloc] initWithData:cornerstoneJson encoding:NSUTF8StringEncoding]);
 return [RSDataResponse responseWithData:cornerstoneJson contentType:@"application/json"];
 */
