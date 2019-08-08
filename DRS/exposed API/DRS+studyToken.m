#import "DRS+studyToken.h"
#import "LFCGzipUtility.h"
#import "DICMTypes.h"
#import "NSData+PCS.h"

@implementation DRS (studyToken)


static NSString *sqlConnect=@"export MYSQL_PWD=pcs; /usr/local/mysql/bin/mysql --raw --skip-column-names -upcs -h 192.168.250.1 -b pacsdb2 -e \"";

// pkstudy.pkpatient/
static NSString *sqlTwoPks=@"\" | awk -F\\t ' BEGIN{ ORS=\"/\"; OFS=\".\";}{print $1, $2}'";



//recordSeparator+/r+/n  unitSeparator+|
static NSString *sqlRecordFourUnits=@"\" | awk -F\\t ' BEGIN{ ORS=\"\\x0F\\x0A\";OFS=\"\\x0E|\";}{print $1, $2, $3, $4}'";

static NSString *sqlRecordFiveUnits=@"\" | awk -F\\t ' BEGIN{ ORS=\"\\x0F\\x0A\";OFS=\"\\x0E|\";}{print $1, $2, $3, $4, $5}'";

static NSString *sqlRecordSixUnits=@"\" | awk -F\\t ' BEGIN{ ORS=\"\\x0F\\x0A\";OFS=\"\\x0E|\";}{print $1, $2, $3, $4, $5, $6}'";

static NSString *sqlRecordEightUnits=@"\" | awk -F\\t ' BEGIN{ ORS=\"\\x0F\\x0A\";OFS=\"\\x0E|\";}{print $1, $2, $3, $4, $5, $6, $7, $8}'";

static NSString *sqlRecordTenUnits=@"\" | awk -F\\t ' BEGIN{ ORS=\"\\x0F\\x0A\";OFS=\"\\x0E|\";}{print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10}'";



static NSString *sqlPE4Ean=@"%@SELECT pk,patient_fk FROM study WHERE accession_no='%@' limit 10%@";

static NSString *sqlPE4Euid=@"%@SELECT pk,patient_fk FROM study WHERE study_iuid='%@'%@";

static NSString *sqlPE4PidEda=@"%@SELECT study.pk,study.patient_fk FROM study LEFT JOIN patient ON study.patient_fk=patient.pk WHERE patient.pat_id='%@' AND DATE(study.study_datetime)='%@' limit 10%@";

//patient fields
static NSString *sqlP=@"%@SELECT pk,pat_id,pat_name,pat_id_issuer,pat_birthdate,pat_sex FROM patient WHERE pk='%@'%@";

//studyFields
static NSString *sqlE=@"%@SELECT pk,study_iuid,study_desc,DATE(study_datetime),TIME(study_datetime),accession_no,study_id,ref_physician,num_instances,mods_in_study FROM study WHERE pk='%@'%@";

//seriesFields
static NSString *sqlS=@"%@SELECT pk,series_iuid,series_desc,series_no,modality FROM series WHERE study_fk='%@'%@";


//instancesFields
static NSString *sqlI=@"%@SELECT pk,sop_iuid,inst_no,sop_cuid FROM series instance WHERE series_fk='%@'%@";



-(void)addStudyTokenHandler
{
NSRegularExpression *studyTokenRegex = [NSRegularExpression regularExpressionWithPattern:@"/studyToken" options:0 error:NULL];
[self addHandler:@"POST" regex:studyTokenRegex processBlock:
 ^(RSRequest* request, RSCompletionBlock completionBlock){completionBlock(^RSResponse* (RSRequest* request)
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

#pragma mark proxy to pacs?
   NSUInteger pacsIndex=[names indexOfObject:@"pacs"];
   if (pacsIndex!=NSNotFound)
   {
#pragma mark TODO
      if ([DRS.localoids indexOfObject:values[pacsIndex]]==NSNotFound)
      {
         LOG_WARNING(@"to be proxied to another httpdicom");
         return [RSErrorResponse responseWithClientError:404 message:@"to be proxied to another httpdicom"];
      }
   }

#pragma mark processing by this httpdicom

   NSUInteger StudyInstanceUIDsIndex=[names indexOfObject:@"StudyInstanceUID"];
   NSUInteger AccessionNumberIndex=[names indexOfObject:@"AccessionNumber"];
   NSUInteger StudyDateIndex=[names indexOfObject:@"StudyDate"];
   NSUInteger PatientIDIndex=[names indexOfObject:@"PatientID"];

   
   /*
    Using only one of StudyInstanceUID, AccessionNumber or PatientID+StudyDate
    to create a dictionary studyInstanceUID:patientpk
    Reject if there is more than one
    */
   NSMutableDictionary *EPDict=[NSMutableDictionary dictionary];
   NSMutableData *mutableData=[NSMutableData data];
    NSMutableString *sqlBash=[NSMutableString string];

#pragma mark -
#pragma mark StudyInstanceUID
   
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
          [sqlBash setString:[NSString stringWithFormat:sqlPE4Euid,sqlConnect,uid,sqlTwoPks]];
          LOG_VERBOSE(@"%@",sqlBash);
         [mutableData setData:[NSData data]];
         if (!task(@"/bin/bash",@[@"-s"],[sqlBash dataUsingEncoding:NSUTF8StringEncoding],mutableData))
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
#pragma mark AccessionNumber
         if (
               (StudyDateIndex!=NSNotFound)
             ||(PatientIDIndex!=NSNotFound)
             ) [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken AccessionNumber shoud not be present together with StudyDate or PatientID"];
         //issuer?
         
         //find corresponding EP
          [sqlBash setString:[NSString stringWithFormat:sqlPE4Ean, sqlConnect, values[AccessionNumberIndex],sqlTwoPks]];
          LOG_VERBOSE(@"%@",sqlBash);
         [mutableData setData:[NSData data]];
         if (!task(@"/bin/bash",@[@"-s"],[sqlBash dataUsingEncoding:NSUTF8StringEncoding],mutableData))
            [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken accessionNumber error"];
      }
      else if ((PatientIDIndex!=NSNotFound)&&(StudyDateIndex!=NSNotFound))
      {
#pragma mark PatientID+StudyDate
         //issuer?
         
         //find corresponding EP
          [sqlBash setString:[NSString stringWithFormat:sqlPE4PidEda, sqlConnect, values[PatientIDIndex], values[StudyDateIndex], sqlTwoPks]];
          LOG_VERBOSE(@"%@",sqlBash);
         [mutableData setData:[NSData data]];
          
         if (!task(@"/bin/bash",@[@"-s"],[sqlBash dataUsingEncoding:NSUTF8StringEncoding],mutableData))
            [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken PatientID or StudyDate error"];
      }
      else [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken one of StudyInstanceUID, AccessionNumber or PatientID+StudyDate should be present"];

      
      //for both AccessionNumber or PatientID+StudyDate, check if mutableData
      if ([mutableData length]<2) [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken AccessionNumber or PatientID+StudyDate did not select any study"];
      
      for (NSString *EPString in [[[NSString alloc]initWithData:mutableData encoding:NSUTF8StringEncoding] pathComponents])
      {
         [EPDict setObject:[EPString pathExtension] forKey:[EPString stringByDeletingPathExtension]];
      }
   }
   
   
#pragma mark -
#pragma mark patient set

   NSSet *PSet=[NSSet setWithArray:[EPDict allValues]];
   
#pragma mark session
   NSString *sessionString=nil;
   NSUInteger sessionIndex=[names indexOfObject:@"session"];
   if (sessionIndex!=NSNotFound) sessionString=values[sessionIndex];
   else sessionString=@"";

#pragma mark accessType
   NSString *accessTypeString=nil;
   NSUInteger accessTypeIndex=[names indexOfObject:@"accessType"];
   if (accessTypeIndex!=NSNotFound) accessTypeString=values[accessTypeIndex];
   else [RSErrorResponse responseWithClientError:404 message:@"%@",@"accessType required"];
   BOOL doWeasis=[accessTypeString isEqualToString:@"weasis"];
   BOOL doCornerstone=[accessTypeString isEqualToString:@"cornerstone"];
   BOOL doDicomzip=[accessTypeString isEqualToString:@"dicomzip"];
   if (!doWeasis && !doCornerstone && !doDicomzip) [RSErrorResponse responseWithClientError:404 message:@"%@",@"accessType should be either weasis, cornerstone or dicomzip"];
   if (doCornerstone && ([EPDict count]>1))
   {
       [RSErrorResponse responseWithClientError:404 message:@"%@",@"accessType cornerstone can not be applied to more than a study"];
   }
   
   
#pragma mark SeriesDescription
   NSArray *SeriesDescriptionArray=nil;
   NSUInteger SeriesDescriptionIndex=[names indexOfObject:@"SeriesDescription"];
   if (SeriesDescriptionIndex!=NSNotFound) SeriesDescriptionArray=[values[SeriesDescriptionIndex] componentsSeparatedByString:@"\\"];


#pragma mark Modality
   NSArray *ModalityArray=nil;
   NSUInteger ModalityIndex=[names indexOfObject:@"Modality"];
   if (ModalityIndex!=NSNotFound) ModalityArray=[values[ModalityIndex]componentsSeparatedByString:@"\\"];


#pragma mark SOPClass
   NSArray *SOPClassArray=nil;
   NSUInteger SOPClassIndex=[names indexOfObject:@"SOPClass"];
   if (SOPClassIndex!=NSNotFound) SOPClassArray=[values[SOPClassIndex]componentsSeparatedByString:@"\\"];

                                                 
#pragma mark series restriction
   BOOL hasSeriesDescriptionRestriction=
        (
            SeriesDescriptionArray
         && [SeriesDescriptionArray count]
         && [SeriesDescriptionArray[0] length]
         );
   BOOL hasModalityRestriction=
    (
        ModalityArray
     && [ModalityArray count]
     && [ModalityArray[0] length]
     );
   BOOL hasSOPClassRestriction=
    (
        SOPClassArray
     && [SOPClassArray count]
     && [SOPClassArray[0] length]
     );

   NSMutableString *manifest=[NSMutableString string];
   NSMutableArray *responseArray=[NSMutableArray array];

#pragma mark -
#pragma mark processing
     [manifest appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\r"];
     [manifest appendString:@"<manifest xmlns=\"http://www.weasis.org/xsd/2.5\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">\r"];

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
     [manifest appendFormat:@"<arcQuery arcId=\"%@\" baseUrl=\"%@\" webLogin=\"%@\" requireOnlySOPInstanceUID=\"%@\" additionnalParameters=\"&amp;session=%@&amp;custodianOID=%@&amp;SeriesDescription=%@&amp;Modality=%@&amp;SOPClass=%@\" overrideDicomTagsList=\"%@\">\r",
      @"2.16.858.0.1.4.0.72769.217215590012.2",
      @"http://192.168.250.1:8080/dcm4chee",
      @"",
      @"false",
      sessionString,
      @"2.16.858.0.1.4.0",
      [SeriesDescriptionArray componentsJoinedByString:@"\\"],
      [ModalityArray componentsJoinedByString:@"\\"],
      [SOPClassArray componentsJoinedByString:@"\\"],
      @""
      ];
     
#pragma mark patient loop
     for (NSString *P in PSet)
     {
        [mutableData setData:[NSData data]];
        if (!task(@"/bin/bash",@[@"-s"],[[NSString stringWithFormat:sqlP,sqlConnect,P,sqlRecordSixUnits] dataUsingEncoding:NSUTF8StringEncoding],mutableData))
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
        [manifest appendFormat:
         @"<Patient PatientID=\"%@\" PatientName=\"%@\" IssuerOfPatientID=\"%@\" PatientBirthDate=\"%@\" PatientSex=\"%@\">\r",
         (patientPropertiesArray[0])[1],
         (patientPropertiesArray[0])[2],
         (patientPropertiesArray[0])[3],
         (patientPropertiesArray[0])[4],
         (patientPropertiesArray[0])[5]
         ];
        NSMutableArray *studyArray=[NSMutableArray array];
        [responseArray addObject:@{
         @"PatientID":(patientPropertiesArray[0])[1],
         @"PatientName":(patientPropertiesArray[0])[2],
         @"IssuerOfPatientID":(patientPropertiesArray[0])[3],
         @"PatientBirthDate":(patientPropertiesArray[0])[4],
         @"PatientSex":(patientPropertiesArray[0])[5],
         @"studyList":studyArray
         }];
        //studies
        for (NSString *E in EPDict)
        {
           if ([EPDict[E] isEqualToString:P])
           {
              [mutableData setData:[NSData data]];
              if (!task(@"/bin/bash",@[@"-s"],[[NSString stringWithFormat:sqlE,sqlConnect,E,sqlRecordTenUnits] dataUsingEncoding:NSUTF8StringEncoding],mutableData))
                 [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken study db error"];
              NSArray *EPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:3 decreasing:YES];//NSUTF8StringEncoding
              /*
               <xsd:attribute name="StudyInstanceUID" type="dicomVrUI"
               use="required" />
               <xsd:attribute name="StudyDescription" type="dicomVrLO" />
               <xsd:attribute name="StudyDate" type="dicomVrDA" />
               <xsd:attribute name="StudyTime" type="dicomVrTM" />
               <xsd:attribute name="AccessionNumber" type="dicomVrSH" />
               <xsd:attribute name="StudyID" type="dicomVrSH" />
               <xsd:attribute name="ReferringPhysicianName" type="dicomVrPN" />
               */
              NSString *StudyDateString=[NSString stringWithFormat:@"%@%@%@",
                                         [(EPropertiesArray[0])[3]subarrayWithRange:NSMakeRange(0,4)],
                                         [(EPropertiesArray[0])[3]subarrayWithRange:NSMakeRange(5,2)],
                                         [(EPropertiesArray[0])[3]subarrayWithRange:NSMakeRange(8,2)]
                                         ];
              NSString *StudyTimeString=[NSString stringWithFormat:@"%@%@%@",
                                         [(EPropertiesArray[0])[4]subarrayWithRange:NSMakeRange(0,2)],
                                         [(EPropertiesArray[0])[4]subarrayWithRange:NSMakeRange(3,2)],
                                         [(EPropertiesArray[0])[4]subarrayWithRange:NSMakeRange(6,2)]
                                         ];
              [manifest appendFormat:
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

              
              
              //series

              [mutableData setData:[NSData data]];
              if (!task(@"/bin/bash",@[@"-s"],[[NSString stringWithFormat:sqlS,sqlConnect,E,sqlRecordFiveUnits] dataUsingEncoding:NSUTF8StringEncoding],mutableData))
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
                 
                 if (hasSeriesDescriptionRestriction && [SeriesDescriptionArray indexOfObject:SProperties[2]]!=NSNotFound) continue;
                    
                 if (hasModalityRestriction && [ModalityArray indexOfObject:SProperties[4]]!=NSNotFound) continue;
                 

                 //instances
                 
                 [mutableData setData:[NSData data]];
                 if (!task(@"/bin/bash",@[@"-s"],[[NSString stringWithFormat:sqlI,sqlConnect,SProperties[0],sqlRecordFourUnits] dataUsingEncoding:NSUTF8StringEncoding],mutableData))
                    [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken instance db error"];
                 NSArray *IPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding

                 if ([IPropertiesArray count]!=0)
                 {
                    //SOPClass?
                    if (!hasSOPClassRestriction || [SOPClassArray indexOfObject:((IPropertiesArray[0])[3])]==NSNotFound)
                    {
                       [manifest appendFormat:
                        @"<Series SeriesInstanceUID=\"%@\" SeriesDescription=\"%@\" SeriesNumber=\"%@\" Modality=\"%@\"  WadoTransferSyntaxUID=\"%@\">\r",
                        SProperties[1],
                        SProperties[2],
                        SProperties[3],
                        SProperties[4],
                        @"*"
                        ];
                       //@"<Series SeriesInstanceUID=\"%@\" SeriesDescription=\"%@\" SeriesNumber=\"%@\" Modality=\"%@\"  WadoTransferSyntaxUID=\"%@\" WadoCompressionRate=\"%@\" DirectDownloadThumbnail=\"%@\">\r"
                       
                       
                       /*
                        seriesList
                        ==========
                        not for OT nor DOC
                        
                        seriesDescription
                        seriesNumber
                        */
                       NSMutableArray *instanceArray=[NSMutableArray array];
                       BOOL addCornerstoneSeries=
                       (   ![SProperties[4] isEqualToString:@"OT"]
                        && ![SProperties[4] isEqualToString:@"DOC"]
                       );
                       if (addCornerstoneSeries)
                       {
                          [seriesArray addObject:
                           @{
                                @"SeriesInstanceUID":SProperties[1],
                                @"seriesDescription":SProperties[2],
                                @"seriesNumber":SProperties[3],
                                @"Modality":SProperties[4],
                                @"instanceList":instanceArray,
                           }];
                       }
                       for (NSArray *IProperties in IPropertiesArray)
                       {
                          /*
                           <xsd:attribute name="SOPInstanceUID" type="dicomVrUI"
                           use="required" />
                           <xsd:attribute name="InstanceNumber" type="dicomVrIS" />
                           ---<xsd:attribute name="DirectDownloadFile" type="xsd:string" />
                           
                           */
                          [manifest appendFormat:
                           @"<Instance SOPInstanceUID=\"%@\" InstanceNumber=\"%@\"/>\r",
                           IProperties[1],
                           IProperties[2]
                           ];
                          
                          
                          if (addCornerstoneSeries)
                          {
                             /*
                              instanceList
                              ============
                              classified by instanceNumber
                              imageId:wadouri
                              */

                             
                             NSString *wadouriInstance=[NSString stringWithFormat:
@"%@?requestType=WADO&studyUID=%@&seriesUID=%@&objectUID=%@&transferSyntax=*&session=%@&custodianOID=%@",
@"http://192.168.250.1:8080/dcm4chee",
(EPropertiesArray[0])[1],
SProperties[1],
IProperties[1],
sessionString,
@"2.16.858.0.1.4.0"];
                              [instanceArray addObject:@{@"imageId":wadouriInstance
                                                          }];
                           }
                       }
                       [manifest appendString:@"</Series>\r"];
                    }//end no SOPClass restriction
                 }//end no instances in series

                                  

              }
              [manifest appendString:@"</Study>\r"];
           }//end if ([EPDict[E] isEqualToString:P])
        }//end for each E
        
        [manifest appendString:@"</Patient>\r"];
     }
     [manifest appendString:@"</wado_query>\r"];
     [manifest appendString:@"</manifest>\r"];
     LOG_INFO(@"%@",manifest);
   
   if (doWeasis)
   {
     RSDataResponse *response=[RSDataResponse responseWithData:[[[LFCGzipUtility gzipData:[manifest dataUsingEncoding:NSUTF8StringEncoding]] base64EncodedStringWithOptions:0]dataUsingEncoding:NSUTF8StringEncoding] contentType:@"application/x-gzip"];
     [response setValue:@"Base64" forAdditionalHeader:@"Content-Transfer-Encoding"];//https://tools.ietf.org/html/rfc2045
     
     return response;
   }
   else if (doCornerstone)
   {
#pragma mark cornerstone
     
     //cornerstone
     NSMutableDictionary *cornerstone=[NSMutableDictionary dictionary];
     
 
     
     
      NSData *cornerstoneJson=[NSJSONSerialization dataWithJSONObject:cornerstone options:0 error:nil];
     LOG_DEBUG(@"cornerstone manifest :\r\n%@",[[NSString alloc] initWithData:cornerstoneJson encoding:NSUTF8StringEncoding]);
     return [RSDataResponse responseWithData:cornerstoneJson contentType:@"application/json"];
   }
   
   
#pragma mark dicomzip
//use responseArray to stream the zipped imageId objects
   return [RSErrorResponse responseWithClientError:404 message:@"%@",@"falta programar dicomzip"];

   
}
(request));}];
}

@end
