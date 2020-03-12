#import "DRS+datatablesStudy.h"
#import "DRS+studyToken.h"

@implementation DRS (datatablesStudy)

+(void)datateblesStudySql4dictionary:(NSDictionary*)d
{
   NSString *maxCountString=d[@"max"];
   long long maxCount=0;
   if (maxCountString.length) maxCount=[maxCountString longLongValue];

   NSMutableArray *studyArray=[NSMutableArray arrayWithContentsOfFile:d[@"devOIDPLISTPath"]];
   
   BOOL maxCountOK=true;
   
   //case cache contains count
   if (studyArray)
   {
       if (   (studyArray.count==1)
           && [studyArray[0] isKindOfClass:[NSNumber class]]
           && ([studyArray[0] longLongValue] < maxCount)
          )
           [studyArray removeObjectAtIndex:0];
       else
           maxCountOK=(studyArray.count <= maxCount);
   }
   
   if (maxCountOK)
   {
      /*
       if there is a cache, should contain less records than max
       */
      
      //if there were no cache, initialize it with an empty array
      if (!studyArray) studyArray=[NSMutableArray array];
      
//sql init
      NSDictionary *devDict=DRS.pacs[d[@"devOID"]];
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
      if (sqlEPErrorReturned)
      {
         LOG_WARNING(@"%@",[sqlEPErrorReturned description]);
      }
      else if (EPDict.count)
      {
         if (maxCount < EPDict.count)
         {
            //cache count
            [[[NSString stringWithFormat:@"[%@]",maxCountString] dataUsingEncoding:NSUTF8StringEncoding] writeToFile:d[@"devOIDPLISTPath"] atomically:YES];
         }
         else if (EPDict.count != studyArray.count)
         {
            //continue only if there were less results than max
            
#pragma mark patient loop
         for (NSString *P in [NSSet setWithArray:[EPDict allValues]])
         {
            long long Plonglong=[P longLongValue];
            NSNumber *PKeyNumber=[NSNumber numberWithLongLong:Plonglong];
            
            NSString *PIDString=nil;
            NSString *PNameString=nil;
            NSString *PIssuerString=nil;
            NSString *PBirthDateString=nil;
            NSString *PSexString=nil;

            NSMutableArray *patientProperties=[studyArray firstMutableArrayWithObjectAtIndex:DEPKey isEqualToNumber:PKeyNumber];
            if (patientProperties)
            {
               PIDString=patientProperties[PID];
               PNameString=patientProperties[PName];
               PIssuerString=patientProperties[PIssuer];
               PBirthDateString=patientProperties[PBirthDate];
               PSexString=patientProperties[PSex];
            }
            else
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
               
               NSArray *sqlP=
               [patientData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:PName decreasing:NO
                ]
               [0];//NSUTF8StringEncoding


               PIDString=sqlP[PID];
               PNameString=[sqlP[PName] removeTrailingCarets];
               PIssuerString=sqlP[PIssuer];
               PBirthDateString=sqlP[PBirthDate];
               PSexString=sqlP[PSex];
            }
            
            
#pragma mark study loop
            for (NSString *E in [EPDict allKeysForObject:P])
            {
               long long Elonglong=[E longLongValue];
               NSNumber *EKeyNumber=[NSNumber numberWithLongLong:Elonglong];

               
               
               if (![studyArray firstMutableArrayWithObjectAtIndex:DEEKey isEqualToNumber:EKeyNumber])
               {
                  //from here on, we are dealing with a new record
                  
                  NSMutableData *studyData=[NSMutableData data];
                  if (execUTF8Bash(sqlcredentials,
                                    [NSString stringWithFormat:
                                     sqlDictionary[@"E"],
                                     sqlprolog,
                                     E,
                                     @"",
                                     sqlRecordSixteenUnits
                                     ],
                                    studyData)
                      !=0)
                  {
                     LOG_ERROR(@"studyToken study db error");
                     continue;
                  }
                  NSArray *sqlE=[studyData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:EDate decreasing:YES][0];//there is only one response
                   //NSUTF8StringEncoding
                  
                  
                  NSString *EDateTimeString=
                   [NSString stringWithFormat:@"%@-%@-%@ %@:%@",
                    [sqlE[EDate] substringToIndex:4],
                    [sqlE[EDate] substringWithRange:NSMakeRange(4,2)],
                    [sqlE[EDate] substringFromIndex:6],
                    [sqlE[ETime] substringToIndex:2],
                    [sqlE[ETime] substringWithRange:NSMakeRange(2,2)]
                    ];
                  //[sqlE[EDate]stringByAppendingString:[sqlE[ETime] substringToIndex:6]];
                   NSString *file=[[d[@"devOIDPLISTPath"] lastPathComponent]stringByDeletingPathExtension];
                   NSString *folder=[[d[@"devOIDPLISTPath"] stringByDeletingLastPathComponent] lastPathComponent];
                   //NSString *EKeyString=[sqlE[EKey] removeFirstAndLastSpaces];
                  //institution has the OID of the pacs
                   
                   NSString *SURLString=[NSString stringWithFormat:@"?EKey=%@&cache=%@&institution=%@&StudyInstanceUID=%@", sqlE[EKey], folder, file, sqlE[EUID] ];
                   
                   NSString *PURLString=nil;
                   if ([PIssuerString isEqualToString:@"NULL"])
                       PURLString=[NSString stringWithFormat:@"?PatientID=%@&cache=%@&institution=%@&max=1000&start=0&length=1000", PIDString, folder, file ];
                   else
                       PURLString=[NSString stringWithFormat:@"?PatientID=%@&issuer=%@&cache=%@&institution=%@&max=1000&start=0&length=1000", PIDString, PIssuerString, folder, file];
#pragma mark add a study record array
                  [studyArray addObject:
                   @[
                      @"",
                      SURLString,
                      sqlE[ERead],
                      PURLString,
                      PNameString,
                      EDateTimeString,
                      sqlE[EModalities],
                      sqlE[EDescription],
                      [sqlE[ERef] removeTrailingCarets],
                      sqlE[ESocial],
                      PIssuerString,
                      PBirthDateString,
                      PSexString,
                      sqlE[EAN],
                      sqlE[EANIssuerUID],
                      sqlE[EID],
                      sqlE[EUID],
                      EDateTimeString,
                      sqlE[EInstitution],
                      PKeyNumber,
                      EKeyNumber,
                      d[@"devOID"],
                      folder,
                      PIDString
                     ]
                   ];
               }
            }
         }//loop P
            [studyArray writeToFile:d[@"devOIDPLISTPath"] atomically:YES];
         }//maxCountOK2
      }//EPDict.count
   }//maxCountOK1
}
@end
