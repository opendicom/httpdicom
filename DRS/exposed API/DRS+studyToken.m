#import "DRS+studyToken.h"
#import "LFCGzipUtility.h"
#import "DICMTypes.h"
#import "NSData+PCS.h"

const NSInteger selectTypeSql=0;
const NSInteger selectTypeQido=1;
const NSInteger selectTypeCfind=2;

const NSInteger getTypeFile=0;
const NSInteger getTypeFolder=1;
const NSInteger getTypeWado=2;
const NSInteger getTypeWadors=3;
const NSInteger getTypeCget=4;
const NSInteger getTypeCmove=5;

const NSInteger accessTypeWeasis=0;
const NSInteger accessTypeCornerstone=1;
const NSInteger accessTypeDicomzip=2;
const NSInteger accessTypeOsirix=3;

@implementation DRS (studyToken)

static NSString *sqlConnect=@"/usr/local/mysql/bin/mysql --raw --skip-column-names -upcs -h 192.168.250.1 -b pacsdb2 -e \"";

// pkstudy.pkpatient/
static NSString *sqlTwoPks=@"\" | awk -F\\t ' BEGIN{ ORS=\"/\"; OFS=\".\";}{print $1, $2}' | sed -e 's/\\/$//'";



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

static NSString *sqlPE4Ean=@"%@SELECT pk,patient_fk FROM study WHERE accession_no='%@' %@ %@";//limit 10

static NSString *sqlPE4Euid=@"%@SELECT pk,patient_fk FROM study WHERE study_iuid='%@' %@ %@";

static NSString *sqlPE4PidEda=@"%@SELECT study.pk,study.patient_fk FROM study LEFT JOIN patient ON study.patient_fk=patient.pk WHERE patient.pat_id='%@' AND DATE(study.study_datetime)='%@' %@ %@";//limit 10

//patient fields
static NSString *sqlP=@"%@SELECT pk,pat_id,pat_name,pat_id_issuer,pat_birthdate,pat_sex FROM patient WHERE pk='%@' %@ %@";

//studyFields
static NSString *sqlE=@"%@SELECT pk,study_iuid,study_desc,DATE(study_datetime),TIME(study_datetime),accession_no,study_id,ref_physician,num_instances,mods_in_study FROM study WHERE pk='%@' %@ %@";

//seriesFields
static NSString *sqlS=@"%@SELECT pk,series_iuid,series_desc,series_no,modality FROM series WHERE study_fk='%@' %@ %@";


//instancesFields
static NSString *sqlI=@"%@SELECT pk,sop_iuid,inst_no,sop_cuid FROM instance WHERE series_fk='%@' %@ %@";



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
   NSString *custodianOIDString=nil;
   if (custodianOIDIndex==NSNotFound)
   {
      LOG_WARNING(@"stuyToken custloianOID not available");
      return [RSErrorResponse responseWithClientError:404 message:@"stuyToken custloianOID not available"];
   }
   
#pragma mark TODO proxying to another PCS if no localoid
   
   custodianOIDString=values[custodianOIDIndex];

   
   
#pragma mark - SELECT switch
   switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:(DRS.pacs[custodianOIDString])[@"select"]]) {
      
      case NSNotFound:{
         [RSErrorResponse responseWithClientError:404 message:@"studyToken pacs %@ lacks \"select\" property",custodianOIDString];
      } break;
         
      case selectTypeSql:{
#pragma mark · SQL
   
         NSDictionary *sqlcredentials=@{(DRS.pacs[custodianOIDString])[@"sqluser"]:(DRS.pacs[custodianOIDString])[@"sqlpassword"]};

         NSDictionary *sqlDictionary=DRS.sqls[(DRS.pacs[custodianOIDString])[@"sqlmap"]];

#pragma mark · filtros
   
   /*
    Using only one of StudyInstanceUID, AccessionNumber or PatientID+StudyDate
    to create a dictionary studyInstanceUID:patientpk
    Reject if there is more than one
    */
   NSMutableDictionary *EPDict=[NSMutableDictionary dictionary];
   NSMutableData *mutableData=[NSMutableData data];

//#pragma mark StudyInstanceUID
   
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
         //find patient fk
         [mutableData setData:[NSData data]];
         
         if (!execUTF8Bash(sqlcredentials,
                           [NSString stringWithFormat:
                            sqlPE4Euid,
                            sqlConnect,
                            uid,
                            @"",
                            sqlTwoPks
                            ],
                           mutableData)
             )
            [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken StudyInstanceUID db error"];
         if (![mutableData length]) [RSErrorResponse responseWithClientError:404 message:@"studyToken StudyInstanceUID  %@ does not exist",uid];
         NSString *EPString=[[[NSString alloc]initWithData:mutableData encoding:NSUTF8StringEncoding] stringByDeletingLastPathComponent];//record terminated by /
         [EPDict setObject:[EPString pathExtension] forKey:[EPString stringByDeletingPathExtension]];
      }
   }
   else
   {
      if (AccessionNumberIndex!=NSNotFound)
      {
//#pragma mark AccessionNumber
         if (
               (StudyDateIndex!=NSNotFound)
             ||(PatientIDIndex!=NSNotFound)
             ) [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken AccessionNumber shoud not be present together with StudyDate or PatientID"];
         //issuer?
         
         //find corresponding EP
         [mutableData setData:[NSData data]];
         if (!execUTF8Bash(sqlcredentials,
                           [NSString stringWithFormat:
                            sqlPE4Ean,
                            sqlConnect,
                            values[AccessionNumberIndex],
                            @"",
                            sqlTwoPks
                            ],
                           mutableData)
             )
            [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken accessionNumber error"];
      }
      else if ((PatientIDIndex!=NSNotFound)&&(StudyDateIndex!=NSNotFound))
      {
//#pragma mark PatientID+StudyDate
         //issuer?
         
         //find corresponding EP
         [mutableData setData:[NSData data]];
         if (!execUTF8Bash(sqlcredentials,
                           [NSString stringWithFormat:
                            sqlPE4PidEda,
                            sqlConnect,
                            values[PatientIDIndex],
                            values[StudyDateIndex],
                            @"",
                            sqlTwoPks
                            ],
                           mutableData)
             ) [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken PatientID or StudyDate error"];
      }
      else [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken one of StudyInstanceUID, AccessionNumber or PatientID+StudyDate should be present"];

      
      //for both AccessionNumber or PatientID+StudyDate, check if mutableData
      if ([mutableData length]<2) [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken AccessionNumber or PatientID+StudyDate did not select any study"];
      
      for (NSString *EPString in [[[NSString alloc]initWithData:mutableData encoding:NSUTF8StringEncoding] pathComponents])
      {
         [EPDict setObject:[EPString pathExtension] forKey:[EPString stringByDeletingPathExtension]];
      }
   }
   
   
   
#pragma mark · series restriction in query?

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
   
#pragma mark · GET switch
         switch ([@[@"file",@"folder",@"wado",@"wadors",@"cget",@"cmove"] indexOfObject:(DRS.pacs[custodianOIDString])[@"get"]]) {
               
            case NSNotFound:{
               [RSErrorResponse responseWithClientError:404 message:@"studyToken pacs %@ lacks \"get\" property",custodianOIDString];
            } break;

            case getTypeFile:{
#pragma mark ·· FILE
               [RSErrorResponse responseWithClientError:404 message:@"studyToken sql file not implemented yet"];
            } break;//end of getTypeFile

            case getTypeFolder:{
#pragma mark ·· FOLDER
               [RSErrorResponse responseWithClientError:404 message:@"studyToken sql folder not implemented yet"];
            } break;//end of getTypeFolder

            case getTypeWado:{
#pragma mark ·· WADO

               
#pragma mark ·· ACCESS switch
   
               NSInteger accessTypeIndex=[names indexOfObject:@"accessType"];
               if (accessTypeIndex==NSNotFound) [RSErrorResponse responseWithClientError:404 message:@"studyToken accessType required in request"];
               
               switch ([@[@"weasis",@"cornerstone",@"dicomzip",@"osirix"] indexOfObject:values[accessTypeIndex]]) {
                     
                  case NSNotFound:{
                     [RSErrorResponse responseWithClientError:404 message:@"studyToken accessType \"%@\" unknown",values[accessTypeIndex]];
                  } break;
                     
                  case accessTypeWeasis:{
#pragma mark ··· WEASIS
                     NSMutableString *xmlweasismanifest=[NSMutableString string];
   
//#pragma mark arcQuery
                     [xmlweasismanifest appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\r"];
                     [xmlweasismanifest appendString:@"<manifest xmlns=\"http://www.weasis.org/xsd/2.5\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">\r"];
/*
 <xsd:attribute name="arcId" type="xsd:string" use="required" />
 <xsd:attribute name="baseUrl" type="xsd:anyURI" use="required" />
 <xsd:attribute name="webLogin" type="xsd:string" />
 <xsd:attribute name="requireOnlySOPInstanceUID" type="xsd:boolean" />
 <xsd:attribute name="additionnalParameters" type="xsd:string" />
 <!-- &session (in additionnalParameters)-->
 <!-- &custodianOID (in additionnalParameters) -->
 <xsd:attribute name="overrideDicomTagsList" type="dicomTagsList" />
 */
                     [xmlweasismanifest appendFormat:@"<arcQuery arcId=\"%@\" baseUrl=\"%@\" additionnalParameters=\"&amp;session=%@&amp;custodianOID=%@&amp;SeriesDescription=%@&amp;Modality=%@&amp;SOPClass=%@\" overrideDicomTagsList=\"%@\">\r",
                      custodianOIDString,
                      proxyURIString,
                      sessionString,
                      custodianOIDString,
                      [SeriesDescriptionArray componentsJoinedByString:@"\\"],
                      [ModalityArray componentsJoinedByString:@"\\"],
                      [SOPClassArray componentsJoinedByString:@"\\"],
                      @""
                      ];
                     
//#pragma mark patient loop
                     
                     for (NSString *P in [NSSet setWithArray:[EPDict allValues]])
                     {
                        [mutableData setData:[NSData data]];
                        if (!execUTF8Bash(sqlcredentials,
                                          [NSString stringWithFormat:
                                           sqlP,
                                           sqlConnect,
                                           P,
                                           @"",
                                           sqlRecordSixUnits
                                           ],
                                          mutableData)
                            )
                           [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken patient db error"];
                        NSArray *patientPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding
/*
 <!-- pk (added in our implementation -->
 <xsd:attribute name="PatientID" type="dicomVrLO" use="required" />
 <xsd:attribute name="PatientName" type="dicomVrPN" use="required" />
 <xsd:attribute name="IssuerOfPatientID" type="dicomVrLO" />
 <xsd:attribute name="PatientBirthDate" type="dicomVrDA" />
 <!--<xsd:attribute name="PatientBirthTime" type="dicomVrTM" /> (not present in our implementation)-->
 <xsd:attribute name="PatientSex" type="dicomPatientSex" />
 */
                        [xmlweasismanifest appendFormat:
                         @"<Patient PatientID=\"%@\" PatientName=\"%@\" IssuerOfPatientID=\"%@\" PatientBirthDate=\"%@\" PatientSex=\"%@\">\r",
                         (patientPropertiesArray[0])[1],
                         (patientPropertiesArray[0])[2],
                         (patientPropertiesArray[0])[3],
                         (patientPropertiesArray[0])[4],
                         (patientPropertiesArray[0])[5]
                         ];

//#pragma mark study loop
                        for (NSString *E in EPDict)
                        {
                           if ([EPDict[E] isEqualToString:P])
                           {
                              [mutableData setData:[NSData data]];
                              if (!execUTF8Bash(sqlcredentials,
                                                [NSString stringWithFormat:
                                                 sqlE,
                                                 sqlConnect,
                                                 E,
                                                 @"",
                                                 sqlRecordTenUnits
                                                 ],
                                                mutableData)
                                  )
                                 [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken study db error"];
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
/*
 <xsd:attribute name="StudyInstanceUID" type="dicomVrUI" use="required" />
 <xsd:attribute name="StudyDescription" type="dicomVrLO" />
 <xsd:attribute name="StudyDate" type="dicomVrDA" />
 <xsd:attribute name="StudyTime" type="dicomVrTM" />
 <xsd:attribute name="AccessionNumber" type="dicomVrSH" />
 <xsd:attribute name="StudyID" type="dicomVrSH" />
 <xsd:attribute name="ReferringPhysicianName" type="dicomVrPN" />
 */
                              [xmlweasismanifest appendFormat:
                               @"<Study StudyInstanceUID=\"%@\" StudyDescription=\"%@\" StudyDate=\"%@\" StudyTime=\"%@\" AccessionNumber=\"%@\" StudyID=\"%@\" ReferringPhysicianName=\"%@\" numImages=\"%@\" modality=\"%@\">\r",
                               (EPropertiesArray[0])[1],
                               (EPropertiesArray[0])[2],
                               StudyDateString,
                               StudyTimeString,
                               (EPropertiesArray[0])[5],
                               (EPropertiesArray[0])[6],
                               (EPropertiesArray[0])[7],
                               (EPropertiesArray[0])[8],
                               (EPropertiesArray[0])[9]
                               ];
//#pragma mark series loop
                              [mutableData setData:[NSData data]];
                              if (!execUTF8Bash(sqlcredentials,
                                                [NSString stringWithFormat:
                                                 sqlS,
                                                 sqlConnect,
                                                 E,
                                                 @"",
                                                 sqlRecordFiveUnits
                                                 ],
                                                mutableData)
                                  )
                                 [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken series db error"];
                              NSArray *SPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:3 decreasing:NO];//NSUTF8StringEncoding
/*
 <xsd:attribute name="SeriesInstanceUID" type="dicomVrUI"
 use="required" />
 <xsd:attribute name="SeriesDescription" type="dicomVrLO" />
 <xsd:attribute name="SeriesNumber" type="dicomVrIS" />
 <xsd:attribute name="Modality" type="dicomVrCS" />
 <xsd:attribute name="WadoTransferSyntaxUID" type="xsd:string" />
 <xsd:attribute name="WadoCompressionRate" type="xsd:integer" />
 <xsd:attribute name="DirectDownloadThumbnail" type="xsd:string" />
 */
                              for (NSArray *SProperties in SPropertiesArray)
                              {
                                 //for SOPClassUID check on the first instance
                                 [mutableData setData:[NSData data]];
                                 if (!execUTF8Bash(sqlcredentials,
                                                   [NSString stringWithFormat:
                                                    sqlI,
                                                    sqlConnect,
                                                    SProperties[0],
                                                    @"limit 1",
                                                    sqlRecordFourUnits
                                                    ],
                                                   mutableData)
                                     )
                                    [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken instance db error"];
                                 NSArray *IPropertiesFirstRecord=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding
                                 
                                 //dicom cda
                                 if ([IPropertiesFirstRecord[3] isEqualToString:@"1.2.840.10008.5.1.4.1.1.104.2"]) continue;
                                 //SR
                                 if ([IPropertiesFirstRecord[3] hasPrefix:@"1.2.840.10008.5.1.4.1.1.88"])continue;
                                 //do not add empty series
                                 if ([IPropertiesFirstRecord count]==0) continue;
                                 //if there is restriction and does't match
                                 if (
                                     hasRestriction
                                     &&(hasSeriesDescriptionRestriction && [SeriesDescriptionArray indexOfObject:SProperties[2]]==NSNotFound)
                                     &&(hasModalityRestriction && [ModalityArray indexOfObject:SProperties[4]]==NSNotFound)
                                     &&(hasSOPClassRestriction && [SOPClassArray indexOfObject:IPropertiesFirstRecord[3]]==NSNotFound)
                                     ) continue;
                                 
                                 
                                 
                                 //instances
                                 [mutableData setData:[NSData data]];
                                 if (!execUTF8Bash(sqlcredentials,
                                                   [NSString stringWithFormat:
                                                    sqlI,
                                                    sqlConnect,
                                                    SProperties[0],
                                                    @"",
                                                    sqlRecordFourUnits
                                                    ],
                                                   mutableData)
                                     )
                                    [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken instance db error"];
                                 NSArray *IPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding
                                 
                                 [xmlweasismanifest appendFormat:
                                  @"<Series SeriesInstanceUID=\"%@\" SeriesDescription=\"%@\" SeriesNumber=\"%@\" Modality=\"%@\"  WadoTransferSyntaxUID=\"%@\" >\r",
                                  SProperties[1],
                                  SProperties[2],
                                  SProperties[3],
                                  SProperties[4],
                                  @"*"
                                  ];//DirectDownloadThumbnail=\"%@\"
//#pragma mark instance loop
                                 for (NSArray *IProperties in IPropertiesArray)
                                 {
/*
 <xsd:attribute name="SOPInstanceUID" type="dicomVrUI" use="required" />
 <xsd:attribute name="InstanceNumber" type="dicomVrIS" />
 <xsd:attribute name="DirectDownloadFile" type="xsd:string" />
 */
                                    [xmlweasismanifest appendFormat:
                                     @"<Instance SOPInstanceUID=\"%@\" InstanceNumber=\"%@\" />\r",
                                     IProperties[1],
                                     IProperties[2]
                                     ];//DirectDownloadFile=\"%@\"
                                 }
                                 [xmlweasismanifest appendString:@"</Series>\r"];
                              }
                              [xmlweasismanifest appendString:@"</Study>\r"];
                           }//end if ([EPDict[E] isEqualToString:P])
                        }//end for each E
                        [xmlweasismanifest appendString:@"</Patient>\r"];
                     }
                     [xmlweasismanifest appendString:@"</arcQuery>\r"];
                     [xmlweasismanifest appendString:@"</manifest>\r"];
                     LOG_DEBUG(@"%@",xmlweasismanifest);

                     return [RSDataResponse
                             responseWithData:[LFCGzipUtility gzipData:[xmlweasismanifest dataUsingEncoding:NSUTF8StringEncoding]]
                             contentType:@"application/x-gzip"
                             ];
/*
 //base64 dicom:get -i does not work
 
 RSDataResponse *response=[RSDataResponse responseWithData:[[[LFCGzipUtility gzipData:[xmlweasismanifest dataUsingEncoding:NSUTF8StringEncoding]] base64EncodedStringWithOptions:0]dataUsingEncoding:NSUTF8StringEncoding] contentType:@"application/x-gzip"];
 [response setValue:@"Base64" forAdditionalHeader:@"Content-Transfer-Encoding"];//https://tools.ietf.org/html/rfc2045
 return response;
 
 //xml dicom:get -iw works also, like with gzip
 return [RSDataResponse
 responseWithData:[xmlweasismanifest dataUsingEncoding:NSUTF8StringEncoding]
 contentType:@"text/xml"];
 */
      } break;//end of sql wado weasis
         
                  case accessTypeCornerstone:{
#pragma mark ··· CORNERSTONE (TODO remove limitation)
                     if ([EPDict count]>1) [RSErrorResponse responseWithClientError:404 message:@"%@",@"accessType cornerstone can not be applied to more than a study"];

//#pragma mark arcQuery
                     NSMutableArray *responseArray=[NSMutableArray array];
                     NSMutableArray *patientArray=[NSMutableArray array];
                     [responseArray addObject:
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

//#pragma mark patient loop
                     for (NSString *P in [NSSet setWithArray:[EPDict allValues]])
                     {
                        [mutableData setData:[NSData data]];
                        if (!execUTF8Bash(sqlcredentials,
                                          [NSString stringWithFormat:
                                           sqlP,
                                           sqlConnect,
                                           P,
                                           @"",
                                           sqlRecordSixUnits
                                           ],
                                          mutableData)
                            )
                           [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken patient db error"];
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
                              if (!execUTF8Bash(sqlcredentials,
                                                [NSString stringWithFormat:
                                                 sqlE,
                                                 sqlConnect,
                                                 E,
                                                 @"",
                                                 sqlRecordTenUnits
                                                 ],
                                                mutableData)
                                  )
                                 [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken study db error"];
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
                              
                              NSMutableArray *seriesArray=[NSMutableArray array];
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
//#pragma mark series loop
                              [mutableData setData:[NSData data]];
                              if (!execUTF8Bash(sqlcredentials,
                                                [NSString stringWithFormat:
                                                 sqlS,
                                                 sqlConnect,
                                                 E,
                                                 @"",
                                                 sqlRecordFiveUnits
                                                 ],
                                                mutableData)
                                  )
                                 [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken series db error"];
                              NSArray *SPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:3 decreasing:NO];//NSUTF8StringEncoding

                              for (NSArray *SProperties in SPropertiesArray)
                              {
                                 //for SOPClassUID check on the first instance
                                 [mutableData setData:[NSData data]];
                                 if (!execUTF8Bash(sqlcredentials,
                                                   [NSString stringWithFormat:
                                                    sqlI,
                                                    sqlConnect,
                                                    SProperties[0],
                                                    @"limit 1",
                                                    sqlRecordFourUnits
                                                    ],
                                                   mutableData)
                                     )
                                    [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken instance db error"];
                                 NSArray *IPropertiesFirstRecord=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding
                                 
                                 //dicom cda
                                 if ([IPropertiesFirstRecord[3] isEqualToString:@"1.2.840.10008.5.1.4.1.1.104.2"]) continue;
                                 //SR
                                 if ([IPropertiesFirstRecord[3] hasPrefix:@"1.2.840.10008.5.1.4.1.1.88"])continue;
                                 //do not add empty series
                                 if ([IPropertiesFirstRecord count]==0) continue;
                                 //if there is restriction and does't match
                                 if (
                                     hasRestriction
                                     &&(hasSeriesDescriptionRestriction && [SeriesDescriptionArray indexOfObject:SProperties[2]]==NSNotFound)
                                     &&(hasModalityRestriction && [ModalityArray indexOfObject:SProperties[4]]==NSNotFound)
                                     &&(hasSOPClassRestriction && [SOPClassArray indexOfObject:IPropertiesFirstRecord[3]]==NSNotFound)
                                     ) continue;
                                 
                                 
                                 
                                 //instances
                                 [mutableData setData:[NSData data]];
                                 if (!execUTF8Bash(sqlcredentials,
                                                   [NSString stringWithFormat:
                                                    sqlI,
                                                    sqlConnect,
                                                    SProperties[0],
                                                    @"",
                                                    sqlRecordFourUnits
                                                    ],
                                                   mutableData)
                                     )
                                    [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken instance db error"];
                                 NSArray *IPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding
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
                                                               @"wadouri:%@?requestType=WADO&studyUID=%@&seriesUID=%@&objectUID=%@&contentType=application/dicom&transferSyntax=*&session=%@&custodianOID=%@",
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
                                 }
                              }
                           }//end if ([EPDict[E] isEqualToString:P])
                        }//end for each E
                     }
                     NSData *cornerstoneJson=[NSJSONSerialization dataWithJSONObject:responseArray options:0 error:nil];
                     LOG_DEBUG(@"cornerstone manifest :\r\n%@",[[NSString alloc] initWithData:cornerstoneJson encoding:NSUTF8StringEncoding]);
                     return [RSDataResponse responseWithData:cornerstoneJson contentType:@"application/json"];
               } break;//end of sql wado cornerstone
          
                  case accessTypeDicomzip:
                  {
#pragma mark ··· DICOMZIP
                     //use responseArray to stream the zipped imageId objects
                     return [RSErrorResponse responseWithClientError:404 message:@"%@",@"falta programar dicomzip"];
                  } break;//end of sql wado dicomzip
         
                  case accessTypeOsirix:
                  {
#pragma mark ··· OSIRIX
                     //use responseArray to stream the zipped imageId objects
                     return [RSErrorResponse responseWithClientError:404 message:@"%@",@"falta programar dicomzip"];
                  } break;//end of sql wado osirix
               }
            }


            case getTypeWadors:{
#pragma mark ·· WADORS
               [RSErrorResponse responseWithClientError:404 message:@"studyToken sql wadors not implemented yet"];
            } break;//end of getTypeFolder
         }


      } break;//end of sql
         
      case selectTypeQido:{
#pragma mark · QIDO
         return [RSErrorResponse responseWithClientError:404 message:@"%@",@"falta programar studyToken qido"];
      } break;//end of qido
         
      case selectTypeCfind:{
#pragma mark · CFIND
         return [RSErrorResponse responseWithClientError:404 message:@"%@",@"falta programar studyToken cfind"];
      } break;//end of qido
   }
   
   return [RSErrorResponse responseWithClientError:404 message:@"studyToken should not be here"];
}

@end
