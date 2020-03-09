/*
 TODO
 socket in messages
 access types other lan and wan nodes
 osirix dcmURLs
 datatablesSeries
 datatablesPatient
 wadors study
 wadors series
 zip real compression
 tokenFolder keeping zipped
 */

#import "DRS+studyToken.h"


const uint8 startSquareBracket='[';
const uint8 semicolon=',';
const uint8 endSquareBracket=']';


/*
study pk and patient pk of studies selected
*/
RSResponse * sqlEP(
 NSMutableDictionary * EPDict,
 NSDictionary        * sqlcredentials,
 NSDictionary        * sqlDictionary,
 NSString            * sqlprolog,
 BOOL                EuiE,
 NSString            * StudyInstanceUIDRegexpString,
 NSString            * AccessionNumberEqualString,
 NSString            * refInstitutionLikeString,
 NSString            * refServiceLikeString,
 NSString            * refUserLikeString,
 NSString            * refIDLikeString,
 NSString            * refIDTypeLikeString,
 NSString            * readInstitutionSqlLikeString,
 NSString            * readServiceSqlLikeString,
 NSString            * readUserSqlLikeString,
 NSString            * readIDSqlLikeString,
 NSString            * readIDTypeSqlLikeString,
 NSString            * StudyIDLikeString,
 NSString            * PatientIDLikeString,
 NSString            * patientFamilyLikeString,
 NSString            * patientGivenLikeString,
 NSString            * patientMiddleLikeString,
 NSString            * patientPrefixLikeString,
 NSString            * patientSuffixLikeString,
 NSArray             * issuerArray,
 NSArray             * StudyDateArray,
 NSString            * SOPClassInStudyRegexpString,
 NSString            * ModalityInStudyRegexpString,
 NSString            * StudyDescriptionRegexpString
)
{
   NSMutableData * mutableData=[NSMutableData data];
   if (StudyInstanceUIDRegexpString)
#pragma mark · StudyInstanceUID
   {
//six parts: prolog,select,where,and,limit&order,format
      if (execUTF8Bash(
          sqlcredentials,
          [NSString stringWithFormat:@"%@\"%@%@%@%@\"%@",
           sqlprolog,
            EuiE?sqlDictionary[@"EselectEuiE"]:sqlDictionary[@"EselectEP"],
           sqlDictionary[@"Ewhere"],
           [NSString stringWithFormat:
            sqlDictionary[@"EmatchEui"],
            StudyInstanceUIDRegexpString
            ],
           @"",
           sqlTwoPks
          ],
          mutableData)
          !=0) return [RSErrorResponse responseWithClientError:404 message:@"studyToken StudyInstanceUID %@ db error",StudyInstanceUIDRegexpString];
   }
   else if (AccessionNumberEqualString)
#pragma mark · AccessionNumber
   {

      switch (issuerArray.count) {
            
         case issuerNone:
         {
            if (execUTF8Bash(sqlcredentials,
                        [NSString stringWithFormat:@"%@\"%@%@%@%@\"%@",
                         sqlprolog,
                         EuiE?sqlDictionary[@"EselectEuiE"]:sqlDictionary[@"EselectEP"],
                         sqlDictionary[@"Ewhere"],
                         [NSString stringWithFormat:
                          (sqlDictionary[@"EmatchEan"])[issuerNone],
                          AccessionNumberEqualString
                          ],
                         @"",
                         sqlTwoPks
                        ],
                        mutableData)
                !=0) return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessionNumber db error. AN='%@' issuer='%@'",AccessionNumberEqualString,[issuerArray componentsJoinedByString:@"^"]];
            } break;

         case issuerLocal:
         {
            if (execUTF8Bash(sqlcredentials,
                             [NSString stringWithFormat:@"%@\"%@%@%@%@%@\"%@",
                              sqlprolog,
                              EuiE?sqlDictionary[@"EselectEuiE"]:sqlDictionary[@"EselectEP"],
                              ((sqlDictionary[@"Ejoin"])[0])[0],
                              sqlDictionary[@"Ewhere"],
                              [NSString stringWithFormat:
                               (sqlDictionary[@"EmatchEan"])[issuerLocal],
                               AccessionNumberEqualString,
                               issuerArray[0]
                               ],
                              @"",
                              sqlTwoPks
                             ],
                             mutableData)
                !=0) return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessionNumber db error. AN='%@' issuer='%@'",AccessionNumberEqualString,[issuerArray componentsJoinedByString:@"^"]];
         } break;
                  
         case issuerUniversal:
         {
            if (execUTF8Bash(sqlcredentials,
                             [NSString stringWithFormat:@"%@\"%@%@%@%@%@\"%@",
                              sqlprolog,
                              EuiE?sqlDictionary[@"EselectEuiE"]:sqlDictionary[@"EselectEP"],
                              ((sqlDictionary[@"Ejoin"])[0])[0],
                              sqlDictionary[@"Ewhere"],
                              [NSString stringWithFormat:
                               (sqlDictionary[@"EmatchEan"])[issuerUniversal],
                               AccessionNumberEqualString,
                               issuerArray[1],
                               issuerArray[2]
                               ],
                              @"",
                              sqlTwoPks
                             ],
                             mutableData)
               !=0) return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessionNumber db error. AN='%@' issuer='%@'",AccessionNumberEqualString,[issuerArray componentsJoinedByString:@"^"]];
         } break;

                     
         case issuerDivision:
         {
            if (execUTF8Bash(sqlcredentials,
                             [NSString stringWithFormat:@"%@\"%@%@%@%@%@\"%@",
                              sqlprolog,
                              EuiE?sqlDictionary[@"EselectEuiE"]:sqlDictionary[@"EselectEP"],
                              ((sqlDictionary[@"Ejoin"])[0])[0],
                              sqlDictionary[@"Ewhere"],
                              [NSString stringWithFormat:
                               (sqlDictionary[@"EmatchEan"])[issuerDivision],
                               AccessionNumberEqualString,
                               issuerArray[0],
                               issuerArray[1],
                               issuerArray[2]
                               ],
                              @"",
                              sqlTwoPks
                             ],
                             mutableData)
               !=0) return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessionNumber db error. AN='%@' issuer='%@'",AccessionNumberEqualString,[issuerArray componentsJoinedByString:@"^"]];
         } break;

         default:
            return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessionNumber issuer error '%@'",[issuerArray componentsJoinedByString:@"^"]];
            break;
      }
   }
   else
   {
      NSMutableArray *sqlJoins=[NSMutableArray array];
      NSMutableString *filters=[NSMutableString string];
      
      if (PatientIDLikeString)
#pragma mark 1 Pid
      {
         [sqlJoins addObjectsFromArray:(sqlDictionary[@"Ejoin"])[EcumulativeFilterPid]];
         switch (issuerArray.count) {
               
            case issuerNone:
               [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPid])[issuerNone],PatientIDLikeString];
               break;

            case issuerLocal:
               [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPid])[issuerLocal],PatientIDLikeString,issuerArray[0]];
               break;

            default:
               return [RSErrorResponse responseWithClientError:404 message:@"studyToken patientID issuer error '%@'",[issuerArray componentsJoinedByString:@"^"]];
               break;
         }
      }
      

      if (   patientFamilyLikeString
          || patientGivenLikeString
          || patientMiddleLikeString
          || patientPrefixLikeString
          || patientSuffixLikeString
          )
#pragma mark 2 Ppn
      {
          for (NSString *moreJoin in (sqlDictionary[@"Ejoin"])[EcumulativeFilterPpn])
          {
              if ([sqlJoins indexOfObject:moreJoin]==NSNotFound)[sqlJoins addObject:moreJoin];
          }
          NSString *pnFilterCompoundString=((sqlDictionary[@"Eand"])[EcumulativeFilterPpn])[pnFilterCompound];
         if (![pnFilterCompoundString isEqualToString:@""])
         {
            // DB with pn compound field
            NSString *regexp=nil;
            if (patientSuffixLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@^%@^%@^%@",
               patientFamilyLikeString?patientFamilyLikeString:@"",
               patientGivenLikeString?patientGivenLikeString:@"",
               patientMiddleLikeString?patientMiddleLikeString:@"",
               patientPrefixLikeString?patientPrefixLikeString:@"",
               patientSuffixLikeString];
            else if (patientPrefixLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@^%@^%@",
               patientFamilyLikeString?patientFamilyLikeString:@"",
               patientGivenLikeString?patientGivenLikeString:@"",
               patientMiddleLikeString?patientMiddleLikeString:@"",
               patientPrefixLikeString];
            else if (patientMiddleLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@^%@",
               patientFamilyLikeString?patientFamilyLikeString:@"",
               patientGivenLikeString?patientGivenLikeString:@"",
               patientMiddleLikeString];
            else if (patientGivenLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@",
               patientFamilyLikeString?patientFamilyLikeString:@"",
               patientGivenLikeString];
            else if (patientFamilyLikeString)
               regexp=[NSString stringWithString:patientFamilyLikeString];
            
            if (regexp) [filters appendFormat:pnFilterCompoundString,regexp];
         }
         else
         {
            //DB with pn detailed fields
            if (patientFamilyLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPpn])[pnFilterFamily],patientFamilyLikeString];
            if (patientGivenLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPpn])[pnFilterGiven],patientGivenLikeString];
            if (patientMiddleLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPpn])[pnFilterMiddle],patientMiddleLikeString];
            if (patientPrefixLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPpn])[pnFilterPrefix],patientPrefixLikeString];
            if (patientSuffixLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterPpn])[pnFilterSuffix],patientSuffixLikeString];
         }

      }
      
      
      
      if (StudyIDLikeString)
#pragma mark 3 Eid
      {
          for (NSString *moreJoin in (sqlDictionary[@"Ejoin"])[EcumulativeFilterEid])
          {
              if ([sqlJoins indexOfObject:moreJoin]==NSNotFound)[sqlJoins addObject:moreJoin];
          }
         [filters appendFormat:(sqlDictionary[@"Eand"])[EcumulativeFilterEid],StudyIDLikeString];
      }



      //(Eda)
      if (StudyDateArray)
#pragma mark 4 Eda
      {
         for (NSString *moreJoin in (sqlDictionary[@"Ejoin"])[EcumulativeFilterEda])
         {
             if ([sqlJoins indexOfObject:moreJoin]==NSNotFound)[sqlJoins addObject:moreJoin];
         }
          
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
         switch (StudyDateArray.count) {
            case dateMatchAny:
               break;
            case dateMatchOn:
            {
               [filters appendFormat:Eda[dateMatchOn],
                isoMatching?StudyDateArray[0]:[DICMTypes DAStringFromDAISOString:StudyDateArray[0]]
                ];
            } break;
            case dateMatchSince:
            {
               [filters appendFormat:Eda[dateMatchSince],
                isoMatching?StudyDateArray[0]:[DICMTypes DAStringFromDAISOString:StudyDateArray[0]]
                ];
            } break;
            case dateMatchUntil:
            {
               [filters appendFormat:Eda[dateMatchUntil],
                isoMatching?StudyDateArray[2]:[DICMTypes DAStringFromDAISOString:StudyDateArray[2]]
                ];

            } break;
            case dateMatchBetween:
            {
               [filters appendFormat:Eda[dateMatchBetween],
                isoMatching?StudyDateArray[0]:[DICMTypes DAStringFromDAISOString:StudyDateArray[0]],
                isoMatching?StudyDateArray[3]:[DICMTypes DAStringFromDAISOString:StudyDateArray[3]]
                ];

            } break;
         }
      }



#pragma mark 5 Elo
      if (StudyDescriptionRegexpString)
      {
         for (NSString *moreJoin in (sqlDictionary[@"Ejoin"])[EcumulativeFilterElo])
         {
             if ([sqlJoins indexOfObject:moreJoin]==NSNotFound)[sqlJoins addObject:moreJoin];
         }
         [filters appendFormat:(sqlDictionary[@"Eand"])[EcumulativeFilterElo],StudyDescriptionRegexpString];
      }
      
      
      if (   refInstitutionLikeString
          || refServiceLikeString
          || refUserLikeString
          || refIDLikeString
          || refIDTypeLikeString
          )
#pragma mark 6 Ref
      {
          NSLog(@"%d",EcumulativeFilterRef);
         for (NSString *moreJoin in (sqlDictionary[@"Ejoin"])[EcumulativeFilterRef])
         {
             if ([sqlJoins indexOfObject:moreJoin]==NSNotFound)[sqlJoins addObject:moreJoin];
         }
         NSString *pnFilterCompoundString=((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterCompound];
         if (![pnFilterCompoundString isEqualToString:@""])
         {
            // DB with pn compound field
            NSString *regexp=nil;
            if (refIDTypeLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@^%@^%@^%@",
               refInstitutionLikeString?refInstitutionLikeString:@"",
               refServiceLikeString?refServiceLikeString:@"",
               refUserLikeString?refUserLikeString:@"",
               refIDLikeString?refIDLikeString:@"",
               refIDTypeLikeString];
            else if (refIDLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@^%@^%@",
               refInstitutionLikeString?refInstitutionLikeString:@"",
               refServiceLikeString?refServiceLikeString:@"",
               refUserLikeString?refUserLikeString:@"",
               refIDLikeString];
            else if (refUserLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@^%@",
               refInstitutionLikeString?refInstitutionLikeString:@"",
               refServiceLikeString?refServiceLikeString:@"",
               refUserLikeString];
            else if (refServiceLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@",
               refInstitutionLikeString?refInstitutionLikeString:@"",
               refServiceLikeString];
            else if (refInstitutionLikeString)
               regexp=[NSString stringWithString:refInstitutionLikeString];
            
            if (regexp) [filters appendFormat:pnFilterCompoundString,regexp];
         }
         else
         {
            //DB with pn detailed fields
            if (refInstitutionLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterFamily],refInstitutionLikeString];
            if (refServiceLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterGiven],refServiceLikeString];
            if (refUserLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterGiven],refUserLikeString];
            if (refIDLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterGiven],refIDLikeString];
            if (refIDTypeLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRef])[pnFilterGiven],refIDTypeLikeString];
         }
      }
      
      
      if (   readInstitutionSqlLikeString
          || readServiceSqlLikeString
          || readUserSqlLikeString
          || readIDSqlLikeString
          || readIDTypeSqlLikeString
          )
#pragma mark 7 Read
      {
         for (NSString *moreJoin in (sqlDictionary[@"Ejoin"])[EcumulativeFilterRead])
         {
             if ([sqlJoins indexOfObject:moreJoin]==NSNotFound)[sqlJoins addObject:moreJoin];
         }
         NSString *pnFilterCompoundString=((sqlDictionary[@"Eand"])[EcumulativeFilterRead])[pnFilterCompound];
         if (![pnFilterCompoundString isEqualToString:@""])
         {
            // DB with pn compound field
            NSString *regexp=nil;
            if (refIDTypeLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@^%@^%@^%@",
               refInstitutionLikeString?refInstitutionLikeString:@"",
               refServiceLikeString?refServiceLikeString:@"",
               refUserLikeString?refUserLikeString:@"",
               refIDLikeString?refIDLikeString:@"",
               refIDTypeLikeString];
            else if (refIDLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@^%@^%@",
               refInstitutionLikeString?refInstitutionLikeString:@"",
               refServiceLikeString?refServiceLikeString:@"",
               refUserLikeString?refUserLikeString:@"",
               refIDLikeString];
            else if (refUserLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@^%@",
               refInstitutionLikeString?refInstitutionLikeString:@"",
               refServiceLikeString?refServiceLikeString:@"",
               refUserLikeString];
            else if (refServiceLikeString)
               regexp=[NSString stringWithFormat:@"%@^%@",
               refInstitutionLikeString?refInstitutionLikeString:@"",
               refServiceLikeString];
            else if (refInstitutionLikeString)
               regexp=[NSString stringWithString:refInstitutionLikeString];
            
            if (regexp) [filters appendFormat:pnFilterCompoundString,regexp];
         }
         else
         {
            //DB with pn detailed fields
            if (refInstitutionLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRead])[pnFilterFamily],refInstitutionLikeString];
            if (refServiceLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRead])[pnFilterGiven],refServiceLikeString];
            if (refUserLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRead])[pnFilterGiven],refUserLikeString];
            if (refIDLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRead])[pnFilterGiven],refIDLikeString];
            if (refIDTypeLikeString) [filters appendFormat:((sqlDictionary[@"Eand"])[EcumulativeFilterRead])[pnFilterGiven],refIDTypeLikeString];
         }
      }
      

      if (SOPClassInStudyRegexpString)
#pragma mark 8 Esc (SOPClassesInStudy)
         {
            for (NSString *moreJoin in (sqlDictionary[@"Ejoin"])[EcumulativeFilterEsc])
            {
                if ([sqlJoins indexOfObject:moreJoin]==NSNotFound)[sqlJoins addObject:moreJoin];
            }
            [filters appendFormat:(sqlDictionary[@"Eand"])[EcumulativeFilterEsc],SOPClassInStudyRegexpString];
         }

      
      
      if (ModalityInStudyRegexpString)
#pragma mark 9 (optional) ModalitiesInStudy Emo
         {
            for (NSString *moreJoin in (sqlDictionary[@"Ejoin"])[EcumulativeFilterEmo])
            {
                if ([sqlJoins indexOfObject:moreJoin]==NSNotFound)[sqlJoins addObject:moreJoin];
            }
            [filters appendFormat:(sqlDictionary[@"Eand"])[EcumulativeFilterEmo],SOPClassInStudyRegexpString];
         }
            
       //six parts: prolog,select,where,and,limit&order,format
       if (execUTF8Bash(
           sqlcredentials,
           [NSString stringWithFormat:@"%@\"%@%@%@%@%@\"%@",
            sqlprolog,
            EuiE?sqlDictionary[@"EselectEuiE"]:sqlDictionary[@"EselectEP"],
            [sqlJoins componentsJoinedByString:@""],
            sqlDictionary[@"Ewhere"],
            filters,
            @"",
            sqlTwoPks
           ],
           mutableData)
           !=0) return [RSErrorResponse responseWithClientError:404 message:@"studyToken StudyInstanceUID %@ db error",StudyInstanceUIDRegexpString];

      
    }

    if ([mutableData length]==0)
    {
      LOG_VERBOSE(@"studyToken empty response");
      return nil;
    }
    for (NSString *pkdotpk in [[[NSString alloc]initWithData:mutableData encoding:NSUTF8StringEncoding]componentsSeparatedByString:@"/"])
    {
        if (pkdotpk.length) [EPDict setObject:[pkdotpk pathExtension] forKey:[pkdotpk stringByDeletingPathExtension]];
    }
    //record terminated by /

    return nil;
}


/*
 applied at series level in each of the access type to restrict returned series.
 The function returns the SOPClass of series to be included
 */
NSString * SOPCLassOfReturnableSeries(
 NSDictionary        * sqlcredentials,
 NSString            * sqlIci4S,
 NSString            * sqlprolog,
 NSArray             * SProperties,
 NSRegularExpression * SeriesInstanceUIDRegex,
 NSRegularExpression * SeriesNumberRegex,
 NSRegularExpression * SeriesDescriptionRegex,
 NSRegularExpression * ModalityRegex,
 NSRegularExpression * SOPClassRegex,
 NSRegularExpression * SOPClassOffRegex
)
{
   NSMutableData *SOPClassData=[NSMutableData dataWithCapacity:64];
   if (execUTF8Bash(sqlcredentials,
                     [NSString stringWithFormat:
                      sqlIci4S,
                      sqlprolog,
                      SProperties[0],
                      @"limit 1",
                      @"| awk -F\\t ' BEGIN{ ORS=\"\"; OFS=\"\";}{print $1}'"
                      ],
                     SOPClassData)
       !=0)
   {
      LOG_ERROR(@"studyToken SOPClassData");
      return nil;
   }
   if (!SOPClassData.length) return nil;
   NSString *SOPClassString=[[NSString alloc] initWithData:SOPClassData  encoding:NSUTF8StringEncoding];
   /*
    //dicom cda
   if ([(IPropertiesFirstRecord[0])[3] isEqualToString:@"1.2.840.10008.5.1.4.1.1.104.2"]) continue;
   //SR
   if ([(IPropertiesFirstRecord[0])[3] hasPrefix:@"1.2.840.10008.5.1.4.1.1.88"])continue;
    
    //replaced by SOPClassOff
   */

   if (
          (    SeriesInstanceUIDRegex
            &&![SeriesInstanceUIDRegex
                numberOfMatchesInString:SProperties[1]
                options:0
                range:NSMakeRange(0, [SProperties[1] length])
                ]
            )
       ||  (    SeriesNumberRegex
            &&![SeriesNumberRegex
                numberOfMatchesInString:SProperties[3]
                options:0
                range:NSMakeRange(0, [SProperties[3] length])
                ]
            )
       ||  (    SeriesDescriptionRegex
            &&![SeriesDescriptionRegex
                numberOfMatchesInString:SProperties[2]
                options:0
                range:NSMakeRange(0, [SProperties[2] length])
                ]
            )
       ||  (    ModalityRegex
            &&![ModalityRegex
                numberOfMatchesInString:SProperties[4]
                options:0
                range:NSMakeRange(0, [SProperties[4] length])
                ]
            )
       ||  (    SOPClassRegex
            &&![SOPClassRegex
                numberOfMatchesInString:SOPClassString
                options:0
                range:NSMakeRange(0, SOPClassString.length)
                ]
            )
       ||  (    SOPClassOffRegex
            && [SOPClassOffRegex
                  numberOfMatchesInString:SOPClassString
                  options:0
                  range:NSMakeRange(0, SOPClassString.length)
                  ]
            )

       ) return nil;
    return SOPClassString;
};


#pragma mark -
@implementation DRS (studyToken)

-(void)addPostAndGetStudyTokenHandler
{
   [self
    addHandler:@"POST"
    regex:[NSRegularExpression regularExpressionWithPattern:@"^/(studyToken|osirix.dcmURLs|weasis.xml|dicom.zip|iso.dicom.zip|deflate.dicom.zip|deflate.iso.dicom.zip|max.deflate.iso.dicom.zip|zip64.iso.dicom.zip|wadors.dicom|datatablesseries.json|datatablespatient.json|cornerstone.json)$" options:0 error:NULL]
    processBlock:^(RSRequest* request,RSCompletionBlock completionBlock)
    {
       completionBlock(^RSResponse* (RSRequest* request) {return [DRS studyToken:request];}(request));
    }
   ];

   [self
    addHandler:@"GET"
    regex:[NSRegularExpression regularExpressionWithPattern:@"^/(studyToken|osirix.dcmURLs|weasis.xml|dicom.zip|iso.dicom.zip|deflate.dicom.zip|deflate.iso.dicom.zip|max.deflate.iso.dicom.zip|zip64.iso.dicom.zip|wadors.dicom|datatablesseries.json|datatablespatient.json|cornerstone.json)$" options:0 error:NULL]
    processBlock:^(RSRequest* request,RSCompletionBlock completionBlock)
    {
       completionBlock(^RSResponse* (RSRequest* request) {return [DRS studyToken:request];}(request));
    }
   ];
}


+(RSResponse*)studyToken:(RSRequest*)request
{
   NSMutableArray *names=[NSMutableArray array];
   NSMutableArray *values=[NSMutableArray array];
   NSString *errorString=parseRequestParams(request, names, values);
   if (errorString) return [RSErrorResponse responseWithClientError:404 message:@"%@",errorString];
   return [DRS
           studyTokenSocket:request.socketNumber
           requestURL:request.URL
           requestPath:request.path
           names:names
           values:values
           acceptsGzip:request.acceptsGzipContentEncoding
           ];
}

+(RSResponse*)studyTokenSocket:(unsigned short)socket
                    requestURL:(NSURL*)requestURL
                   requestPath:(NSString*)requestPath
                         names:(NSArray*)names
                        values:(NSArray*)values
                   acceptsGzip:(BOOL)acceptsGzip
{
   NSFileManager *defaultManager=[NSFileManager defaultManager];
   NSMutableDictionary *requestDict=[NSMutableDictionary dictionary];
   NSInteger tokenIndex=[names indexOfObject:@"token"];
   if (tokenIndex!=NSNotFound) [requestDict setObject:values[tokenIndex] forKey:@"tokenString"];

   
   NSMutableString *canonicalQuery=[NSMutableString stringWithString:@"{"];
#pragma mark query context
   
   NSInteger proxyURIIndex=[names indexOfObject:@"proxyURI"];
    if (proxyURIIndex!=NSNotFound)
    {
       [canonicalQuery appendFormat:@"\"proxyURI\":\"%@\",",values[proxyURIIndex]];
       [requestDict setObject:values[proxyURIIndex] forKey:@"proxyURIString"];
    }
   

   NSInteger sessionIndex=[names indexOfObject:@"session"];
   if (sessionIndex!=NSNotFound)
   {
      //[canonicalQuery appendFormat:@"\"session\":\"%@\",",values[sessionIndex]];
      [requestDict setObject:values[sessionIndex] forKey:@"sessionString"];
   }


#pragma mark institution
#pragma mark TODO revise oid vs orgaet.deviceaet
   /*
    oid => wado direct from html5dicom to pacs
    orgaet.deviceaet => wado to httpdicom proxy
    */
   
   NSMutableArray *lanArray=[NSMutableArray array];
   NSMutableArray *wanArray=[NSMutableArray array];
   
   NSInteger orgIndex=[names indexOfObject:@"institution"];
   [requestDict setObject:values[orgIndex] forKey:@"institutionString"];
   if (orgIndex==NSNotFound)
   {
      orgIndex=[names indexOfObject:@"lanPacs"];
      if (orgIndex!=NSNotFound) [lanArray addObjectsFromArray:[values[orgIndex] componentsSeparatedByString:@"|"]];
      orgIndex=[names indexOfObject:@"wanPacs"];
      if (orgIndex!=NSNotFound) [wanArray addObjectsFromArray:[values[orgIndex] componentsSeparatedByString:@"|"]];
   }
   else
   {
      NSArray *orgArray=[values[orgIndex] componentsSeparatedByString:@"|"];
      for (NSInteger i=[orgArray count]-1;i>=0;i--)
      {
         if ([DRS.wan indexOfObject:orgArray[i]]!=NSNotFound)
         {
            [wanArray addObject:orgArray[i]];
            LOG_DEBUG(@"studyToken institution wan %@",orgArray[i]);
         }
         else if ([DRS.dev indexOfObject:orgArray[i]]!=NSNotFound)
         {
            [lanArray addObject:orgArray[i]];
            LOG_DEBUG(@"studyToken institution lan %@",orgArray[i]);
         }
         else if ([DRS.lan indexOfObject:orgArray[i]]!=NSNotFound)
         {
            //find all dev of local custodian
            if (DRS.oidsaeis[orgArray[i]])
            {
               [lanArray addObjectsFromArray:DRS.oidsaeis[orgArray[i]]];
               LOG_VERBOSE(@"studyToken institution for lan %@:\r\n%@",orgArray[i],[DRS.oidsaeis[orgArray[i]]description]);
            }
            else
            {
               [lanArray addObjectsFromArray:DRS.titlestitlesaets[orgArray[i]]];
               LOG_VERBOSE(@"studyToken institution for lan %@:\r\n%@",orgArray[i],[DRS.titlestitlesaets[orgArray[i]]description]);
            }
         }
         else LOG_WARNING(@"studyToken institution '%@' not registered",orgArray[i]);
      }
   }
   if (![lanArray count] && ![wanArray count]) return [RSErrorResponse responseWithClientError:404 message:@"no valid pacs in the request"];

//   if ([lanArray count]) [canonicalQuery appendFormat:@"\"lanArray\":\"%@\",",[[lanArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]componentsJoinedByString:@"|"]];

//   if ([wanArray count]) [canonicalQuery appendFormat:@"\"wanArray\":\"%@\",",[[lanArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]componentsJoinedByString:@"|"]];


#pragma mark StudyInstanceUID
    NSString *StudyInstanceUIDRegexpString=nil;
    NSInteger StudyInstanceUIDIndex=[names indexOfObject:@"StudyInstanceUID"];
    if (StudyInstanceUIDIndex!=NSNotFound)
    {
       if ([values[StudyInstanceUIDIndex] length])
       {
          if ([DICMTypes isUIPipeListString:values[StudyInstanceUIDIndex]])
          {
             StudyInstanceUIDRegexpString=[values[StudyInstanceUIDIndex] regexQuoteEscapedString];
             [requestDict setObject:StudyInstanceUIDRegexpString forKey:@"StudyInstanceUIDRegexpString"];
             [canonicalQuery appendFormat:@"\"StudyInstanceUID\":\"%@\",",StudyInstanceUIDRegexpString];
          }
          else return [RSErrorResponse responseWithClientError:404 message:@"studyToken param StudyInstanceUID: %@",values[StudyInstanceUIDIndex]];
       }
    }

#pragma mark AccessionNumber
    NSString *AccessionNumberEqualString=nil;
    NSInteger AccessionNumberIndex=[names indexOfObject:@"AccessionNumber"];
    if (AccessionNumberIndex!=NSNotFound)
    {
       AccessionNumberEqualString=[values[AccessionNumberIndex] sqlEqualEscapedString];
       [requestDict setObject:AccessionNumberEqualString forKey:@"AccessionNumberEqualString"];
       [canonicalQuery appendFormat:@"\"AccessionNumber\":\"%@\",",AccessionNumberEqualString];
    }

   
#pragma mark 1. PatientID (Pid)
    NSString *PatientIDLikeString=nil;
    NSInteger PatientIDIndex=[names indexOfObject:@"PatientID"];
    if (PatientIDIndex!=NSNotFound)
    {
       PatientIDLikeString=[values[PatientIDIndex] sqlLikeEscapedString];
       [requestDict setObject:PatientIDLikeString forKey:@"PatientIDLikeString"];
       [canonicalQuery appendFormat:@"\"PatientID\":\"%@\",",PatientIDLikeString];
    }

#pragma mark 2. PatientName (Ppn)
   
   BOOL patientNamePart=false;
   
   NSString *patientFamilyLikeString=nil;
   NSInteger patientFamilyIndex=[names indexOfObject:@"patientFamily"];
   if (patientFamilyIndex!=NSNotFound)
   {
      patientNamePart=true;
      patientFamilyLikeString=[values[patientFamilyIndex] regexQuoteEscapedString];
      [requestDict setObject:patientFamilyLikeString forKey:@"patientFamilyLikeString"];
      [canonicalQuery appendFormat:@"\"patientFamily\":\"%@\",",patientFamilyLikeString];
   }

   NSString *patientGivenLikeString=nil;
   NSInteger patientGivenIndex=[names indexOfObject:@"patientGiven"];
   if (patientGivenIndex!=NSNotFound)
   {
      patientNamePart=true;
      patientGivenLikeString=[values[patientGivenIndex] regexQuoteEscapedString];
      [requestDict setObject:patientGivenLikeString forKey:@"patientGivenLikeString"];
      [canonicalQuery appendFormat:@"\"patientGiven\":\"%@\",",patientGivenLikeString];
   }

   NSString *patientMiddleLikeString=nil;
   NSInteger patientMiddleIndex=[names indexOfObject:@"patientMiddle"];
   if (patientMiddleIndex!=NSNotFound)
   {
      patientNamePart=true;
      patientMiddleLikeString=[values[patientMiddleIndex] regexQuoteEscapedString];
      [requestDict setObject:patientMiddleLikeString forKey:@"patientMiddleLikeString"];
      [canonicalQuery appendFormat:@"\"patientMiddle\":\"%@\",",patientMiddleLikeString];
   }

   NSString *patientPrefixLikeString=nil;
   NSInteger patientPrefixIndex=[names indexOfObject:@"patientPrefix"];
   if (patientPrefixIndex!=NSNotFound)
   {
      patientNamePart=true;
      patientPrefixLikeString=[values[patientPrefixIndex] regexQuoteEscapedString];
      [requestDict setObject:patientPrefixLikeString forKey:@"patientPrefixLikeString"];
      [canonicalQuery appendFormat:@"\"patientPrefix\":\"%@\",",patientPrefixLikeString];
   }

   NSString *patientSuffixLikeString=nil;
   NSInteger patientSuffixIndex=[names indexOfObject:@"patientSuffix"];
   if (patientSuffixIndex!=NSNotFound)
   {
      patientNamePart=true;
      patientSuffixLikeString=[values[patientSuffixIndex] regexQuoteEscapedString];
      [requestDict setObject:patientSuffixLikeString forKey:@"patientSuffixLikeString"];
      [canonicalQuery appendFormat:@"\"patientSuffix\":\"%@\",",patientSuffixLikeString];
   }

   if (!patientNamePart)
   {
      NSInteger PatientNameIndex=[names indexOfObject:@"PatientName"];
      if (PatientNameIndex!=NSNotFound)
      {
         NSString *PatientNameRegexString=[values[PatientNameIndex] regexQuoteEscapedString];
         NSArray *PatientNameParts=[PatientNameRegexString componentsSeparatedByString:@"^"];
         if (PatientNameParts.count>0)
         {
            patientFamilyLikeString=PatientNameParts[0];
            [requestDict setObject:patientFamilyLikeString forKey:@"patientFamilyLikeString"];
            [canonicalQuery appendFormat:@"\"patientFamily\":\"%@\",",patientFamilyLikeString];
         }
         if (PatientNameParts.count>1)
         {
            patientGivenLikeString=PatientNameParts[1];
            [requestDict setObject:patientGivenLikeString forKey:@"patientGivenLikeString"];
            [canonicalQuery appendFormat:@"\"patientGiven\":\"%@\",",patientGivenLikeString];
         }
         if (PatientNameParts.count>2)
         {
            patientMiddleLikeString=PatientNameParts[2];
            [requestDict setObject:patientMiddleLikeString forKey:@"patientMiddleLikeString"];
            [canonicalQuery appendFormat:@"\"patientMiddle\":\"%@\",",patientMiddleLikeString];
         }
         if (PatientNameParts.count>3)
         {
            patientPrefixLikeString=PatientNameParts[3];
            [requestDict setObject:patientPrefixLikeString forKey:@"patientPrefixLikeString"];
            [canonicalQuery appendFormat:@"\"patientPrefix\":\"%@\",",patientPrefixLikeString];
         }
         if (PatientNameParts.count>4)
         {
            patientSuffixLikeString=PatientNameParts[4];
            [requestDict setObject:patientSuffixLikeString forKey:@"patientSuffixLikeString"];
            [canonicalQuery appendFormat:@"\"patientSuffix\":\"%@\",",patientSuffixLikeString];
         }
      }
   }
    
#pragma mark 3. StudyID (Eid)
    
    NSString *StudyIDLikeString=nil;
    NSInteger StudyIDIndex=[names indexOfObject:@"StudyID"];
    if (StudyIDIndex!=NSNotFound)
    {
       StudyIDLikeString=[values[StudyIDIndex] sqlLikeEscapedString];
       [requestDict setObject:StudyIDLikeString forKey:@"StudyIDLikeString"];
       [canonicalQuery appendFormat:@"\"StudyID\":\"%@\",",StudyIDLikeString];
    }

    
#pragma mark 4. StudyDate (Eda)
    
    NSArray *StudyDateArray=nil;
    NSInteger StudyDateIndex=[names indexOfObject:@"StudyDate"];
    if (StudyDateIndex!=NSNotFound)
    {
       NSString *StudyDateString=values[StudyDateIndex];
       [canonicalQuery appendFormat:@"\"StudyDate\":\"%@\",",StudyDateString];
       if ([StudyDateString length])
       {
          if (![DICMTypes isDA0or1PipeString:StudyDateString]) return [RSErrorResponse responseWithClientError:404 message:@"studyToken bad StudyDate %@",StudyDateString];
          else
          {
             NSArray *StudyDatePipeComponents=[StudyDateString componentsSeparatedByString:@"|"];
             
             if (StudyDatePipeComponents.count ==1 )
             {
                 StudyDateArray=@[StudyDatePipeComponents[0]];
             }
             else
             {
               
                 if(![StudyDateArray[1] length])
                 {
                     //aaaa-mm-dd|  =since
                     StudyDateArray=@[StudyDatePipeComponents[0],@""];
                 }
                 else if(![StudyDateArray[0] length])
                 {
                     //|aaaa-mm-dd  =until
                     StudyDateArray=@[@"",@"",StudyDatePipeComponents[1]];
                 }
                 else
                 {
                     //aaaa-mm-dd|aaaa-mm-dd
                     //[aaaa-mm-dd][][][aaaa-mm-dd] = between
                StudyDateArray=@[StudyDatePipeComponents[0],@"",@"",StudyDatePipeComponents[1]];
                 }
             }
             [requestDict setObject:StudyDateArray forKey:@"StudyDateArray"];
          }
       }
    }

 
#pragma mark 5. StudyDescription (Elo)
    
    NSString *StudyDescriptionRegexpString=nil;
    NSInteger StudyDescriptionIndex=[names indexOfObject:@"StudyDescription"];
    if (StudyDescriptionIndex!=NSNotFound)
    {
       StudyDescriptionRegexpString=[values[StudyDescriptionIndex] regexQuoteEscapedString];
       [requestDict setObject:StudyDescriptionRegexpString forKey:@"StudyDescriptionRegexpString"];
       [canonicalQuery appendFormat:@"\"StudyDescription\":\"%@\",",StudyDescriptionRegexpString];
    }

    
#pragma mark 6. ref

    BOOL refPart=false;

    NSString *refInstitutionLikeString=nil;
    NSInteger refInstitutionIndex=[names indexOfObject:@"refInstitution"];
    if (refInstitutionIndex!=NSNotFound)
    {
       refPart=true;
       refInstitutionLikeString=[values[refInstitutionIndex] regexQuoteEscapedString];
       [requestDict setObject:refInstitutionLikeString forKey:@"refInstitutionLikeString"];
       [canonicalQuery appendFormat:@"\"refInstitution\":\"%@\",",refInstitutionLikeString];
    }

    NSString *refServiceLikeString=nil;
    NSInteger refServiceIndex=[names indexOfObject:@"refService"];
    if (refServiceIndex!=NSNotFound)
    {
       refPart=true;
       refServiceLikeString=[values[refServiceIndex] regexQuoteEscapedString];
       [requestDict setObject:refServiceLikeString forKey:@"refServiceLikeString"];
       [canonicalQuery appendFormat:@"\"refService\":\"%@\",",refServiceLikeString];
    }

    NSString *refUserLikeString=nil;
    NSInteger refUserIndex=[names indexOfObject:@"refUser"];
    if (refUserIndex!=NSNotFound)
    {
       refPart=true;
       refUserLikeString=[values[refUserIndex] regexQuoteEscapedString];
       [requestDict setObject:refUserLikeString forKey:@"refUserLikeString"];
       [canonicalQuery appendFormat:@"\"refUser\":\"%@\",",refUserLikeString];
    }

    NSString *refIDLikeString=nil;
    NSInteger refIDIndex=[names indexOfObject:@"refID"];
    if (refIDIndex!=NSNotFound)
    {
       refPart=true;
       refIDLikeString=[values[refIDIndex] regexQuoteEscapedString];
       [requestDict setObject:refIDLikeString forKey:@"refIDLikeString"];
       [canonicalQuery appendFormat:@"\"refID\":\"%@\",",refIDLikeString];
    }

    NSString *refIDTypeLikeString=nil;
    NSInteger refIDTypeIndex=[names indexOfObject:@"refIDType"];
    if (refIDTypeIndex!=NSNotFound)
    {
       refPart=true;
       refIDTypeLikeString=[values[refIDTypeIndex] regexQuoteEscapedString];
       [requestDict setObject:refIDTypeLikeString forKey:@"refIDTypeLikeString"];
       [canonicalQuery appendFormat:@"\"refIDType\":\"%@\",",refIDTypeLikeString];
    }
   
   if (!refPart)
   {
      NSInteger refIndex=[names indexOfObject:@"ref"];
      if (refIndex!=NSNotFound)
      {
         NSString *refRegexString=[values[refIndex] regexQuoteEscapedString];
         NSArray *refParts=[refRegexString componentsSeparatedByString:@"^"];
         if (refParts.count>0)
         {
            refInstitutionLikeString=refParts[0];
            [requestDict setObject:refInstitutionLikeString forKey:@"refInstitutionLikeString"];
            [canonicalQuery appendFormat:@"\"refInstitution\":\"%@\",",refInstitutionLikeString];
         }
         if (refParts.count>1)
         {
            refServiceLikeString=refParts[1];
            [requestDict setObject:refServiceLikeString forKey:@"refServiceLikeString"];
            [canonicalQuery appendFormat:@"\"refService\":\"%@\",",refServiceLikeString];
         }
         if (refParts.count>2)
         {
            refUserLikeString=refParts[2];
            [requestDict setObject:refUserLikeString forKey:@"refUserLikeString"];
            [canonicalQuery appendFormat:@"\"refUser\":\"%@\",",refUserLikeString];
         }
         if (refParts.count>3)
         {
            refIDLikeString=refParts[3];
            [requestDict setObject:refIDLikeString forKey:@"refIDLikeString"];
            [canonicalQuery appendFormat:@"\"refID\":\"%@\",",refIDLikeString];
         }
         if (refParts.count>4)
         {
            refIDTypeLikeString=refParts[4];
            [requestDict setObject:refIDTypeLikeString forKey:@"refIDTypeLikeString"];
            [canonicalQuery appendFormat:@"\"patientSuffix\":\"%@\",",refIDTypeLikeString];
         }
      }
   }


#pragma mark 7. read
    
    BOOL readPart=false;

    NSString *readInstitutionLikeString=nil;
    NSInteger readInstitutionIndex=[names indexOfObject:@"readInstitution"];
    if (readInstitutionIndex!=NSNotFound)
    {
       readPart=true;
       readInstitutionLikeString=[values[readInstitutionIndex] regexQuoteEscapedString];
       [requestDict setObject:readInstitutionLikeString forKey:@"readInstitutionLikeString"];
       [canonicalQuery appendFormat:@"\"readInstitution\":\"%@\",",readInstitutionLikeString];
    }

    NSString *readServiceLikeString=nil;
    NSInteger readServiceIndex=[names indexOfObject:@"readService"];
    if (readServiceIndex!=NSNotFound)
    {
       readPart=true;
       readServiceLikeString=[values[readServiceIndex] regexQuoteEscapedString];
       [requestDict setObject:readServiceLikeString forKey:@"readServiceLikeString"];
       [canonicalQuery appendFormat:@"\"readService\":\"%@\",",readServiceLikeString];
    }

    NSString *readUserLikeString=nil;
    NSInteger readUserIndex=[names indexOfObject:@"readUser"];
    if (readUserIndex!=NSNotFound)
    {
       readPart=true;
       readUserLikeString=[values[readUserIndex] regexQuoteEscapedString];
       [requestDict setObject:readUserLikeString forKey:@"readUserLikeString"];
       [canonicalQuery appendFormat:@"\"readUser\":\"%@\",",readUserLikeString];
    }

    NSString *readIDLikeString=nil;
    NSInteger readIDIndex=[names indexOfObject:@"readID"];
    if (readIDIndex!=NSNotFound)
    {
       readPart=true;
       readIDLikeString=[values[readIDIndex] regexQuoteEscapedString];
       [requestDict setObject:readIDLikeString forKey:@"readIDLikeString"];
       [canonicalQuery appendFormat:@"\"readID\":\"%@\",",readIDLikeString];
    }
    
    NSString *readIDTypeLikeString=nil;
    NSInteger readIDTypeIndex=[names indexOfObject:@"readIDType"];
    if (readIDTypeIndex!=NSNotFound)
    {
       readPart=true;
       readIDTypeLikeString=[values[readIDTypeIndex] regexQuoteEscapedString];
       [requestDict setObject:readIDTypeLikeString forKey:@"readIDTypeLikeString"];
       [canonicalQuery appendFormat:@"\"readIDType\":\"%@\",",readIDTypeLikeString];
    }

   if (!readPart)
   {
      NSInteger readIndex=[names indexOfObject:@"read"];
      if (readIndex!=NSNotFound)
      {
         NSString *readRegexString=[values[readIndex] regexQuoteEscapedString];
         NSArray *readParts=[readRegexString componentsSeparatedByString:@"^"];
         if (readParts.count>0)
         {
            readInstitutionLikeString=readParts[0];
            [requestDict setObject:readInstitutionLikeString forKey:@"readInstitutionLikeString"];
            [canonicalQuery appendFormat:@"\"readInstitution\":\"%@\",",readInstitutionLikeString];
         }
         if (readParts.count>1)
         {
            readServiceLikeString=readParts[1];
            [requestDict setObject:readServiceLikeString forKey:@"readServiceLikeString"];
            [canonicalQuery appendFormat:@"\"readService\":\"%@\",",readServiceLikeString];
         }
         if (readParts.count>2)
         {
            readUserLikeString=readParts[2];
            [requestDict setObject:readUserLikeString forKey:@"readUserLikeString"];
            [canonicalQuery appendFormat:@"\"readUser\":\"%@\",",readUserLikeString];
         }
         if (readParts.count>3)
         {
            readIDLikeString=readParts[3];
            [requestDict setObject:readIDLikeString forKey:@"readIDLikeString"];
            [canonicalQuery appendFormat:@"\"readID\":\"%@\",",readIDLikeString];
         }
         if (readParts.count>4)
         {
            readIDTypeLikeString=readParts[4];
            [requestDict setObject:readIDTypeLikeString forKey:@"readIDTypeLikeString"];
            [canonicalQuery appendFormat:@"\"patientSuffix\":\"%@\",",readIDTypeLikeString];
         }
      }
   }

    
#pragma mark 8. SOPClassInStudyString
    
   NSInteger SOPClassInStudyIndex=[names indexOfObject:@"SOPClassInStudy"];
   if ((SOPClassInStudyIndex!=NSNotFound) && [DICMTypes isSingleUIString:values[SOPClassInStudyIndex]])
   {
           [requestDict setObject:values[SOPClassInStudyIndex] forKey:@"SOPClassInStudyRegexpString"];
           [canonicalQuery appendFormat:@"\"SOPClassInStudy\":\"%@\",",values[SOPClassInStudyIndex]];
   }

   
#pragma mark 9. ModalityInStudyString
   NSInteger ModalityInStudyIndex=[names indexOfObject:@"ModalityInStudy"];
   if ((ModalityInStudyIndex!=NSNotFound) && [DICMTypes isSingleCSString:values[ModalityInStudyIndex]])
   {
      [requestDict setObject:values[ModalityInStudyIndex] forKey:@"ModalityInStudyRegexpString"];
      [canonicalQuery appendFormat:@"\"ModalityInStudy\":\"%@\",",values[ModalityInStudyIndex]];
   }

#pragma mark issuer
    
   NSArray *issuerArray=nil;
   NSInteger issuerIndex=[names indexOfObject:@"issuer"];
   if (issuerIndex!=NSNotFound)
   {
      [canonicalQuery appendFormat:@"\"issuer\":\"%@\",",[values[issuerIndex] sqlEqualEscapedString]];
      NSArray *array=[[values[issuerIndex] sqlEqualEscapedString] componentsSeparatedByString:@"^"];
      switch (array.count) {
         case 1:
         {
            if ([array[0] length]==0) issuerArray=@[];
            else if ([array[0] length]<17) issuerArray=[NSArray arrayWithArray:array];
            else return [RSErrorResponse responseWithClientError:404 message:@"studyToken bad param issuer: '%@'",values[issuerIndex]];
         } break;
         case 3:
         {
            if ([array[1] length] && ([@[@"DNS",@"EUI64",@"ISO",@"URI",@"UUID",@"X400",@"X500"] indexOfObject:array[2]]!=NSNotFound))
            {
               if (![array[0] length]) issuerArray=[NSArray arrayWithArray:array];
               else if ([array[0] length]<17) issuerArray=[array arrayByAddingObject:array[0]];
               else return [RSErrorResponse responseWithClientError:404 message:@"studyToken bad param issuer: '%@'",values[issuerIndex]];
            }
         } break;
         default:
         {
            return [RSErrorResponse responseWithClientError:404 message:@"studyToken bad param issuer: '%@'",values[issuerIndex]];
         } break;
      }
      [requestDict setObject:issuerArray forKey:@"issuerArray"];
   }


#pragma mark series restrictions

// SeriesInstanceUID
   NSInteger SeriesInstanceUIDIndex=[names indexOfObject:@"SeriesInstanceUID"];
   if (SeriesInstanceUIDIndex!=NSNotFound)
   {
      [requestDict setObject:values[SeriesInstanceUIDIndex] forKey:@"SeriesInstanceUIDRegexString"];
      [canonicalQuery appendFormat:@"\"SeriesInstanceUID\":\"%@\",",values[SeriesInstanceUIDIndex]];
   }
   
// SeriesNumber
   NSInteger SeriesNumberIndex=[names indexOfObject:@"SeriesNumber"];
   if (SeriesNumberIndex!=NSNotFound)
   {
      [requestDict setObject:values[SeriesNumberIndex] forKey:@"SeriesNumberRegexString"];
      [canonicalQuery appendFormat:@"\"SeriesNumber\":\"%@\",",values[SeriesNumberIndex]];
   }

// SeriesDescription@StationName@Department@Institution
   NSInteger SeriesDescriptionIndex=[names indexOfObject:@"SeriesDescription"];
   if (SeriesDescriptionIndex!=NSNotFound)
   {
      [requestDict setObject:values[SeriesDescriptionIndex] forKey:@"SeriesDescriptionRegexString"];
      [canonicalQuery appendFormat:@"\"SeriesDescription\":\"%@\",",values[SeriesDescriptionIndex]];
   }
   
// Modality
   NSInteger ModalityIndex=[names indexOfObject:@"Modality"];
   if (ModalityIndex!=NSNotFound)
   {
      [requestDict setObject:values[ModalityIndex] forKey:@"ModalityRegexString"];
      [canonicalQuery appendFormat:@"\"Modality\":\"%@\",",values[ModalityIndex]];
   }

// SOPClass
   NSInteger SOPClassIndex=[names indexOfObject:@"SOPClass"];
   if (SOPClassIndex!=NSNotFound)
   {
      [requestDict setObject:values[SOPClassIndex] forKey:@"SOPClassRegexString"];
      [canonicalQuery appendFormat:@"\"SOPClass\":\"%@\",",values[SOPClassIndex]];
   }
   
// SOPClassOff
   NSInteger SOPClassOffIndex=[names indexOfObject:@"SOPClassOff"];
   if (SOPClassOffIndex!=NSNotFound)
   {
      [requestDict setObject:values[SOPClassOffIndex] forKey:@"SOPClassOffRegexString"];
      [canonicalQuery appendFormat:@"\"SOPClassOff\":\"%@\",",values[SOPClassOffIndex]];
   }

//hasRestriction?
   BOOL hasRestriction=
      requestDict[@"SeriesInstanceUIDRegexString"]
   || requestDict[@"SeriesNumberRegexString"]
   || requestDict[@"SeriesDescriptionRegexString"]
   || requestDict[@"ModalityRegexString"]
   || requestDict[@"SOPClassRegexString"]
   || requestDict[@"SOPClassOffRegexString"];
   [requestDict setObject:[NSNumber numberWithBool:hasRestriction] forKey:@"hasRestriction"];


#pragma mark sha512
   [canonicalQuery replaceCharactersInRange:NSMakeRange(canonicalQuery.length-1, 1) withString:@"}"];
   LOG_DEBUG(@"curl --header \"Content-Type: application/json\" --request POST --data '%@' %@ > dcm.zip",canonicalQuery,[requestURL absoluteString]);
   NSString *canonicalQuerySHA512String=[canonicalQuery SHA512String];

   
#pragma mark wan
   for (NSString *devOID in wanArray)
   {
      NSLog(@"wan %@",devOID);
      //add nodes and start corresponding processes
   }

#pragma mark caché
   //path is the folder containing a file for each of the pacs consulted
   //path.json is the corresponding canonical query
   NSString *path=[DRS.tokentmpDir stringByAppendingPathComponent:canonicalQuerySHA512String];
   if (![defaultManager fileExistsAtPath:[path stringByAppendingPathExtension:@"json"]])
   {
      [canonicalQuery writeToFile:[path stringByAppendingPathExtension:@"json"] atomically:NO encoding:NSUTF8StringEncoding error:nil];
   }
   if (![defaultManager fileExistsAtPath:path])
      [defaultManager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];

   

#pragma mark accessType

   NSInteger accessTypeNumber=NSNotFound;
   if (![requestPath isEqualToString:@"/studyToken"])
      accessTypeNumber=[
                  @[
                     @"/weasis.xml",
                     @"/cornerstone.json",
                     @"/dicom.zip",
                     @"/osirix.dcmURLs",
                     @"/datatables/studies",
                     @"/datatables/series",
                     @"/datatables/patient",
                     @"/iso.dicom.zip",
                     @"/deflate.iso.dicom.zip",
                     @"/max.deflate.iso.dicom.zip",
                     @"/zip64.iso.dicom.zip",
                     @"/wadors.dicom"
                  ]  indexOfObject:requestPath
                  ];
   else
   {
      NSInteger accessTypeIndex=[names indexOfObject:@"accessType"];
      if (accessTypeIndex==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessType required in request"];
      accessTypeNumber=[
                  @[
                     @"weasis.xml",
                     @"cornerstone.json",
                     @"dicom.zip",
                     @"osirix.dcmURLs",
                     @"datatablesstudy.jsonp",
                     @"datatablesseries.jsonp",
                     @"datatablespatient.jsonp",
                     @"iso.dicom.zip",
                     @"deflate.iso.dicom.zip",
                     @"max.deflate.iso.dicom.zip",
                     @"zip64.iso.dicom.zip",
                     @"wadors.dicom"
                  ]
                  indexOfObject:values[accessTypeIndex]
                  ];
      if (accessTypeNumber==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessType %@ unknown",values[accessTypeIndex]];
   }
   
   switch (accessTypeNumber)
   {
#pragma mark - weasis
      case accessTypeWeasis:
      {
//loop each LAN pacs producing part
         for (NSString *devOID in lanArray)
         {
            [requestDict setObject:devOID forKey:@"devOID"];
            [requestDict setObject:[[path stringByAppendingPathComponent:devOID]stringByAppendingPathExtension:@"xml"] forKey:@"path"];
            [requestDict setObject:(DRS.pacs[devOID])[@"wadoweasisparameters"] forKey:@"wadoweasisparameters"];
            switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:(DRS.pacs[devOID])[@"select"]])
            {
               case selectTypeSql:
                  [DRS weasisSql4dictionary:requestDict];
            }
         }
//reply with result found in path
         NSArray *results=[defaultManager contentsOfDirectoryAtPath:path error:nil];
         NSMutableData *resultData=[NSMutableData dataWithData:[@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><manifest xmlns=\"http://www.weasis.org/xsd/2.5\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">" dataUsingEncoding:NSUTF8StringEncoding]];
         for (NSString *result in results)
         {
            [resultData appendData:[NSData dataWithContentsOfFile:[path stringByAppendingPathComponent:result]]];
         }
         [resultData appendData:[@"</manifest>" dataUsingEncoding:NSUTF8StringEncoding]];
         
         //weasis base64 dicom:get -i does not work
         /*
         RSDataResponse *response=[RSDataResponse responseWithData:[[[LFCGzipUtility gzipData:[xmlweasismanifest dataUsingEncoding:NSUTF8StringEncoding]] base64EncodedStringWithOptions:0]dataUsingEncoding:NSUTF8StringEncoding] contentType:@"application/x-gzip"];
         [response setValue:@"Base64" forAdditionalHeader:@"Content-Transfer-Encoding"];//https://tools.ietf.org/html/rfc2045
         return response;

         //xml dicom:get -iw works also, like with gzip
         return [RSDataResponse
         responseWithData:[xmlweasismanifest dataUsingEncoding:NSUTF8StringEncoding]
         contentType:@"text/xml"];
         */
         if (acceptsGzip)
            return [RSDataResponse
          responseWithData:[resultData gzip]
          contentType:@"application/x-gzip"];
         else return [RSDataResponse
         responseWithData:resultData contentType:@"text/xml"];
      } break;
         
#pragma mark cornerstone
         /*
          JSON returned
          [
          {
          "arcId":"devOID",
          "baseUrl":"proxyURIString",
          "patientList":
          [
           {
            "key"=123,
            "PatientID":"",
            "PatientName":"",
            "IssuerOfPatientID":"",
            "PatientBirthDate":"",
            "PatientSex":"",
            "studyList":
            [
             {
              "key"=123,
              "StudyInstanceUID":"",
              "studyDescription":"",
              "studyDate":"",
              "StudyTime":"",
              "AccessionNumber":"",
              "StudyID":"",
              "ReferringPhysicianName":"",
              "numImages":"",
              "modality":"",
              "patientId":"",
              "patientName":"",
              "seriesList":
              [
               {
                "key"=123,
                "seriesDescription":"",
                "seriesNumber":"",
                "SeriesInstanceUID":"",
                "SOPClassUID":"",
                "Modality":"",
                "WadoTransferSyntaxUID":"",
                "Institution":"",
                "Department":"",
                "StationName":"",
                "PerformingPhysician":"",
                "Laterality":"",
                "numImages":1,
                "instanceList":
                [
                 {
                  "key"=123,
                  "InstanceNumber":"",
                  "numFrames":1
                  "SOPClassUID":"",
                  "SOPInstanceUID":"",
                  "imageId":"wadouriInstance",
                 }
                ]
               }
              ]
             }
            ]
           }
          ]
         }

         (-1=info not available, 0=not an image, 1=monoframe, x=multiframe)
         */
      case accessTypeCornerstone:
      {
//loop each LAN pacs producing part
         for (NSString *devOID in lanArray)
         {
            [requestDict setObject:devOID forKey:@"devOID"];
            [requestDict setObject:[[path stringByAppendingPathComponent:devOID]stringByAppendingPathExtension:@"json"]forKey:@"path"];

             switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:(DRS.pacs[devOID])[@"select"]])
            {
                case selectTypeSql:
                  [DRS cornerstoneSql4dictionary:requestDict];
            }
         }
//reply with result found in path
         NSArray *results=[defaultManager contentsOfDirectoryAtPath:path error:nil];
         NSMutableData *resultData=[NSMutableData dataWithBytes:&startSquareBracket length:1];
         for (NSString *result in results)
         {
            [resultData appendData:[NSData dataWithContentsOfFile:[path stringByAppendingPathComponent:result]]];
            [resultData appendBytes:&semicolon length:1];
         }
         [resultData replaceBytesInRange:NSMakeRange(resultData.length-1, 1)
         withBytes:&endSquareBracket];
         
         return
         [RSDataResponse
          responseWithData:resultData contentType:@"application/json"];
      } break;
         
#pragma mark dicomzip
      case accessTypeDicomzip:
      case accessTypeIsoDicomZip:
      case accessTypeDeflateIsoDicomZip:
      case accessTypeMaxDeflateIsoDicomZip:
      {
         for (NSString *devOID in lanArray)
         {
            [requestDict setObject:devOID forKey:@"devOID"];
            [requestDict setObject:[[path stringByAppendingPathComponent:devOID]stringByAppendingPathExtension:@"json"]forKey:@"path"];

             switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:(DRS.pacs[devOID])[@"select"]])
            {
                case selectTypeSql:
//                  [DRS dicomzipSql4dictionary:requestDict];
                  break;
            }
         }
         //reply with result found in path
         NSArray *results=[defaultManager contentsOfDirectoryAtPath:path error:nil];
         NSMutableData *resultData=[NSMutableData dataWithBytes:&startSquareBracket length:1];
         for (NSString *result in results)
         {
            [resultData appendData:[NSData dataWithContentsOfFile:[path stringByAppendingPathComponent:result]]];
            [resultData appendBytes:&semicolon length:1];
         }
         [resultData replaceBytesInRange:NSMakeRange(resultData.length-1, 1)
         withBytes:&endSquareBracket];
         
//         return [DRS dicomzipChunks4dictionary:requestDict];
         return nil;
      } break;
         
#pragma mark osirix
      case accessTypeOsirix:
      {
      } break;

#pragma mark datatablesStudy
      case accessTypeDatatablesStudy:
      {
         NSLog(@"%@",[values description]);
          
          NSUInteger newIndex=[names indexOfObject:@"new"];
          if (newIndex && [values[newIndex] isEqualToString:@"true"])
          {
              [defaultManager removeItemAtPath:path error:nil];
              [defaultManager createDirectoryAtPath:path  withIntermediateDirectories:NO attributes:nil error:nil];
              
          }

//loop each LAN pacs producing part
         for (NSString *devOID in lanArray)
         {
            [requestDict setObject:devOID forKey:@"devOID"];
            [requestDict setObject:[[path stringByAppendingPathComponent:devOID]stringByAppendingPathExtension:@"array"] forKey:@"path"];
            NSUInteger maxCountIndex=[names indexOfObject:@"max"];
            if (maxCountIndex!=NSNotFound)[requestDict setObject:values[maxCountIndex] forKey:@"max"];

            switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:(DRS.pacs[devOID])[@"select"]])
            {
                case selectTypeSql:
                  [DRS datateblesStudySql4dictionary:requestDict];
                  break;
            }
         }

//reply with result found in path//TODO paging the answer
         NSMutableArray *resultsArray=[NSMutableArray array];
         NSArray *resultsDirectory=[defaultManager contentsOfDirectoryAtPath:path error:nil];
         for (NSString *resultFile in resultsDirectory)
         {
             NSArray *partialArray=[NSArray arrayWithContentsOfFile:[path stringByAppendingPathComponent:resultFile]];
             if ((partialArray.count==1)
             && [partialArray[0] isKindOfClass:[NSNumber class]])
             {
                 LOG_WARNING(@"datatables filter not sufficiently selective for path %@",requestDict[@"path"]);
                 return [RSDataResponse responseWithData:
                         [NSJSONSerialization
                          dataWithJSONObject:
                          @{
                           @"draw":values[[names indexOfObject:@"draw"]],
                           @"recordsTotal":[NSNumber numberWithLongLong:resultsArray.count],
                           @"data":@[],
                           @"error":[NSString stringWithFormat:@"you need a narrower filter. The browser table accepts up to %@ matches only",requestDict[@"max"]]
                          }
                          options:0
                          error:nil
                         ]
                         contentType:@"application/dicom+json"
                         ];
             }
             [resultsArray addObjectsFromArray:partialArray];
         }
         
         //no response?
          if (!resultsArray.count)
              return [RSDataResponse
              responseWithData:
                      [NSJSONSerialization
                       dataWithJSONObject:
                       @{
                        @"draw":values[[names indexOfObject:@"draw"]],
                        @"recordsTotal":@0,
                        @"data":@[],
                       }
                       options:0
                       error:nil
                      ]
              contentType:@"application/dicom+json"
              ];
          
         //check max of total answers
         if ([requestDict[@"max"] longLongValue] < resultsArray.count)
         {
            LOG_WARNING(@"datatables filter not sufficiently selective for path %@",requestDict[@"path"]);
            return [RSDataResponse
                    responseWithData:
                    [NSJSONSerialization
                     dataWithJSONObject:
                     @{
                      @"draw":values[[names indexOfObject:@"draw"]],
                      @"recordsTotal":[NSNumber numberWithLongLong:resultsArray.count],
                      @"data":@[],
                      @"error":[NSString stringWithFormat:@"you need a narrower filter. The browser table accepts up to %@ matches only. There were %lu",requestDict[@"max"],(unsigned long)resultsArray.count]
                     }
                     options:0
                     error:nil
                    ]
                    contentType:@"application/dicom+json"
                    ];
         }
          
          //order
          NSUInteger orderIndex=[names indexOfObject:@"order"];
          NSUInteger dirIndex=[names indexOfObject:@"dir"];
          if ((orderIndex!=NSNotFound) && (dirIndex!=NSNotFound))
          {
            int column=[values[orderIndex] intValue];
            if ([values[dirIndex] isEqualToString:@"desc"])
            {
               [resultsArray sortWithOptions:0 usingComparator:^NSComparisonResult(id obj1, id obj2) {
                   return [obj2[column] caseInsensitiveCompare:obj1[column]];
               }];
            }
            else
            {
               [resultsArray sortWithOptions:0 usingComparator:^NSComparisonResult(id obj1, id obj2) {
                   return [obj1[column] caseInsensitiveCompare:obj2[column]];
               }];
            }
        }
          
        //paging jsonp answer
                   
        long ps=[values[[names indexOfObject:@"start"]] intValue];
        long pl=[values[[names indexOfObject:@"length"]]intValue];
        //LOG_INFO(@"paging desired (start=[%ld],filas=[%ld],last=[%lu])",ps,pl,recordsFiltered-1);
        if (ps < 0) ps=0;
        if (ps > resultsArray.count - 1) ps=0;
        if (ps+pl+1 > resultsArray.count) pl=resultsArray.count-ps;
        //LOG_INFO(@"paging applied (start=[%ld],filas=[%ld],last=[%lu])",ps,pl,recordsFiltered-1);
        NSArray *page=[resultsArray subarrayWithRange:NSMakeRange(ps,pl)];
        if (!page)page=@[];
 

        return [RSDataResponse
                responseWithData:
                                [NSJSONSerialization
                                 dataWithJSONObject:
                                 @{
                                  @"draw":values[[names indexOfObject:@"draw"]],
                                  @"recordsTotal":[NSNumber numberWithLongLong:resultsArray.count],
                                  @"recordsFiltered":[NSNumber numberWithLongLong:resultsArray.count],
                                  @"data":page
                                 }
                                 options:0
                                 error:nil
                                 ]
                 contentType:@"application/dicom+json"
          ];

      } break;


#pragma mark datatablesSeries
      case accessTypeDatatablesSeries:
      {
      } break;
         
#pragma mark datatablesPatient
      case accessTypeDatatablesPatient:
      {
      } break;
   }
   return [RSErrorResponse responseWithClientError:404 message:@"inesperate end of studyToken for %@", path];
}


@end
