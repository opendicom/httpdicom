//
//  DRS+APath.m
//  httpdicom
//
//  Created by jacquesfauquex on 20180119.
//  Copyright © 2018 opendicom.com. All rights reserved.
//

#import "DRS+APath.h"
#import "K.h"
#import "NSURLComponents+PCS.h"
#import "NSString+PCS.h"
#import "NSMutableData+SQL.h"

#import "APathSqlOperation.h"
#import "APathRestOperation.h"

@implementation DRS (APath)

static NSArray             *_levels;
static NSArray             *_key;
static NSArray             *_tag;
static NSArray             *_vr;
+(NSArray*)levels { return _levels;}
+(NSArray*)key { return _key;}
+(NSArray*)tag { return _tag;}
+(NSArray*)vr  { return _vr;}

//-(NSUInteger)countPatientsQidoUrl

-(void)addAPathHandler
{
   
   _levels=@[@"/patients",@"/studies",@"/series",@"/instances"];
   
   _key=@[
          @"IssuerOfPatientID",//0
          @"IssuerOfPatientIDQualifiersSequence.LocalNamespaceEntityID",//1
          @"IssuerOfPatientIDQualifiersSequence.UniversalEntityID",//2
          @"IssuerOfPatientIDQualifiersSequence.UniversalEntityIDType",//3
          @"PatientID",//4
          @"PatientName",//5
          @"PatientBirthDate",//6
          @"PatientSex",//7
          @"",//8
          @"",//9
          @"",//10
          @"",//11
          @"",//12
          @"",//13
          @"",//14
          @"",//15
          @"",//16
          @"ProcedureCodeSequence.CodeValue",//17
          @"ProcedureCodeSequence.CodingSchemeDesignator",//18
          @"ProcedureCodeSequence.CodeMeaning",//19
          @"StudyInstanceUID",//20
          @"StudyDescription",//21
          @"StudyDate",//22
          @"StudyTime",//23
          @"StudyID",//24
          @"",//25
          @"",//26
          @"",//27
          @"",//28
          @"AccessionNumber",//29
          @"IssuerOfAccessionNumberSequence.LocalNamespaceEntityID",//30
          @"IssuerOfAccessionNumberSequence.UniversalEntityID",//31
          @"IssuerOfAccessionNumberSequence.UniversalEntityIDType",//32
          @"ReferringPhysicianName",//33
          @"NameofPhysiciansrStudy",//34
          @"ModalitiesInStudy",//35
          @"NumberOfStudyRelatedSeries",//36
          @"NumberOfStudyRelatedInstances",//37
          @"",//38
          @"",//39
          @"SeriesInstanceUID",//40
          @"Modality",//41
          @"SeriesDescription",//42
          @"SeriesNumber",//43
          @"BodyPartExamined",//44
          @"",//45
          @"",//46
          @"StationName",//47
          @"InstitutionalDepartmentName",//48
          @"InstitutionName",//49
          @"Performing​Physician​Name",//50
          @"",//51
          @"InstitutionCodeSequence.CodeValue",//52
          @"InstitutionCodeSequence.schemeDesignator",//53
          @"",//54
          @"PerformedProcedureStepStartDate",//55
          @"PerformedProcedureStepStartTime",//56
          @"RequestAttributeSequence.ScheduledProcedureStepID",//57
          @"RequestAttributeSequence.RequestedProcedureID",//58
          @"NumberOfSeriesRelatedInstances",//59
          @"SOPInstanceUID",//60
          @"SOPClassUID",//61
          @"InstanceNumber",//62
          @"HL7InstanceIdentifier",//63
          @""//64
          ];
   _tag=@[
          @"00100021",//0
          @"00100024.00400031",//1
          @"00100024.00400032",//2
          @"00100024.00400033",//3
          @"00100020",//4
          @"00100010",//5
          @"00100030",//6
          @"00100040",//7
          @"",//8
          @"",//9
          @"",//10
          @"",//11
          @"",//12
          @"",//13
          @"",//14
          @"",//15
          @"",//16
          @"00081032.00080100",//17
          @"00081032.00080102",//18
          @"00081032.00080104",//19
          @"0020000D",//20
          @"00081030",//21
          @"00080020",//22
          @"00080030",//23
          @"00200010",//24
          @"",//25
          @"",//26
          @"",//27
          @"",//28
          @"00080050",//29
          @"00080051.00400031",//30
          @"00080051.00400032",//31
          @"00080051.00400033",//32
          @"00080090",//33
          @"00081060",//34
          @"00080061",//35
          @"00201206",//36
          @"00201208",//37
          @"",//38
          @"",//39
          @"0020000E",//40
          @"00080060",//41
          @"0008103E",//42
          @"00200011",//43
          @"00180015",//44
          @"",//45
          @"",//46
          @"00081010",//47
          @"00081040",//48
          @"00080080",//49
          @"00081050",//50
          @"",//51
          @"00080082.00080100",//52
          @"00080082.00080102",//53
          @"",//54
          @"00400244",//55
          @"00400245",//56
          @"00400275.00400009",//57
          @"00400275.00401001",//58
          @"00201209",//59
          @"00080018",//60
          @"00080016",//61
          @"00200013",//62
          @"0040E001",//63
          @""//64
          ];
   _vr=@[
         @"LO",//0
         @"UT",//1
         @"UT",//2
         @"CS",//3
         @"LO",//4
         @"PN",//5
         @"DA",//6
         @"CS",//7
         @"",//8
         @"",//9
         @"",//10
         @"",//11
         @"",//12
         @"",//13
         @"",//14
         @"",//15
         @"",//16
         @"SH",//17
         @"SH",//18
         @"LO",//19
         @"UI",//20
         @"LO",//21
         @"DA",//22
         @"TM",//23
         @"SH",//24
         @"",//25
         @"",//26
         @"",//27
         @"",//28
         @"SH",//29
         @"UT",//30
         @"UT",//31
         @"CS",//32
         @"PN",//33
         @"PN",//34
         @"CS",//35
         @"IS",//36
         @"IS",//37
         @"",//38
         @"",//39
         @"UI",//40
         @"CS",//41
         @"LO",//42
         @"IS",//43
         @"CS",//44
         @"",//45
         @"",//46
         @"SH",//47
         @"LO",//48
         @"LO",//49
         @"PN",//50
         @"",//51
         @"SH",//52
         @"SH",//53
         @"",//54
         @"DA",//55
         @"TM",//56
         @"SH",//57
         @"SH",//58
         @"IS",//59
         @"UI",//60
         @"UI",//61
         @"IS",//62
         @"ST",//63
         @""//64
         ];

    NSArray *pathSuffixBottomFilterNumber=@[@patientBottomFilterNumber,@studyBottomFilterNumber,@seriesBottomFilterNumber,@instanceBottomFilterNumber];
    NSCharacterSet *weakCharacters=[NSCharacterSet characterSetWithCharactersInString:@" ^<>-_$%&@*.;:,+¿?!¡[](){}'\"\\#"];
   
   
   
   
   
    NSRegularExpression *APathRegex = [NSRegularExpression regularExpressionWithPattern:@"\\/attributes\\/?" options:NSRegularExpressionCaseInsensitive error:NULL];
    [self addHandler:@"GET" regex:APathRegex processBlock:
     ^(RSRequest* request, RSCompletionBlock completionBlock){completionBlock(^RSResponse* (RSRequest* request)
         {
             //LOG_DEBUG(@"[APath] client: %@",request.remoteAddressString);
            
            //input URL
             NSURLComponents *urlComponents=[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
            //URL, fragment, host, password, path, port, query, queryItems, scheme, user
            
            //init URL-analysis variables
             NSMutableArray *pacsToQuery=[NSMutableArray array];//NSString OID
             NSMutableArray *modulesToReturn=[NSMutableArray array];//NSString name
             NSMutableArray *attributesToReturn=[NSMutableArray array];//atribute list
             NSMutableArray *otherParamsToEcho=[NSMutableArray array];//NSString OID
             NSUInteger level=NSNotFound;
             NSMutableDictionary *filters=[NSMutableDictionary dictionary];
             BOOL hasSpecificFilter=false;
             BOOL hasGenericFilter=false;

             NSMutableSet *attributes=[NSMutableSet set];//NSString
             NSUInteger orderbyIndex=NSNotFound;
             NSUInteger offset=0;
             NSUInteger limit=LLONG_MAX;

#pragma mark 1 parsing parameters

            for (NSURLQueryItem *item in urlComponents.queryItems)
            {
               if ([item.name isEqualToString:@"pacs"] && DRS.oids[item.value])
               {
                  [pacsToQuery addObjectsFromArray:[item.value componentsSeparatedByString:@","]];
               }
               else if ([item.name isEqualToString:@"list"])
               {
                  [attributesToReturn addObjectsFromArray:[item.value componentsSeparatedByString:@","]];
               }
               else if ([item.name isEqualToString:@"module"])
               {
                  [modulesToReturn addObjectsFromArray:[item.value componentsSeparatedByString:@","]];
               }
               else if ([item.name isEqualToString:@"orderby"])
               {
                  if (orderbyIndex==NSNotFound) orderbyIndex=[K indexOfAttribute:item.value];
               }
               else if ([item.name isEqualToString:@"offset"])
               {
                  long long result=[item.value longLongValue];
                  if ((result>-1)&&(result<LLONG_MAX)) offset=(NSUInteger)result;
               }
               else if ([item.name isEqualToString:@"limit"])
               {
                  long long result=[item.value longLongValue];
                  if ((result>0)&&(result<LLONG_MAX)) limit=(NSUInteger)result;
               }
               else //filters
               {
                  NSUInteger index=[DRS.key indexOfObject:item.name];//key
                  if (index==NSNotFound)index=[DRS.tag indexOfObject:item.name];//or tag
                  if (index==NSNotFound) [otherParamsToEcho addObject:item];
                  else
                  {
                     NSUInteger l=[item.value length];
                     if (l==0) return [RSErrorResponse responseWithClientError:404 message:@"[fidji] empty matching key '%@' not taken into account",item.name];
                     NSUInteger w=[[item.value componentsSeparatedByCharactersInSet:weakCharacters]count];
                     if (((l<4)&&(w>1)) || ((l>3)&&(l<w-4))) return [RSErrorResponse responseWithClientError:404 message:@"[fidji] value '%@' for key '%@' not sufficiently precise",item.value,item.name];
                     if ( maxFilterNumber < index) return [RSErrorResponse responseWithClientError:404 message:@"[fidji] matching key %@ not available at level %@]",item.name,urlComponents.path];
                     if (filters[@(index)]) return [RSErrorResponse responseWithClientError:404 message:@"[fidji] matching key '%@' found more than once",item.name];
                     if ([K.vr[index] isEqualToString:@"DA"])
                     {
                        NSArray *interval=[item.value componentsSeparatedByString:@"-"];
                        if (
                            [interval count]==2
                            &&(  ![interval[0]length]
                               ||![interval[1]length]
                               ||([interval[1]intValue]-[interval[0]intValue]>8)
                               )
                            ) hasGenericFilter=hasGenericFilter || ((genericFilterBitmap >> index) && 1);//bitwise check
                        else hasSpecificFilter=hasSpecificFilter || ((specificFilterBitmap >> index) && 1);//bitwise check
                     }
                     else
                     {
                        hasSpecificFilter=hasSpecificFilter || ((specificFilterBitmap >> index) && 1);//bitwise check
                        hasGenericFilter=hasGenericFilter || ((genericFilterBitmap >> index) && 1);//bitwise check;
                     }
                     [filters setObject:item.value forKey:@(index)];
                  }
               }
            }//fin parameter parsing

            
#pragma mark 2 parsing path
            
            NSArray *pathComponents=[urlComponents.path pathComponents];
            switch ([pathComponents count]) {
               case 2:// /attributes?
                  level=0;
               case 3://  /studies/attributes?  /series/attributes?  /instances/attributes?
                  level=[DRS.levels indexOfObject:pathComponents[1]];
                  break;
               case 4:// /studies/*/series? or /studies/*/instance?
                  if (![pathComponents[0] isEqualToString:@"studies"])
                  {
                     LOG_WARNING(@"[APath] incorrect path %@",urlComponents.path);
                     return [RSErrorResponse responseWithClientError:404 message:@"[APath] incorrect path %@",urlComponents.path];
                  }
                  if (![DRS.UIRegex numberOfMatchesInString:pathComponents[1] options:0 range:NSMakeRange(0,[pathComponents[1] length])])
                  {
                     LOG_WARNING(@"[APath] badly formed studyUID %@",pathComponents[1]);
                     return [RSErrorResponse responseWithClientError:404 message:@"[APath] badly formed studyUID %@",pathComponents[1]];
                  }
                  //check where studyID exists
                  
                  
                  
                  level=[DRS.levels indexOfObject:pathComponents[3]];
                  break;

               default:
                  LOG_WARNING(@"[APath] incorrect path %@",urlComponents.path);
                  return [RSErrorResponse responseWithClientError:404 message:@"[APath] incorrect path %@",urlComponents.path];
                  break;
            }
            
            NSUInteger maxFilterNumber=[pathSuffixBottomFilterNumber[level]unsignedIntegerValue];
            
            //no se aceptan filtros de nivel más bajo que el del request

            
            
            
         
//errors which imply early return
             if (![pacsToQuery count])
             {
                 [pacsToQuery addObjectsFromArray:DRS.localoids];
                 if (![pacsToQuery count])
                     return [RSErrorResponse responseWithClientError:404 message:@"[fidji] no pacs defined in %@",[request.URL absoluteString]];
             }

             if (!(hasSpecificFilter||hasGenericFilter)) return [RSErrorResponse responseWithClientError:404 message:@"[fidji] no valid matching key"];

             
             
             
//filters numerical ordering
             NSArray *filtersIndex=[[filters allKeys] sortedArrayUsingSelector:@selector(compare:)];
             
             
             if (includefieldall)
             {
                 switch (level)
                 {
                     case 3://instance
                         [includefieldSet addObjectsFromArray:@[
                                                                @(60),//SOPInstanceUID
                                                                @(61),//SOPClassUID
                                                                @(62) //InstanceNumber
                                                                ]];
                     case 2://series
                         [includefieldSet addObjectsFromArray:@[
                                                                @(40),//SeriesInstanceUID
                                                                @(41),//Modality
                                                                @(42),//SeriesDescription
                                                                @(43),//SeriesNumber
                                                                @(44),//BodyPartExamined
                                                                @(47),//StationName
                                                                @(48),//InstitutionalDepartmentName
                                                                @(49),//InstitutionName
                                                                @(50),//PerformingPhysicianName
                                                                @(52),//InstitutionCodeValue
                                                                @(53),//InstitutionschemeDesignator
                                                                @(55),//PerformedProcedureStepStartDate
                                                                @(56),//PerformedProcedureStepStartTime
                                                                @(57),//RequestScheduledProcedureStepID
                                                                @(58),//RequestProcedureID
                                                                @(59) //NumberOfSeriesRelatedInstances
                                                                ]];
                     case 1://study
                         [includefieldSet addObjectsFromArray:@[
                                                                @(17),//ProcedureCodeValue
                                                                @(18),//ProcedureCodingSchemeDesignator
                                                                @(19),//ProcedureCodeMeaning
                                                                @(20),//StudyInstanceUID
                                                                @(21),//StudyDescription
                                                                @(22),//StudyDate
                                                                @(23),//StudyTime
                                                                @(24),//StudyID
                                                                @(29),//AccessionNumber
                                                                @(30),//IssuerOfAccessionNumberLocalNamespaceEntityID
                                                                @(31),//IssuerOfAccessionNumberUniversalEntityID
                                                                @(32),//IssuerOfAccessionNumberUniversalEntityIDType
                                                                @(33),//ReferringPhysicianName
                                                                @(34),//ModalitiesInStudy
                                                                @(35),//NumberOfStudyRelatedSeries
                                                                @(36) //NumberOfStudyRelatedInstances
                                                                ]];
                     default://patient
                         [includefieldSet addObjectsFromArray:@[
                                                                @(0),//IssuerOfPatientID
                                                                @(1),//IssuerOfPatientIDLocalNamespaceEntityID
                                                                @(2),//IssuerOfPatientIDUniversalEntityID
                                                                @(3),//IssuerOfPatientIDUniversalEntityIDType
                                                                @(4),//PatientID
                                                                @(5),//PatientName
                                                                @(6),//PatientBirthDate
                                                                @(7) //PatientSex
                                                                ]];
                    }
                 }
                 else
                 {
                     switch (level) {
                         case 3://instance
                             [includefieldSet addObject:@(60)];
                         case 2://series
                             [includefieldSet addObject:@(40)];
                         case 1://study
                             [includefieldSet addObject:@(20)];
                     }
                 }
             
//fields numerical ordering
                 NSArray *fieldsIndex=[[includefieldSet allObjects] sortedArrayUsingSelector:@selector(compare:)];

                 
#pragma mark 1 NSOperationQueue
             NSOperationQueue *fidjiQueue= [[NSOperationQueue alloc] init];
             [fidjiQueue setMaxConcurrentOperationCount:queueconcurrency];

#pragma mark 1.1 pacs loop
             for (NSString *oid in pacsToQuery)
             {
                 NSDictionary *loopPacs=DRS.pacs[oid];
                 //sql available
                 NSDictionary *sqlmap=DRS.sqls[loopPacs[@"sqlmap"]];
                 if (sqlmap)
                 {
#pragma mark 1.1.1 operation bash/sql
//TODO                     DRSFidjiSqlOperation *operation=[[DRSFidjiSqlOperation alloc]initWith
                     //[queue addOperation: ]

                     
                     
                     
                     
                     
                     
                     //aliased tables (all except STUDY, SERIES, INSTANCE)
                     //if true, the data is found through relation
                     //if false, the data is found in the base table
                     BOOL PIDENT=false;//STUDY LEVEL: Entity issuer of the patient ID
                     BOOL PID=false;//STUDY LEVEL: patient ID
                     BOOL PAT=false;//STUDY LEVEL: patient demographics
                     BOOL PATNAM=false;//STUDY LEVEL: patient name
                     BOOL PATOBJ=false;//STUDY LEVEL: patient contents counter and similar
                     BOOL REQNAM=false;//STUDY LEVEL: requesting physician name
                     
                     BOOL REPNAM=false;//STUDY LEVEL: reporting physician name (designated)
                     
                     BOOL IANENT=false;//STUDY LEVEL: Issuer of accession number
                     BOOL PROCCOD=false;//STUDY LEVEL: code of procedure of the study
                     BOOL STUOBJ=false;//STUDY LEVEL: study contents counter and similar
                     BOOL PERFNAM=false;//SERIES LEVEL: performing physician name
                     BOOL ORGCOD=false;//SERIES LEVEL: institution code
                     BOOL SEROBJ=false;//SERIES LEVEL:series contents counter and similar
                     BOOL INSOBJ=false;//INSTANCE LEVEL: instance contents counter and similar
                     
                     NSMutableString *SELECT=[NSMutableString stringWithString:@"SELECT"];
                     
                     NSMutableString *FROM=[NSMutableString string];
                     
                     NSMutableString *LEFTJOIN=[NSMutableString string];
                     
                     NSMutableString *WHERE=[NSMutableString string];
                     
                     //add PatientID relations, if necesary
                     //no break, adds all relations below
#pragma mark 1.1.1.1 prepare query
                     switch ([[fieldsIndex firstObject]unsignedIntegerValue]) {
                         case IssuerOfPatientID:
                         {
                             NSString *ID_ISSUER_fk=sqlmap[@"ID_ISSUER"];
                             if (ID_ISSUER_fk && [ID_ISSUER_fk length])
                             {
                                 [LEFTJOIN appendFormat:
                                  @"LEFT OUTER JOIN %@ AS PIDENT ON %@.%@=%@.%@ ",
                                  sqlmap[@"ISSUERtable"],
                                  sqlmap[@"IDtable"], ID_ISSUER_fk,
                                  sqlmap[@"ISSUERtable"], sqlmap[@"ISSUERpk"]
                                  ];
                                 PIDENT=true;
                             }
                         }
                         case PatientID:
                         {
                             NSString *PATIENT_ID_fk=sqlmap[@"PATIENT_ID"];
                             if (PATIENT_ID_fk && [PATIENT_ID_fk length])
                             {
                                 [LEFTJOIN appendFormat:
                                  @"LEFT OUTER JOIN %@ AS PID ON %@.%@=%@.%@ ",
                                  sqlmap[@"IDtable"],
                                  sqlmap[@"PATIENTtable"],PATIENT_ID_fk,
                                  sqlmap[@"IDtable"],sqlmap[@"IDpk"]
                                  ];
                                 PID=true;
                             }
                         }
                         case PatientName:
                         {
                             NSString *PATIENT_NAME_fk=sqlmap[@"PATIENT_NAME"];
                             if (PATIENT_NAME_fk && [PATIENT_NAME_fk length])
                             {
                                 [LEFTJOIN appendFormat:
                                  @"LEFT OUTER JOIN %@ AS PATNAM ON %@.%@=%@.%@ ",
                                  sqlmap[@"IDtable"],
                                  sqlmap[@"PATIENTtable"],PATIENT_NAME_fk,
                                  sqlmap[@"NAMEtable"],sqlmap[@"NAMEpk"]
                                  ];
                                 PATNAM=true;
                             }
                         }
                         case PatientBirthDate:
                         case PatientSex:
                         {
                             NSString *STUDY_PATIENT_fk=sqlmap[@"STUDY_PATIENT"];
                             if (STUDY_PATIENT_fk && [STUDY_PATIENT_fk length])
                             {
                                 [LEFTJOIN appendFormat:
                                  @"LEFT OUTER JOIN %@ ON %@.%@=%@.%@ ",
                                  sqlmap[@"PATIENTtable"],
                                  sqlmap[@"STUDYtable"],STUDY_PATIENT_fk,
                                  sqlmap[@"PATIENTtable"],sqlmap[@"PATIENTpk"]
                                  ];
                                 PAT=true;
                             }
                         }
                     }
                     
                     //add other LEFT JOINS related to filters
                     for (NSNumber *filter in filtersIndex)
                     {
                         switch ([filter unsignedIntegerValue]) {
                             case ProcedureCodeValue:
                             case ProcedureCodingSchemeDesignator:
                             case ProcedureCodeMeaning:
                                 if (!PROCCOD)
                                 {
                                     NSString *PROCEDURE_STUDY_fk=sqlmap[@"PROCEDURE_STUDY"];
                                     NSString *PROCEDURE_CODE_fk=sqlmap[@"PROCEDURE_CODE"];
                                     NSString *STUDY_PROCEDURE_fk=sqlmap[@"STUDY_PROCEDURE"];
                                     if (   PROCEDURE_STUDY_fk
                                         && [@"PROCEDURE_STUDY_fk" length]
                                         && PROCEDURE_CODE_fk
                                         && [@"PROCEDURE_CODE_fk" length])
                                     {
                                         // < PROCEDURE > CODE
                                         [LEFTJOIN appendFormat:
                                          @"LEFT OUTER JOIN %@ ON %@.%@=%@.%@ ",
                                          sqlmap[@"PROCEDUREtable"],
                                          sqlmap[@"STUDYtable"],sqlmap[@"STUDYpk"],
                                          sqlmap[@"PROCEDUREtable"],PROCEDURE_STUDY_fk
                                          ];
                                         [LEFTJOIN appendFormat:
                                          @"LEFT OUTER JOIN %@ AS PROCCOD ON %@.%@=%@.%@ ",
                                          sqlmap[@"CODEtable"],
                                          sqlmap[@"CODEtable"],sqlmap[@"CODEpk"],
                                          sqlmap[@"PROCEDUREtable"],PROCEDURE_CODE_fk
                                          ];
                                         PROCCOD=true;
                                     }
                                     else if (   STUDY_PROCEDURE_fk
                                              && [STUDY_PROCEDURE_fk length])
                                     {
                                         // < PROCEDURE > CODE
                                         [LEFTJOIN appendFormat:
                                          @"LEFT OUTER JOIN %@ ON %@.%@=%@.%@ ",
                                          sqlmap[@"PROCEDUREtable"],
                                          sqlmap[@"STUDYtable"],sqlmap[@"STUDYpk"],
                                          sqlmap[@"PROCEDUREtable"],PROCEDURE_STUDY_fk
                                          ];
                                         [LEFTJOIN appendFormat:
                                          @"LEFT OUTER JOIN %@ AS PROCCOD ON %@.%@=%@.%@ ",
                                          sqlmap[@"PROCEDUREtable"],
                                          sqlmap[@"PROCEDUREtable"],sqlmap[@"PROCEDUREpk"],
                                          sqlmap[@"STUDYtable"],STUDY_PROCEDURE_fk
                                          ];
                                         PROCCOD=true;
                                     }
                                 }
                                break;
                         case IssuerOfAccessionNumberLocalNamespaceEntityID:
                         case IssuerOfAccessionNumberUniversalEntityID:
                         case IssuerOfAccessionNumberUniversalEntityIDType:
                             if (!IANENT)
                             {
                                 NSString *STUDY_ISSUER_fk=sqlmap[@"STUDY_ISSUER"];
                                 if (STUDY_ISSUER_fk && [STUDY_ISSUER_fk length])
                                 {
                                     [LEFTJOIN appendFormat:
                                      @"LEFT OUTER JOIN %@ AS IANENT ON %@.%@=%@.%@ ",
                                      sqlmap[@"ISSUERtable"],
                                      sqlmap[@"STUDYtable"],sqlmap[@"STUDY_ISSUER_fk"],
                                      sqlmap[@"ISSUERtable"],sqlmap[@"ISSUERpk"]
                                      ];
                                     IANENT=true;
                                 }
                             }
                             break;
                         case ReferringPhysicianName:
                             if (!REQNAM)
                             {
                                 NSString *STUDY_NAME_fk=sqlmap[@"STUDY_NAME"];
                                 if (STUDY_NAME_fk && [STUDY_NAME_fk length])
                                 {
                                     [LEFTJOIN appendFormat:
                                      @"LEFT OUTER JOIN %@ AS REQNAM ON %@.%@=%@.%@ ",
                                      sqlmap[@"NAMEtable"],
                                      sqlmap[@"STUDYtable"],STUDY_NAME_fk,
                                      sqlmap[@"NAMEtable"],sqlmap[@"NAMEpk"]
                                      ];
                                     REQNAM=true;
                                 }
                             }
                             break;
                         case ModalitiesInStudy:
                             if (!STUOBJ)
                             {
                                 NSString *STUDYOBJECTS_STUDY_fk=sqlmap[@"STUDYOBJECTS_STUDY"];
                                 if (STUDYOBJECTS_STUDY_fk && [STUDYOBJECTS_STUDY_fk length])
                                 {
                                     [LEFTJOIN appendFormat:
                                      @"LEFT OUTER JOIN %@ AS REQNAM ON %@.%@=%@.%@ ",
                                      sqlmap[@"STUDYOBJECTStable"],
                                      sqlmap[@"STUDYtable"],STUDYOBJECTS_STUDY_fk,
                                      sqlmap[@"STUDYOBJECTStable"],sqlmap[@"STUDYOBJECTSpk"]
                                      ];
                                     STUOBJ=true;
                                 }
                             }
                             break;
                         }
                         //not implemented
                         //PATOBJ
                         //PERFNAM
                         //ORGCOD
                         //SEROBJ
                         //INSOBJ
                         
                         /*
                          output format
                          
                         [
                          {
                              "0020000D":
                              [
                               "1.2.392.200036.9116.2.2.2.1762893313.1029997326.945873"
                               ]
                          }
                          ]
                          */

                     }//end for other filters
                     
                     
                     //includes provision for iocm when it does exist
                     switch (level) {
                         case patientLevel:
                             //case of patient VIP
                             break;
                         case studyLevel:
                             [FROM appendFormat:@"FROM %@ ",sqlmap[@"STUDYtable"]];
                             [WHERE appendString:sqlmap[@"iocmWhereStudy"]];
                             break;
                         case seriesLevel:
                             [FROM appendFormat:@"FROM %@ ",sqlmap[@"SERIEStable"]];
                             [LEFTJOIN appendFormat:
                              @"LEFT OUTER JOIN %@ ON %@.%@=%@.%@ ",
                              sqlmap[@"STUDYtable"],
                              sqlmap[@"SERIEStable"],
                              sqlmap[@"SERIES_STUDY"],
                              sqlmap[@"STUDYtable"],
                              sqlmap[@"STUDYpk"]
                              ];
                             [WHERE appendString:sqlmap[@"iocmWhereSeries"]];
                             break;
                         case instanceLevel:
                             [FROM appendFormat:@"FROM %@ ",sqlmap[@"INSTANCEtable"]];
                             [LEFTJOIN appendFormat:
                              @"LEFT OUTER JOIN %@ ON %@.%@=%@.%@ ",
                              sqlmap[@"STUDYtable"],
                              sqlmap[@"SERIEStable"],
                              sqlmap[@"SERIES_STUDY"],
                              sqlmap[@"STUDYtable"],
                              sqlmap[@"STUDYpk"]
                              ];
                             [LEFTJOIN appendFormat:
                              @"LEFT OUTER JOIN %@ ON %@.%@=%@.%@ ",
                              sqlmap[@"SERIEStable"],
                              sqlmap[@"INSTANCEtable"],
                              sqlmap[@"INSTANCE_SERIES"],
                              sqlmap[@"INSTANCEtable"],
                              sqlmap[@"SERIESpk"]
                              ];
                             [WHERE appendString:sqlmap[@"iocmWhereInstance"]];
                             break;
                     }//end dicom core and iocm
                     
                     NSLog(@"%@ %@ %@ %@ ", SELECT, FROM, LEFTJOIN, WHERE);
                     
                     
#pragma mark 1.1.1.3 completion block
                     //preformat results to simplified json in order to allow for clasification
                     //insert TimezoneOffsetFromUTC 00080201 and InstanceCreatorUID 00080014
                 }
                 
                 
                 
                 
                 
                 
                 else if ([loopPacs[@"dcm4cheelocaluri"] length]>0)
                 {
#pragma mark 1.1.2 dcm4cheelocaluri
                     //qido specific, count or limit
                     
                     //output format
                     /*
                     [
                      {
                          "0020000D":
                          {
                              "vr": "UI",
                              "Value":
                              [
                               "1.2.392.200036.9116.2.2.2.1762893313.1029997326.945873"
                               ]
                          }
                      }
                      ]
                      
                      */
                 }


                 
             }//end loop
                 
#pragma mark 2 admin operationqueue

#pragma mark 3 clasify response

#pragma mark 3 format response

             return [RSErrorResponse responseWithClientError:404 message:@"[fidji] to be continued"];
         }(request));}];
 }

         /*
          
          if (!hasSpecificFilter)
          {
          //count first
          NSUInteger sqlCount=[self countSqlProlog:loopPacs[@"sqlprolog"]
          from:FROM
          leftjoin:LEFTJOIN
          where:WHERE
          ];
          
          }
*/
         
         /*
                 //find loopPacs
             NSDictionary *loopPacs=DRS.devices[pacs];

             //(b) sql available
             NSDictionary *sqlmap=DRS.sqls[loopPacs[@"sqlmap"]];
             if (sqlmap)
             {
                 //create where
                 NSUInteger level=[pathSuffixMaxFilterNumber indexOfObject:urlComponents.path];
                 NSMutableString *whereString = [NSMutableString string];
                 switch (level) {
                     case studyLevel:
                         [whereString appendFormat:@" %@ ",(sqlmap[@"where"])[@"study"]];
                         break;
                     case seriesLevel:
                         [whereString appendFormat:@" %@ ",(sqlmap[@"where"])[@"series"]];
                         break;
                     case instanceLevel:
                         [whereString appendFormat:@" %@ ",(sqlmap[@"where"])[@"instance"]];
                         break;
                     default:
                         return [RSErrorResponse responseWithClientError:404 message:@"level %@ not accepted. Should be study, series or instance",urlComponents.path];
                         break;
                 }
                 
                 for (NSURLQueryItem *qi in urlComponents.queryItems)
                 {
                     if ([qi.name isEqualToString:@"pacs"]) continue;
                     
                     NSString *key=qidotag[qi.name];
                     if (!key) key=qi.name;
                     
                     NSDictionary *keyProperties=nil;
                     if (key) keyProperties=qidokey[key];
                     if (!keyProperties) return [RSErrorResponse responseWithClientError:404 message:@"%@ [not a valid qido filter for this PACS]",qi.name];
                     
                     //level check
                     if ( level < [keyProperties[@"level"] unsignedIntegerValue]) return [RSErrorResponse responseWithClientError:404 message:@"%@ [not available at level %@]",key,urlComponents.path];
                     
                     //string compare
                     if ([@[@"LO",@"PN",@"CS",@"UI"] indexOfObject:keyProperties[@"vr"]]!=NSNotFound)
                     {
                         [whereString appendString:
                          [NSString mysqlEscapedFormat:@" AND %@ like '%@'"
                                           fieldString:(sqlmap[@"attribute"])[key]
                                           valueString:qi.value
                           ]
                          ];
                         continue;
                     }
                     
                     
                     //date compare
                     if ([@[@"DA"] indexOfObject:keyProperties[@"vr"]]!=NSNotFound)
                     {
                         NSArray *startEnd=[qi.value componentsSeparatedByString:@"-"];
                         switch ([startEnd count]) {
                             case 1:;
                                 [whereString appendString:
                                  [
                                   (sqlmap[@"attribute"])[key]
                                   sqlFilterWithStart:startEnd[0]
                                   end:startEnd[0]
                                   ]
                                  ];
                                 break;
                             case 2:;
                                 [whereString appendString:
                                  [
                                   (sqlmap[@"attribute"])[key]
                                   sqlFilterWithStart:startEnd[0]
                                   end:startEnd[1]
                                   ]
                                  ];
                                 break;
                         }
                         continue;
                     }
                     
                 }//end loop
                 
                 //join parts of sql select
                 NSString *sqlScriptString=nil;
                 NSMutableString *select=[NSMutableString stringWithString:@" SELECT "];
                 switch (level) {
                     case 1:;
                         for (NSString* key in qido[@"studyselect"])
                         {
                             [select appendFormat:@"%@,",(sqlmap[@"attribute"])[key]];
                         }
                         [select deleteCharactersInRange:NSMakeRange([select length]-1,1)];
                         sqlScriptString=[NSString stringWithFormat:@"%@%@%@%@%@",
                                          loopPacs[@"sqlprolog"],
                                          select,
                                          (sqlmap[@"from"])[@"studypatient"],
                                          whereString,
                                          qido[@"studyformat"]
                                          ];
                         break;
                     case 2:;
                         for (NSString* key in qido[@"seriesselect"])
                         {
                             [select appendFormat:@"%@,",(sqlmap[@"attribute"])[key]];
                         }
                         [select deleteCharactersInRange:NSMakeRange([select length]-1,1)];
                         
                         sqlScriptString=[NSString stringWithFormat:@"%@%@%@%@%@",
                                          loopPacs[@"sqlprolog"],
                                          select,
                                          (sqlmap[@"from"])[@"seriesstudypatient"],
                                          whereString,
                                          qido[@"seriesformat"]
                                          ];
                         break;
                     case 3:;
                         for (NSString* key in qido[@"instanceselect"])
                         {
                             [select appendFormat:@"%@,",(sqlmap[@"attribute"])[key]];
                         }
                         [select deleteCharactersInRange:NSMakeRange([select length]-1,1)];
                         sqlScriptString=[NSString stringWithFormat:@"%@%@%@%@%@",
                                          loopPacs[@"sqlprolog"],
                                          select,
                                          (sqlmap[@"from"])[@"instansceseriesstudypatient"],
                                          whereString,
                                          qido[@"instanceformat"]
                                          ];
                         break;
                 }
                 LOG_DEBUG(@"%@",sqlScriptString);
                 
                 
                 //execute sql select
                 NSMutableData *mutableData=[NSMutableData mysqlTask:sqlScriptString sqlCharset:NSUTF8StringEncoding];
                 if (!mutableData) [RSErrorResponse responseWithClientError:404 message:@"%@",@"can not execute the sql"];
                 NSLog(@"hola");
                 //if (!task(@"/bin/bash",@[@"-s"],[sqlScriptString dataUsingEncoding:NSUTF8StringEncoding],mutableData))
                 //NotFound
                 
                 
                 //response can be almost empty
                 //in this case we remove lost ']'
                 if ([mutableData length]<10) return [RSDataResponse responseWithData:emptyJsonArray contentType:@"application/json"];
                 
                 //db response may be in latin1
                 NSStringEncoding charset=(NSStringEncoding)[loopPacs[@"sqlstringencoding"] longLongValue ];
                 if (charset!=4 && charset!=5) return [RSErrorResponse responseWithClientError:404 message:@"unknown sql charset : %lu",(unsigned long)charset];
                 
                 if (charset==5) //latin1
                 {
                     NSString *latin1String=[[NSString alloc]initWithData:mutableData encoding:NSISOLatin1StringEncoding];
                     [mutableData setData:[latin1String dataUsingEncoding:NSUTF8StringEncoding]];
                 }
                 
                 NSError *error=nil;
                 NSMutableArray *arrayOfDicts=[NSJSONSerialization JSONObjectWithData:mutableData options:0 error:&error];
                 if (error) return [RSErrorResponse responseWithClientError:404 message:@"bad qido sql result : %@",[error description]];
                 
                 //formato JSON qido
                 NSMutableArray *qidoResponseArray=[NSMutableArray array];
                 for (NSDictionary *dict in arrayOfDicts)
                 {
                     NSMutableDictionary *object=[NSMutableDictionary dictionary];
                     for (NSString *key in dict)
                     {
                         NSDictionary *attrDesc=qidokey[key];
                         NSMutableDictionary *attrInst=[NSMutableDictionary dictionary];
                         if ([attrDesc[@"vr"] isEqualToString:@"PN"])
                             [attrInst setObject:@[@{@"Alphabetic":dict[key]}] forKey:@"Value"];
                         else if ([attrDesc[@"vr"] isEqualToString:@"DA"]) [attrInst setObject:@[[dict[key] dcmDaFromDate]] forKey:@"Value"];
                         else [attrInst setObject:@[dict[key]] forKey:@"Value"];
                         //TODO add other cases, like TM, DT, etc...
                         
                         [attrInst setObject:attrDesc[@"vr"] forKey:@"vr"];
                         [object setObject:attrInst forKey:attrDesc[@"tag"]];
                     }
                     [qidoResponseArray addObject:object];
                 }
                 return [RSDataResponse responseWithData:
                         [NSJSONSerialization dataWithJSONObject:qidoResponseArray options:0 error:nil] contentType:@"application/json"];
             }
             
             //(c) qidolocaluri?
             if ([loopPacs[@"qidolocaluri"] length])
             {
                 NSString *qidolocaluriLevel=[loopPacs[@"qidolocaluri"] stringByAppendingString:urlComponents.path];
             }
             */
             
             
             /*
              NSString *qidoLocalString=loopPacs[@"qidolocaluri"];
              if ([qidoLocalString length]>0)
              {
              return qidoUrlProxy(
              
              [NSString stringWithFormat:@"%@/%@",qidoBaseString,urlPathComp.lastObject],
              =qidolocaluri + urlComponents.path
              ==qidoString
              ===pacsUri
              
              
              urlComponents.query,
              =urlComponents.query
              ==queryString
              
              
              [custodianbaseuri stringByAppendingString:urlComponents.path]
              =custodianglobaluri + urlComponents.path
              ==httpdicomString
              ===httpDicomUri
              );
              //urlPathComp.lastObject = ( studies | series | instances )
              //application/dicom+json not accepted
              }
              */
             /*
              //(d) global?
              if ([loopPacs[@"custodianglobaluri"] length])
              {
              #pragma mark TODO qido global proxying
              
              }
              
              
              //(e) not available
              return [RSErrorResponse responseWithClientError:404 message:@"[fidji] pacs %@ not available",pacs];
              
*/
                         

                                                                              
                                                                              /*
                                                                               else if ([includefieldSet containsObject:@"count"])
                                                                               {
                                                                               #pragma mark count result
                                                                               //acumulators
                                                                               NSUInteger total=0;
                                                                               
                                                                               for (NSString *oid in pacsToQuery)
                                                                               {
                                                                               NSDictionary *loopPacs=DRS.devices[oid];
                                                                               //sql available
                                                                               NSDictionary *sqlmap=DRS.sqls[loopPacs[@"sqlmap"]];
                                                                               if (sqlmap)
                                                                               {
                                                                               //sql count
                                                                               //create where
                                                                               NSUInteger level=[pathSuffixMaxFilterNumber indexOfObject:urlComponents.path];
                                                                               NSMutableString *selectString = [NSMutableString string];
                                                                               NSMutableString *fromString = [NSMutableString string];
                                                                               NSMutableString *whereString = [NSMutableString string];
                                                                               switch (level) {
                                                                               case 1://study
                                                                               [whereString appendFormat:@" %@ ",(sqlmap[@"where"])[@"study"]];
                                                                               break;
                                                                               case 2://series
                                                                               [whereString appendFormat:@" %@ ",(sqlmap[@"where"])[@"series"]];
                                                                               break;
                                                                               case 3://instances
                                                                               [whereString appendFormat:@" %@ ",(sqlmap[@"where"])[@"instance"]];
                                                                               break;
                                                                               }
                                                                               
                                                                               
                                                                               
                                                                               }
                                                                               else if ([loopPacs[@"qidocountextension"] length]>0)
                                                                               {
                                                                               //qidolocaluri+qidocountextension count
                                                                               
                                                                               }
                                                                               else LOG_WARNING(@"[fidji] pacs %@ lacks sql and qido count functions",oid);
                                                                               }
                                                                               }
                                                                               */
                                                                              
                                                                              
                                                                              
                                                                              //accumulators in format qido response
                                                                              //NSMutableArray *qidoResponseArray=[NSMutableArray array];
                                                                              /*
                                                                               [
                                                                               {
                                                                               "0020000D":
                                                                               [
                                                                               "1.2.392.200036.9116.2.2.2.1762893313.1029997326.945873"
                                                                               ]
                                                                               }
                                                                               ]
                                                                               
                                                                               to be transformed in
                                                                               
                                                                               [
                                                                               {
                                                                               "0020000D":
                                                                               {
                                                                               "vr": "UI",
                                                                               "Value":
                                                                               [
                                                                               "1.2.392.200036.9116.2.2.2.1762893313.1029997326.945873"
                                                                               ]
                                                                               }
                                                                               }
                                                                               ]
                                                                               */

@end
