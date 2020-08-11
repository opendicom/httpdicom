#import "DRS+datatablesStudy.h"
#import "DRS+studyToken.h"

@implementation DRS (datatablesStudy)

+(void)datateblesStudySql4dictionary:(NSDictionary*)d
{
   long long maxCount=100;
   if ([d[@"max"] length]) maxCount=[d[@"max"] longLongValue];

   BOOL tooMuchStudies=false;
   BOOL isStudyArrayComplete=false;

   
#pragma mark studyArray from devOIDPLIST or new
   NSMutableArray *studyArray=nil;
   
    studyArray=[NSMutableArray arrayWithContentsOfFile:d[@"devOIDPLISTPath"]];
    if (studyArray)
    {
      //contains a number
      if (   (studyArray.count==1)
          && [studyArray[0] isKindOfClass:[NSNumber class]])
      {
          if ([studyArray[0] longLongValue] <= maxCount) [studyArray removeObjectAtIndex:0];
          else tooMuchStudies=![d[@"new"]isEqualToString:@"true"];
          //if new is true we can not presume how much studies there will be
      }
    }
    else studyArray=[NSMutableArray array];

    
   if (!tooMuchStudies)
   {
      /*
       studyArray contains zero o more answers
       One can query the count of responses and/or the list of results
       
       We apply alternative strategies depending on the filters:
       
       (1) StudyInstanceUID: execute list only if the studyArray.count=0
       
       (2) AccessionNumber: execute list
       
       (3) any filter:
       
       (3.1) studyArray.count <= 200: execute list
       
       (3.2) studyArray.count > 200 : count and then if different list
       
       */
      
      NSDictionary *devDict=DRS.pacs[d[@"devOID"]];
      NSDictionary *sqlDictionary=DRS.sqls[devDict[@"sqlmap"]];

      NSString *Ecount=nil; //shall not be nil only in case 3.2
      NSMutableString *Eand=[NSMutableString string];

      
      
#pragma mark - Euid
      if (d[@"StudyInstanceUIDRegexpString"] && studyArray.count)
      {
         //study not in cache (!studyArray.count)
         isStudyArrayComplete=true;
         
         [Eand stringByAppendingFormat:
              sqlDictionary[@"EmatchEui"],
              d[@"StudyInstanceUIDRegexpString"]
              ];
         }
      else if (d[@"AccessionNumberEqualString"])
#pragma mark - EA
      {
         switch ([d[@"issuerArray"] count]) {
               
            case issuerNone:
               [Eand stringByAppendingFormat:
                    (sqlDictionary[@"EmatchEan"])[issuerNone],
                    d[@"AccessionNumberEqualString"]
                    ];
               break;

            case issuerLocal:
               [Eand stringByAppendingFormat:
                    (sqlDictionary[@"EmatchEan"])[issuerLocal],
                    d[@"AccessionNumberEqualString"],
                    d[@"issuerArray"][0]
                    ];
               break;
                     
            case issuerUniversal:
               [Eand stringByAppendingFormat:
                    (sqlDictionary[@"EmatchEan"])[issuerUniversal],
                    d[@"AccessionNumberEqualString"],
                    d[@"issuerArray"][1],
                    d[@"issuerArray"][2]
                    ];
               break;
                        
            case issuerDivision:
               [Eand stringByAppendingFormat:
                (sqlDictionary[@"EmatchEan"])[issuerDivision],
                d[@"AccessionNumberEqualString"],
                d[@"issuerArray"][0],
                d[@"issuerArray"][1],
                d[@"issuerArray"][2]
                ];
               break;

            default:
               LOG_WARNING(@"studyToken accessionNumber issuer error '%@'",[d[@"issuerArray"] componentsJoinedByString:@"^"]);
               break;
         }
      }
      else
#pragma mark - varios EP
      {
         //marking the requirement to count before listing
         if (studyArray.count > 200) Ecount=sqlDictionary[@"Ecount"];
 
                  
         if (d[@"PatientIDLikeString"])
#pragma mark 1 PI
         {
            switch ([d[@"issuerArray"] count]) {
                  
               case issuerNone:
                  [Eand appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPid])[issuerNone],d[@"PatientIDLikeString"]];
                  break;

               case issuerLocal:
                  [Eand appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPid])[issuerLocal],d[@"PatientIDLikeString"],d[@"issuerArray"][0]];
                  break;

               default:
                  LOG_WARNING(@"studyToken patientID issuer error '%@'",[d[@"issuerArray"] componentsJoinedByString:@"^"]);
                  break;
            }
         }
         
#pragma mark 2 PN
         if (d[@"patientArray"])
         {
            NSArray *patientArray=d[@"patientArray"];
            NSString *compoundFormat=((sqlDictionary[@"Eand"])[EcumulativeFilterPpn])[pnFilterCompound];
            if (compoundFormat.length)
            {
                NSMutableArray *jockerArray=[NSMutableArray array];
                for (NSString *component in patientArray)
                {
                    if (component.length) [jockerArray addObject:component];
                    else [jockerArray addObject:@".*"];
                }
                [Eand appendFormat:compoundFormat,[jockerArray componentsJoinedByString:@"\\\\\\\\^"]];
            }
            else
            {
               //DB with pn detailed fields
               NSArray *formats=(sqlDictionary[@"Eand"])[EcumulativeFilterPpn];
               for (NSUInteger i=0;i<patientArray.count;i++)
               {
                  if (patientArray[0] && [patientArray[0] length]) [Eand appendFormat:formats[i+1],patientArray[0]];
               }
            }
         }
         
#pragma mark 3 Eid
         if (d[@"StudyIDLikeString"]) [Eand appendFormat:(sqlDictionary[@"Eand"])[EcumulativeFilterEid],d[@"StudyIDLikeString"]];

#pragma mark 4 Eda
         if (d[@"StudyDateArray"])
         {
            NSArray *Eda=nil;
            BOOL isoMatching=true;
            if ([((sqlDictionary[@"Eand"])[EcumulativeFilterEda])[0] count])
            {
                //isoMatching
                Eda=((sqlDictionary[@"Eand"])[EcumulativeFilterEda])[0];
            }
            else
            {
                isoMatching=false;//dicom DA matching
                Eda=((sqlDictionary[@"Eand"])[EcumulativeFilterEda])[1];
            }
            switch ([d[@"StudyDateArray"] count]) {
               case dateMatchAny:
                  break;
               case dateMatchOn:
               {
                  [Eand appendFormat:Eda[dateMatchOn],
                   isoMatching?d[@"StudyDateArray"][0]:[DICMTypes DAStringFromDAISOString:d[@"StudyDateArray"][0]]
                   ];
               } break;
               case dateMatchSince:
               {
                  [Eand appendFormat:Eda[dateMatchSince],
                   isoMatching?d[@"StudyDateArray"][0]:[DICMTypes DAStringFromDAISOString:d[@"StudyDateArray"][0]]
                   ];
               } break;
               case dateMatchUntil:
               {
                  [Eand appendFormat:Eda[dateMatchUntil],
                   isoMatching?d[@"StudyDateArray"][2]:[DICMTypes DAStringFromDAISOString:d[@"StudyDateArray"][2]]
                   ];

               } break;
               case dateMatchBetween:
               {
                  [Eand appendFormat:Eda[dateMatchBetween],
                   isoMatching?(d[@"StudyDateArray"])[0]:[DICMTypes DAStringFromDAISOString:d[@"StudyDateArray"][0]],
                   isoMatching?d[@"StudyDateArray"][3]:[DICMTypes DAStringFromDAISOString:d[@"StudyDateArray"][3]]
                   ];

               } break;
            }
         }


#pragma mark 5 Edesc
         if (d[@"StudyDescriptionRegexpString"]) [Eand appendFormat:(sqlDictionary[@"Eand"])[EcumulativeFilterElo],d[@"StudyDescriptionRegexpString"]];
         
       }

      if (!isStudyArrayComplete)
      {
#pragma mark - sql init
         NSMutableData * mutableData=[NSMutableData data];

         
#pragma mark Eaccesscontrol
         
          [Eand stringByAppendingString:d[@"Eaccesscontrol"]];
         
         LOG_VERBOSE(@"%@",Eand);

#pragma mark execute Ecount
         
         if (Ecount)
         {
            if (execUTF8Bash(
                 @{devDict[@"sqlcredentials"]:devDict[@"sqlpassword"]},
                 [NSString stringWithFormat:@"%@\"%@%@%@\"%@",
                  devDict[@"sqlprolog"],
                  sqlDictionary[@"Ecount"],
                  sqlDictionary[@"Ewhere"],
                  Eand,
                  sqlonevalue
                  ],
                   mutableData
                  )
                );
            NSString *EcountString=[[NSString alloc]initWithData:mutableData encoding:NSASCIIStringEncoding];
            long long Ecountll=[EcountString longLongValue];
            if (Ecountll==studyArray.count) return;
            if (Ecountll > maxCount)
            {
               NSError *error=nil;
               if (![EcountString writeToFile:d[@"devOIDPLISTPath"] atomically:NO encoding:NSASCIIStringEncoding error:&error]) LOG_ERROR(@"can not write at %@. %@",d[@"devOIDPLISTPath"],[error description]);
               return;
            }
         }

#pragma mark execute list
         

         
         //six parts: prolog,select,where,and,limit&order,format
         NSString *bash=[NSString stringWithFormat:@"%@\"%@%@%@%@\"%@",
                         devDict[@"sqlprolog"],
                         sqlDictionary[@"Eselect4dt"],
                         sqlDictionary[@"Ewhere"],
                         Eand,
                         sqlDictionary[@"Eorderdesc"],
                         sqlRecordTwentyNineUnits
                         ];
         if (execUTF8Bash(
              @{devDict[@"sqlcredentials"]:devDict[@"sqlpassword"]},
              bash,
              mutableData)
              !=0) LOG_ERROR(@"%@",bash);

          if ([mutableData length])
          {
              NSArray *dtE=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding stringUnitsPostProcessTitle:@"replaceCacheInstitution" dictionary:@{@"_institution_":d[@"devOID"], @"_cache_":[[d[@"devOIDPLISTPath"] stringByDeletingLastPathComponent]lastPathComponent]} orderedByUnitIndex:NSNotFound decreasing:NO];//NSUTF8StringEncoding

             if (dtE.count)
             {
                if (maxCount < dtE.count) [[[NSString stringWithFormat:@"[%lu]",(unsigned long)dtE.count] dataUsingEncoding:NSUTF8StringEncoding] writeToFile:d[@"devOIDPLISTPath"] atomically:YES];
                else [dtE writeToFile:d[@"devOIDPLISTPath"] atomically:YES];
             }
         }
      }//!isStudyArrayComplete
   }//tooMuchStudies
}
@end
