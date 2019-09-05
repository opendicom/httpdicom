#import "DRS+studyToken.h"
#import "LFCGzipUtility.h"
#import "DICMTypes.h"
#import "NSData+PCS.h"
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
      LOG_WARNING(@"studyToken PARAMS error: %@",errorString);
      return [RSErrorResponse responseWithClientError:404 message:@"%@",errorString];
   }
   for (NSUInteger idx=0;idx<[names count];idx++)
   {
      LOG_VERBOSE(@"studyToken PARAM \"%@\" = \"%@\"",names[idx],values[idx]);
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
   

   
#pragma mark custodianOID?
   NSInteger custodianOIDIndex=[names indexOfObject:@"custodianOID"];
   if (custodianOIDIndex==NSNotFound)
   {
      LOG_WARNING(@"studyToken custodianOID not available");
      return [RSErrorResponse responseWithClientError:404 message:@"studyToken custloianOID not available"];
   }
   
   NSMutableArray *wanCustodianOIDArray=[NSMutableArray array];
   NSMutableArray *devCustodianOIDArray=[NSMutableArray array];
   NSArray *custodianOIDArray=[values[custodianOIDIndex] componentsSeparatedByString:@"~"];
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
   if (SeriesNumberIndex!=NSNotFound) SeriesNumberArray=[values[SeriesNumberIndex] componentsSeparatedByString:@"~"];
   BOOL hasSeriesNumberRestriction=
   (
    SeriesNumberArray
    && [SeriesNumberArray count]
    && [SeriesNumberArray[0] length]
    );

//#pragma mark SeriesDescription
   NSArray *SeriesDescriptionArray=nil;
   NSInteger SeriesDescriptionIndex=[names indexOfObject:@"SeriesDescription"];
   if (SeriesDescriptionIndex!=NSNotFound) SeriesDescriptionArray=[values[SeriesDescriptionIndex] componentsSeparatedByString:@"~"];
   BOOL hasSeriesDescriptionRestriction=
   (
    SeriesDescriptionArray
    && [SeriesDescriptionArray count]
    && [SeriesDescriptionArray[0] length]
    );

//#pragma mark Modality
   NSArray *ModalityArray=nil;
   NSInteger ModalityIndex=[names indexOfObject:@"Modality"];
   if (ModalityIndex!=NSNotFound) ModalityArray=[values[ModalityIndex]componentsSeparatedByString:@"~"];
   BOOL hasModalityRestriction=
   (
    ModalityArray
    && [ModalityArray count]
    && [ModalityArray[0] length]
    );

//#pragma mark SOPClass
   NSArray *SOPClassArray=nil;
   NSInteger SOPClassIndex=[names indexOfObject:@"SOPClass"];
   if (SOPClassIndex!=NSNotFound) SOPClassArray=[values[SOPClassIndex]componentsSeparatedByString:@"~"];
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
   NSInteger StudyInstanceUIDsIndex=[names indexOfObject:@"StudyInstanceUID"];
   NSArray *StudyInstanceUIDArray=nil;
   NSInteger AccessionNumberIndex=[names indexOfObject:@"AccessionNumber"];
   NSString *AccessionNumberString=nil;
   NSInteger StudyDateIndex=[names indexOfObject:@"StudyDate"];
   NSString *StudyDateString=nil;
   NSInteger PatientIDIndex=[names indexOfObject:@"PatientID"];
   NSString *PatientIDString=nil;
   if ((StudyInstanceUIDsIndex!=NSNotFound)&&([values[StudyInstanceUIDsIndex] length]))
   {
      if (
            ((AccessionNumberIndex!=NSNotFound)&&([values[AccessionNumberIndex] length]))
          ||((StudyDateIndex!=NSNotFound)&&([values[StudyDateIndex] length]))
          ||((PatientIDIndex!=NSNotFound)&&([values[PatientIDIndex] length]))
          ) return [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken StudyInstanceUID shoud not be present together with AccessionNumber or StudyDate or PatientID"];
      for (NSString *uid in [values[StudyInstanceUIDsIndex]componentsSeparatedByString:@"~"])
      {
         if (![DICMTypes isSingleUIString:uid]) return [RSErrorResponse responseWithClientError:404 message:@"studyToken no StudyInstanceUID found in %@",uid];
      }
      StudyInstanceUIDArray=[values[StudyInstanceUIDsIndex]componentsSeparatedByString:@"~"];
   }
   else if ((AccessionNumberIndex!=NSNotFound)&&([values[AccessionNumberIndex] length]))
   {
      if (
            ((StudyDateIndex!=NSNotFound)&&([values[StudyDateIndex] length]))
          ||((PatientIDIndex!=NSNotFound)&&([values[StudyDateIndex] length]))
          ) return [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken AccessionNumber shoud not be present together with StudyDate or PatientID"];
       AccessionNumberString=values[AccessionNumberIndex];
   }
   else if ((PatientIDIndex!=NSNotFound)&&([values[PatientIDIndex] length])&&(StudyDateIndex!=NSNotFound)&&([values[StudyDateIndex] length]))
   {
      /*
       format options are:
       aaaa-mm-dd
       \\aaaa-mm-dd
       aaaa-mm-dd\\
       aaaa-mm-dd\\aaaa-mm-dd

       _DARegex = [NSRegularExpression regularExpressionWithPattern:@"^(19|20)\\d\\d(01|02|03|04|05|06|07|08|09|10|11|12)(01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31)$" options:0 error:NULL];
      
      return (bool)[DICMTypes.UIRegex numberOfMatchesInString:string options:0 range:NSMakeRange(0,[string length])];
      
      if(
         (qDate_start && [qDate_start length])
         ||(qDate_end && [qDate_end length])
         )
      {
          NSString *s=nil;
          if (qDate_start && [qDate_start length]) s=qDate_start;
          else s=@"";
          NSString *e=nil;
          if (qDate_end && [qDate_end length]) e=qDate_end;
          else e=@"";
          [studiesWhere appendString:[destSql[@"StudyDate"] sqlFilterWithStart:s end:e]];
      }

      -sqlFilterWithStart:(NSString*)start end:(NSString*)end
      {
          NSUInteger startLength=[start length];
          NSUInteger endLength=[end length];
          if (!start || !end || startLength+endLength==0) return @"";

          NSString *isoStart=nil;
          switch (startLength) {
              case 0:;
                  isoStart=@"";
                  break;
              case 8:;
                  isoStart=[NSString stringWithFormat:@"%@-%@-%@",
                        [start substringWithRange:NSMakeRange(0, 4)],
                        [start substringWithRange:NSMakeRange(4, 2)],
                        [start substringWithRange:NSMakeRange(6, 2)]
                        ];
              break;
              case 10:;
                  isoStart=start;
              
              default:
                  return @"";
              break;
          }

          NSString *isoEnd=nil;
          switch (endLength) {
              case 0:;
              isoEnd=@"";
              break;
              case 8:;
              isoEnd=[NSString stringWithFormat:@"%@-%@-%@",
                        [end substringWithRange:NSMakeRange(0, 4)],
                        [end substringWithRange:NSMakeRange(4, 2)],
                        [end substringWithRange:NSMakeRange(6, 2)]
                        ];
              break;
              case 10:;
              isoEnd=end;
              
              default:
              return @"";
              break;
          }

          if (startLength==0) return [NSString stringWithFormat:@" AND DATE(%@) <= '%@'", self, isoEnd];
          else if (endLength==0) return [NSString stringWithFormat:@" AND DATE(%@) >= '%@'", self, isoStart];
          else if ([isoStart isEqualToString:isoEnd]) return [NSString stringWithFormat:@" AND DATE(%@) = '%@'", self, isoStart];
          else return [NSString stringWithFormat:@" AND DATE(%@) >= '%@' AND DATE(%@) <= '%@'", self, isoStart, self, isoEnd];
          
          return @"";
      }
 */
      
       PatientIDString=values[PatientIDIndex];
       StudyDateString=values[StudyDateIndex];
   }
   else return [RSErrorResponse responseWithClientError:404 message:@"%@",@"studyToken one of StudyInstanceUID, AccessionNumber or PatientID+StudyDate should be present"];
  

   //issuer
   NSString *issuerString=nil;
   NSInteger issuerIndex=[names indexOfObject:@"issuer"];
   if (issuerIndex!=NSNotFound) issuerString=values[issuerIndex];
   else issuerString=@"";




#pragma mark -
#pragma mark ACCESS switch

   NSInteger accessTypeIndex=[names indexOfObject:@"accessType"];
   if (accessTypeIndex==NSNotFound) [RSErrorResponse responseWithClientError:404 message:@"studyToken accessType required in request"];
   NSInteger accessType=[@[@"weasis",@"cornerstone",@"dicomzip",@"osirix",@"datatablesSeries"]  indexOfObject:values[accessTypeIndex]];
   if (accessType==NSNotFound) [RSErrorResponse responseWithClientError:404 message:@"studyToken accessType %@ unknown",values[accessTypeIndex]];

   

   switch (accessType) {
      case accessTypeWeasis:{
         return [DRS
                 weasisWithProxyURI:proxyURIString
                 session:sessionString
                 devCustodianOIDArray:devCustodianOIDArray
                 wanCustodianOIDArray:wanCustodianOIDArray
                 hasRestriction:hasRestriction
                 SeriesNumberArray:SeriesNumberArray
                 SeriesDescriptionArray:SeriesDescriptionArray
                 ModalityArray:ModalityArray
                 SOPClassArray:SOPClassArray
                 StudyInstanceUIDArray:StudyInstanceUIDArray
                 AccessionNumberString:AccessionNumberString
                 PatientIDString:PatientIDString
                 StudyDateString:StudyDateString
                 issuerString:issuerString
                 ];
         } break;//end of sql wado weasis
      case accessTypeCornerstone:{
         return [DRS
                 cornerstoneWithProxyURI:proxyURIString
                 session:sessionString
                 devCustodianOIDArray:devCustodianOIDArray
                 wanCustodianOIDArray:wanCustodianOIDArray
                 hasRestriction:hasRestriction
                 SeriesNumberArray:SeriesNumberArray
                 SeriesDescriptionArray:SeriesDescriptionArray
                 ModalityArray:ModalityArray
                 SOPClassArray:SOPClassArray
                 StudyInstanceUIDArray:StudyInstanceUIDArray
                 AccessionNumberString:AccessionNumberString
                 PatientIDString:PatientIDString
                 StudyDateString:StudyDateString
                 issuerString:issuerString
                 ];
         } break;//end of sql wado cornerstone
      case accessTypeDicomzip:{
         } break;//end of sql wado dicomzip
      case accessTypeOsirix:{
         } break;//end of sql wado osirix
      case accessTypeDatatablesSeries:{
         } break;//end of sql wado osirix
   }

/*
 there are studies for this custodian
 
               case accessTypeDicomzip:{
                  patientArray=[NSMutableArray array];
                  
                   - create
                   {
                     pacsUID:[{
                        studyUID:[{
                           seriesUID:[
                              instanceUID,
                   */


//#pragma mark instance loop
   return [RSErrorResponse responseWithClientError:404 message:@"studyToken should not be here"];

}


+(RSResponse*)weasisWithProxyURI:(NSString*)proxyURIString
                        session:(NSString*)sessionString
           devCustodianOIDArray:(NSMutableArray*)devCustodianOIDArray
           wanCustodianOIDArray:(NSMutableArray*)wanCustodianOIDArray
                 hasRestriction:(BOOL)hasRestriction
              SeriesNumberArray:(NSArray*)SeriesNumberArray
         SeriesDescriptionArray:(NSArray*)SeriesDescriptionArray
                  ModalityArray:(NSArray*)ModalityArray
                  SOPClassArray:(NSArray*)SOPClassArray
          StudyInstanceUIDArray:(NSArray*)StudyInstanceUIDArray
          AccessionNumberString:(NSString*)AccessionNumberString
                PatientIDString:(NSString*)PatientIDString
                 StudyDateString:(NSString*)StudyDateString
                    issuerString:(NSString*)issuerString
{
   NSXMLElement *XMLRoot=[WeasisManifest manifest];
            
   if (devCustodianOIDArray.count > 1)
   {
      //add nodes and start corresponding processes
   }

   if (wanCustodianOIDArray.count > 0)
   {
      //add nodes and start corresponding processes
   }

   if (devCustodianOIDArray.count == 0)
   {
      //add nodes and start corresponding processes
   }
   else
   {
      while (1)
      {
         NSString *custodianString=devCustodianOIDArray[0];
         NSDictionary *custodianDict=DRS.pacs[custodianString];

#pragma mark · GET type index
         NSUInteger getTypeIndex=[@[@"file",@"folder",@"wado",@"wadors",@"cget",@"cmove"] indexOfObject:custodianDict[@"get"]];

#pragma mark · SELECT switch
         switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:custodianDict[@"select"]]) {
            
            case NSNotFound:{
               LOG_WARNING(@"studyToken pacs %@ lacks \"select\" type property",custodianString);
            } break;
               
            case selectTypeSql:{
   #pragma mark · SQL SELECT (unique option for now)
               NSDictionary *sqlcredentials=@{custodianDict[@"sqluser"]:custodianDict[@"sqlpassword"]};
               NSString *sqlprolog=custodianDict[@"sqlprolog"];
               NSDictionary *sqlDictionary=DRS.sqls[custodianDict[@"sqlmap"]];

               
   #pragma mark · apply Patient Study filters
         
               NSMutableDictionary *EPDict=[NSMutableDictionary dictionary];
               NSMutableData *mutableData=[NSMutableData data];

   //#pragma mark StudyInstanceUID
               
               if (StudyInstanceUIDArray)
               {
                  for (NSString *uid in StudyInstanceUIDArray)
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
                   if (AccessionNumberString)
                   {
                      [mutableData setData:[NSData data]];
                      if (execUTF8Bash(sqlcredentials,
                                        [NSString stringWithFormat:
                                         sqlDictionary[@"sqlPE4Ean"],
                                         sqlprolog,
                                         AccessionNumberString,
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
                   else if (PatientIDString)
                   {
                       //issuer?
                       [mutableData setData:[NSData data]];
                       if (execUTF8Bash(sqlcredentials,
                                        [NSString stringWithFormat:
                                         sqlDictionary[@"sqlPE4PidEda"],
                                         sqlprolog,
                                         PatientIDString,
                                         StudyDateString,
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

/*
   there are studies for this custodian
*/
               NSXMLElement *arcQueryElement=
                     [WeasisArcQuery
                      arcQueryOID:custodianString
                      custodian:proxyURIString
                      session:sessionString
                      seriesNumbers:SeriesNumberArray
                      seriesDescriptions:SeriesDescriptionArray
                      modalities:ModalityArray
                      SOPClasses:SOPClassArray
                      overrideDicomTagsList:@""
                      ];
                     [XMLRoot addChild:arcQueryElement];

#pragma mark ·· GET switch
               switch (getTypeIndex) {
                     
                  case NSNotFound:{
                     LOG_WARNING(@"studyToken pacs %@ lacks \"get\" property",custodianString);
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
                        NSArray *patientPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding
                        PatientElement=
                        [WeasisPatient
                         pk:(patientPropertiesArray[0])[0]
                         pid:(patientPropertiesArray[0])[1]
                         name:(patientPropertiesArray[0])[2]
                         issuer:(patientPropertiesArray[0])[3]
                         birthdate:(patientPropertiesArray[0])[4]
                         sex:(patientPropertiesArray[0])[5]
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

                           StudyElement=
                           [WeasisStudy
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
                       
                       //if there is restriction and does't match
                        if (hasRestriction)
                        {
                            if (
                                !(SeriesNumberArray.count && [SeriesNumberArray indexOfObject:SProperties[3]]!=NSNotFound)
                                && !(SeriesDescriptionArray.count && [SeriesDescriptionArray indexOfObject:SProperties[2]]!=NSNotFound)
                                && !(ModalityArray.count && [ModalityArray indexOfObject:SProperties[4]]!=NSNotFound)
                                && !(SOPClassArray.count && [SOPClassArray indexOfObject:(IPropertiesFirstRecord[0])[3]]!=NSNotFound)
                                ) continue;
                        }
                        
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
NSXMLElement *SeriesElement=[WeasisSeries pk:SProperties[0]
                               uid:SProperties[1]
                              desc:SProperties[2]
                               num:SProperties[3]
                               mod:SProperties[4]
                               wts:@"*"
                               sop:(IPropertiesFirstRecord[0])[3]
                                             ];//DirectDownloadThumbnail=\"%@\"
                              [StudyElement addChild:SeriesElement];
                              

//#pragma mark instance loop
                        for (NSArray *IProperties in IPropertiesArray)
                        {
//#pragma mark instance loop
NSXMLElement *InstanceElement=[WeasisInstance
                               pk:IProperties[0]
                               uid:IProperties[1]
                               num:IProperties[2]
                               ];//DirectDownloadFile
                             [SeriesElement addChild:InstanceElement];
                           }
                              }//end for each I
                           }// end for each S
                        }//end for each E
                     }//end for each P
                  } break;//end of WADO
               }// end of GET switch
            } break;//end of sql
         } //end of SELECT switch

         /*
          if (!XMLRoot.childCount)
          {
          }
          */
         NSXMLDocument *doc=[NSXMLDocument documentWithRootElement:XMLRoot];
          doc.documentContentKind=NSXMLDocumentXMLKind;
          doc.characterEncoding=@"UTF-8";
          /*
          NSData *docData=[doc XMLData];
          return
          [RSDataResponse
           responseWithData:docData
           contentType:@"text/xml"
           ];
           */
         return
         [RSDataResponse
          responseWithData:[LFCGzipUtility gzipData:[doc XMLData]]
          contentType:@"application/x-gzip"
          ];

//base64 dicom:get -i does not work
/*
RSDataResponse *response=[RSDataResponse responseWithData:[[[LFCGzipUtility gzipData:[xmlweasismanifest dataUsingEncoding:NSUTF8StringEncoding]] base64EncodedStringWithOptions:0]dataUsingEncoding:NSUTF8StringEncoding] contentType:@"application/x-gzip"];
[response setValue:@"Base64" forAdditionalHeader:@"Content-Transfer-Encoding"];//https://tools.ietf.org/html/rfc2045
return response;

//xml dicom:get -iw works also, like with gzip
return [RSDataResponse
responseWithData:[xmlweasismanifest dataUsingEncoding:NSUTF8StringEncoding]
contentType:@"text/xml"];
*/
               
               
      }//end while 1

   }//end at least one dev
   return [RSErrorResponse responseWithClientError:404 message:@"studyToken should not be here"];
}

+(RSResponse*)cornerstoneWithProxyURI:(NSString*)proxyURIString
                              session:(NSString*)sessionString
                 devCustodianOIDArray:(NSMutableArray*)devCustodianOIDArray
                 wanCustodianOIDArray:(NSMutableArray*)wanCustodianOIDArray
                       hasRestriction:(BOOL)hasRestriction
                    SeriesNumberArray:(NSArray*)SeriesNumberArray
               SeriesDescriptionArray:(NSArray*)SeriesDescriptionArray
                        ModalityArray:(NSArray*)ModalityArray
                        SOPClassArray:(NSArray*)SOPClassArray
                StudyInstanceUIDArray:(NSArray*)StudyInstanceUIDArray
                AccessionNumberString:(NSString*)AccessionNumberString
                      PatientIDString:(NSString*)PatientIDString
                      StudyDateString:(NSString*)StudyDateString
                         issuerString:(NSString*)issuerString
{
      NSMutableArray *JSONArray=[NSMutableArray array];

      if (devCustodianOIDArray.count > 1)
      {
         //add nodes and start corresponding processes
      }

      if (wanCustodianOIDArray.count > 0)
      {
         //add nodes and start corresponding processes
      }

      if (devCustodianOIDArray.count == 0)
      {
         //add nodes and start corresponding processes
      }
      else
      {
         while (1)
         {
            NSString *custodianString=devCustodianOIDArray[0];
            NSDictionary *custodianDict=DRS.pacs[custodianString];

   #pragma mark · GET type index
            NSUInteger getTypeIndex=[@[@"file",@"folder",@"wado",@"wadors",@"cget",@"cmove"] indexOfObject:custodianDict[@"get"]];

   #pragma mark · SELECT switch
            switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:custodianDict[@"select"]]) {
               
               case NSNotFound:{
                  LOG_WARNING(@"studyToken pacs %@ lacks \"select\" type property",custodianString);
               } break;
                  
               case selectTypeSql:{
      #pragma mark · SQL SELECT (unique option for now)
                  NSDictionary *sqlcredentials=@{custodianDict[@"sqluser"]:custodianDict[@"sqlpassword"]};
                  NSString *sqlprolog=custodianDict[@"sqlprolog"];
                  NSDictionary *sqlDictionary=DRS.sqls[custodianDict[@"sqlmap"]];

                  
      #pragma mark · apply Patient Study filters
            
                  NSMutableDictionary *EPDict=[NSMutableDictionary dictionary];
                  NSMutableData *mutableData=[NSMutableData data];

      //#pragma mark StudyInstanceUID
                  
                  if (StudyInstanceUIDArray)
                  {
                     for (NSString *uid in StudyInstanceUIDArray)
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
                      if (AccessionNumberString)
                      {
                         [mutableData setData:[NSData data]];
                         if (execUTF8Bash(sqlcredentials,
                                           [NSString stringWithFormat:
                                            sqlDictionary[@"sqlPE4Ean"],
                                            sqlprolog,
                                            AccessionNumberString,
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
                      else if (PatientIDString)
                      {
                          //issuer?
                          [mutableData setData:[NSData data]];
                          if (execUTF8Bash(sqlcredentials,
                                           [NSString stringWithFormat:
                                            sqlDictionary[@"sqlPE4PidEda"],
                                            sqlprolog,
                                            PatientIDString,
                                            StudyDateString,
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

#pragma mark ··· CORNERSTONE (TODO remove limitation)
                  if ([EPDict count]>1) [RSErrorResponse responseWithClientError:404 message:@"%@",@"accessType cornerstone can not be applied to more than a study"];
/*
      there is one study for this custodian
*/
                  NSMutableArray *patientArray=[NSMutableArray array];
                  [JSONArray addObject:
                   @{
                     @"arcId":custodianString,
                     @"baseUrl":proxyURIString,
                     @"additionnalParameters":
                        [NSString stringWithFormat:@"&amp;session=%@&amp;custodianOID=%@&amp;SeriesNumber=%@&amp;SeriesDescription=%@&amp;Modality=%@&amp;SOPClass=%@",
                         sessionString,
                         custodianString,
                         [SeriesNumberArray componentsJoinedByString:@"\\"],
                         [SeriesDescriptionArray componentsJoinedByString:@"\\"],
                         [ModalityArray componentsJoinedByString:@"\\"],
                         [SOPClassArray componentsJoinedByString:@"\\"]
                        ],
                     @"overrideDicomTagsList":@"",
                     @"patientList":patientArray
                     }
                   ];

   #pragma mark ·· GET switch
                  switch (getTypeIndex) {
                        
                     case NSNotFound:{
                        LOG_WARNING(@"studyToken pacs %@ lacks \"get\" property",custodianString);
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
                               patientName
                               patientId
                               studyDate
                               modality (in Study)
                               studyDescription
                               numImages
                               studyId
                               */
                              NSMutableArray *seriesArray=[NSMutableArray array];//Study=Exam
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
                            if (hasRestriction)
                            {
                                if (
                                    !(SeriesNumberArray.count && [SeriesNumberArray indexOfObject:SProperties[3]]!=NSNotFound)
                                    && !(SeriesDescriptionArray.count && [SeriesDescriptionArray indexOfObject:SProperties[2]]!=NSNotFound)
                                    && !(ModalityArray.count && [ModalityArray indexOfObject:SProperties[4]]!=NSNotFound)
                                    && !(SOPClassArray.count && [SOPClassArray indexOfObject:(IPropertiesFirstRecord[0])[3]]!=NSNotFound)
                                    )continue;
                            }

                           
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

                                 }//end for each I
                              }// end for each S
                           }//end for each E
                        }//end for each P
                     } break;//end of WADO
                  }// end of GET switch
               } break;//end of sql
            } //end of SELECT switch
            }
            NSData *cornerstoneJson=[NSJSONSerialization dataWithJSONObject:JSONArray options:0 error:nil];
            LOG_DEBUG(@"cornerstone manifest :\r\n%@",[[NSString alloc] initWithData:cornerstoneJson encoding:NSUTF8StringEncoding]);
            return [RSDataResponse responseWithData:cornerstoneJson contentType:@"application/json"];

         }//end while 1

      }//end at least one dev



   return [RSErrorResponse responseWithClientError:404 message:@"studyToken should not be here"];
}

@end
