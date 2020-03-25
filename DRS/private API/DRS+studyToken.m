/*
 TODO
 socket in messages
 access types other lan and wan nodes
 osirix dcmURLs
 wadors study
 wadors series
 zip real compression
 tokenFolder keeping zipped
 */

#import "DRS+studyToken.h"

BOOL appendImmutableToCanonical(
    NSMutableDictionary *cacheDict,
    NSMutableString *canonicalQuery,
    NSString* name,
    NSString* value
)
{
    [canonicalQuery appendFormat:@"\"%@\":\"%@\",",name,value];
    if (cacheDict[name]) return [value isEqualToString:cacheDict[name]];
    return true;
}

/*
study pk and patient pk of studies selected
*/
RSResponse * sqlEP(
 NSMutableDictionary * EPDict,
 NSDictionary        * sqlcredentials,
 NSDictionary        * sqlDictionary,
 NSString            * sqlprolog,
 NSString            * sqlselect,
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
/*
 six or more parts:
   prolog
   select
   where
   and+
   limit&order
   format
 */
      if (execUTF8Bash(
          sqlcredentials,
          [NSString stringWithFormat:@"%@\"%@%@%@%@\"%@",
           
           sqlprolog,
           sqlDictionary[@"EselectEuiE"],
           sqlDictionary[@"Ewhere"],
           [NSString stringWithFormat:sqlDictionary[@"EmatchEui"],StudyInstanceUIDRegexpString],
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
                         sqlselect,
                         sqlDictionary[@"Ewhere"],
                         [NSString stringWithFormat:(sqlDictionary[@"EmatchEan"])[issuerNone],AccessionNumberEqualString],
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
                              sqlselect,
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
                              sqlselect,
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
                              sqlselect,
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
            sqlselect,
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
    regex:[NSRegularExpression regularExpressionWithPattern:@"^/(studyToken|osirix.dcmURLs|weasis.xml|dicom.zip|iso.dicom.zip|deflate.dicom.zip|deflate.iso.dicom.zip|max.deflate.iso.dicom.zip|zip64.iso.dicom.zip|wadors.dicom|cornerstone.json)$" options:0 error:NULL]
    processBlock:^(RSRequest* request,RSCompletionBlock completionBlock)
    {
       completionBlock(^RSResponse* (RSRequest* request) {return [DRS studyToken:request];}(request));
    }
   ];

   [self
    addHandler:@"GET"
    regex:[NSRegularExpression regularExpressionWithPattern:@"^/(studyToken|osirix.dcmURLs|weasis.xml|dicom.zip|iso.dicom.zip|deflate.dicom.zip|deflate.iso.dicom.zip|max.deflate.iso.dicom.zip|zip64.iso.dicom.zip|wadors.dicom|cornerstone.json)$" options:0 error:NULL]
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
                         names:(NSMutableArray*)names
                        values:(NSMutableArray*)values
                   acceptsGzip:(BOOL)acceptsGzip
{
   NSFileManager *defaultManager=[NSFileManager defaultManager];
   NSError *error=nil;


#pragma mark accessType

   NSInteger accessTypeNumber=NSNotFound;
   if (![requestPath isEqualToString:@"/studyToken"])
      accessTypeNumber=[
                  @[
                     @"/weasis.xml",
                     @"/cornerstone.json",
                     @"/dicom.zip",
                     @"/osirix.dcmURLs",
                     @"/datatables",
                     @"/datatables/studies",
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
                     @"datatables",
                     @"datatables/sudies",
                     @"datatables/patient",
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

#pragma mark cache?
   /*
    if cacheDict, evalutate changes:
    case datatables/study
    -> evaluate if it is a restriction and if so, filter already existing results
    case dicomzip,cornerstone,weasis, etc
    -> should declare bad url
    */
    NSString *queryPath=nil;
    NSUInteger cacheIndex=[names indexOfObject:@"cache"];
    NSString *cachePath=nil;
   
    NSMutableString *rPID=[NSMutableString string];
    NSMutableString *rFamily=[NSMutableString string];
    NSMutableString *rGiven=[NSMutableString string];
    NSMutableString *rMiddle=[NSMutableString string];
    NSMutableString *rPrefix=[NSMutableString string];
    NSMutableString *rSuffix=[NSMutableString string];
    NSMutableString *rDate=[NSMutableString string];
    NSMutableString *rMod=[NSMutableString string];
   //rPID,rFamily,rGiven,rMiddle,rPrefix,rSuffix,rDate,rMod,rDesc,rID
    NSMutableDictionary *cacheDict=nil;
    if (   (cacheIndex!=NSNotFound)
        && ([values[cacheIndex] length])
       )
    {
        cachePath=[DRS.tokentmpDir stringByAppendingPathComponent:values[cacheIndex]];
        NSData *cacheData=[NSData dataWithContentsOfFile:[cachePath stringByAppendingPathExtension:@"json"]];
        if (cacheData) cacheDict=[NSJSONSerialization JSONObjectWithData:cacheData options:NSJSONReadingMutableContainers error:nil];
     }
    
    NSMutableString *canonicalQuery=[NSMutableString stringWithString:@"{"];
    
    NSMutableDictionary *requestDict=[NSMutableDictionary dictionaryWithObject:@"1000" forKey:@"max"];

    NSInteger tokenIndex=[names indexOfObject:@"token"];
    if (tokenIndex!=NSNotFound) [requestDict setObject:values[tokenIndex] forKey:@"tokenString"];



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
              if (!appendImmutableToCanonical(
                                         cacheDict,
                                         canonicalQuery,
                                         @"StudyInstanceUID",
                                         StudyInstanceUIDRegexpString
                                         )
                  ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];

          }
          else return [RSErrorResponse responseWithClientError:404 message:@"studyToken param StudyInstanceUID: %@",values[StudyInstanceUIDIndex]];
       }
    }

   
#pragma mark AccessionNumber
    NSString *AccessionNumberRestriction=nil;
    NSString *AccessionNumberEqualString=nil;
    NSInteger AccessionNumberIndex=[names indexOfObject:@"AccessionNumber"];
    if (AccessionNumberIndex!=NSNotFound)
    {
        AccessionNumberEqualString=[values[AccessionNumberIndex] sqlEqualEscapedString];
        [requestDict setObject:AccessionNumberEqualString forKey:@"AccessionNumberEqualString"];
        [canonicalQuery appendFormat:@"\"AccessionNumber\":\"%@\",",AccessionNumberEqualString];
        NSString *cachedAN=cacheDict[@"AccessionNumber"];
        if (cachedAN && ![AccessionNumberEqualString hasPrefix:cachedAN]) [cacheDict removeAllObjects];
        else AccessionNumberRestriction=AccessionNumberEqualString;
    }


   
#pragma mark 1. PatientID (Pid)
    NSString *PatientIDLikeString=nil;
    NSInteger PatientIDIndex=[names indexOfObject:@"PatientID"];
    if (PatientIDIndex!=NSNotFound)
    {
       PatientIDLikeString=[values[PatientIDIndex] sqlLikeEscapedString];
       [requestDict setObject:PatientIDLikeString forKey:@"PatientIDLikeString"];
       [canonicalQuery appendFormat:@"\"PatientID\":\"%@\",",PatientIDLikeString];
       NSString *cachedPID=cacheDict[@"PatientID"];
       if (cachedPID && ![PatientIDLikeString hasPrefix:cachedPID]) [cacheDict removeAllObjects];
       else [rPID setString:PatientIDLikeString];
    }
   
#pragma mark 2. PatientName (Ppn)
   
   NSMutableString *PatientNameRegexString=[NSMutableString string];

   NSString *patientFamilyLikeString=nil;
   NSInteger patientFamilyIndex=[names indexOfObject:@"patientFamily"];
   if (patientFamilyIndex!=NSNotFound)
   {
      patientFamilyLikeString=[values[patientFamilyIndex] regexQuoteEscapedString];
      [PatientNameRegexString appendString:patientFamilyLikeString];
      [requestDict setObject:patientFamilyLikeString forKey:@"patientFamily"];
      [canonicalQuery appendFormat:@"\"patientFamily\":\"%@\",",patientFamilyLikeString];
   }
    
   [PatientNameRegexString appendString:@"^"];
    
   NSString *patientGivenLikeString=nil;
   NSInteger patientGivenIndex=[names indexOfObject:@"patientGiven"];
   if (patientGivenIndex!=NSNotFound)
   {
      patientGivenLikeString=[values[patientGivenIndex] regexQuoteEscapedString];
      [PatientNameRegexString appendString:patientGivenLikeString];
      [requestDict setObject:patientGivenLikeString forKey:@"patientGiven"];
      [canonicalQuery appendFormat:@"\"patientGiven\":\"%@\",",patientGivenLikeString];
   }
     
    [PatientNameRegexString appendString:@"^"];
     
   NSString *patientMiddleLikeString=nil;
   NSInteger patientMiddleIndex=[names indexOfObject:@"patientMiddle"];
   if (patientMiddleIndex!=NSNotFound)
   {
      patientMiddleLikeString=[values[patientMiddleIndex] regexQuoteEscapedString];
      [PatientNameRegexString appendString:patientMiddleLikeString];
      [requestDict setObject:patientMiddleLikeString forKey:@"patientMiddle"];
      [canonicalQuery appendFormat:@"\"patientMiddle\":\"%@\",",patientMiddleLikeString];
   }
     
    [PatientNameRegexString appendString:@"^"];
     
   NSString *patientPrefixLikeString=nil;
   NSInteger patientPrefixIndex=[names indexOfObject:@"patientPrefix"];
   if (patientPrefixIndex!=NSNotFound)
   {
      patientPrefixLikeString=[values[patientPrefixIndex] regexQuoteEscapedString];
      [PatientNameRegexString appendString:patientPrefixLikeString];
      [requestDict setObject:patientPrefixLikeString forKey:@"patientPrefix"];
      [canonicalQuery appendFormat:@"\"patientPrefix\":\"%@\",",patientPrefixLikeString];
   }
     
    [PatientNameRegexString appendString:@"^"];
     
   NSString *patientSuffixLikeString=nil;
   NSInteger patientSuffixIndex=[names indexOfObject:@"patientSuffix"];
   if (patientSuffixIndex!=NSNotFound)
   {
      patientSuffixLikeString=[values[patientSuffixIndex] regexQuoteEscapedString];
      [PatientNameRegexString appendString:patientSuffixLikeString];
      [requestDict setObject:patientSuffixLikeString forKey:@"patientSuffix"];
      [canonicalQuery appendFormat:@"\"patientSuffix\":\"%@\",",patientSuffixLikeString];
   }


   if (PatientNameRegexString.length > 4) [PatientNameRegexString removeTrailingCarets];
   else
   {
      NSInteger PatientNameIndex=[names indexOfObject:@"PatientName"];
       if (PatientNameIndex==NSNotFound) [PatientNameRegexString setString:@""];
       else //desglossing PatientName
       {
           [PatientNameRegexString setString:[[values[PatientNameIndex] removeTrailingCarets] regexQuoteEscapedString]];
           NSArray *PatientNameParts=[PatientNameRegexString componentsSeparatedByString:@"^"];
           if (PatientNameParts.count>0 && [PatientNameParts[0] length])
           {
              patientFamilyLikeString=PatientNameParts[0];
              [requestDict setObject:patientFamilyLikeString forKey:@"patientFamily"];
              [canonicalQuery appendFormat:@"\"patientFamily\":\"%@\",",patientFamilyLikeString];
           }
           if (PatientNameParts.count>1 && [PatientNameParts[1] length])
           {
              patientGivenLikeString=PatientNameParts[1];
              [requestDict setObject:patientGivenLikeString forKey:@"patientGiven"];
              [canonicalQuery appendFormat:@"\"patientGiven\":\"%@\",",patientGivenLikeString];
           }
           if (PatientNameParts.count>2 && [PatientNameParts[2] length])
           {
              patientMiddleLikeString=PatientNameParts[2];
              [requestDict setObject:patientMiddleLikeString forKey:@"patientMiddle"];
              [canonicalQuery appendFormat:@"\"patientMiddle\":\"%@\",",patientMiddleLikeString];
           }
           if (PatientNameParts.count>3 && [PatientNameParts[3] length])
           {
              patientPrefixLikeString=PatientNameParts[3];
              [requestDict setObject:patientPrefixLikeString forKey:@"patientPrefix"];
              [canonicalQuery appendFormat:@"\"patientPrefix\":\"%@\",",patientPrefixLikeString];
           }
           if (PatientNameParts.count>4 && [PatientNameParts[4] length])
           {
              patientSuffixLikeString=PatientNameParts[4];
              [requestDict setObject:patientSuffixLikeString forKey:@"patientSuffix"];
              [canonicalQuery appendFormat:@"\"patientSuffix\":\"%@\",",patientSuffixLikeString];
           }
       }
   }
    if (patientFamilyLikeString)
    {
       if (cacheDict[@"patientFamily"] && ![patientFamilyLikeString hasPrefix:cacheDict[@"patientFamily"]])
          [cacheDict removeAllObjects];//force new
       else if (patientFamilyLikeString.length) [rFamily setString:patientFamilyLikeString];
    }
    if (patientGivenLikeString)
    {
       if (cacheDict[@"patientGiven"] && ![patientGivenLikeString hasPrefix:cacheDict[@"patientGiven"]])
          [cacheDict removeAllObjects];//force new
       else if (patientGivenLikeString.length) [rGiven setString:patientGivenLikeString];
    }
    if (patientMiddleLikeString)
    {
       if (cacheDict[@"patientMiddle"] && ![patientMiddleLikeString hasPrefix:cacheDict[@"patientMiddle"]])
          [cacheDict removeAllObjects];//force new
       else if (patientMiddleLikeString.length) [rMiddle setString:patientMiddleLikeString];
    }
    if (patientPrefixLikeString)
    {
       if (cacheDict[@"patientPrefix"] && ![patientPrefixLikeString hasPrefix:cacheDict[@"patientPrefix"]])
          [cacheDict removeAllObjects];//force new
       else if (patientPrefixLikeString.length) [rPrefix setString:patientPrefixLikeString];
    }
    if (patientSuffixLikeString)
    {
       if (cacheDict[@"patientSuffix"] && ![patientSuffixLikeString hasPrefix:cacheDict[@"patientSuffix"]])
          [cacheDict removeAllObjects];//force new
       else if (patientSuffixLikeString.length) [rSuffix setString:patientSuffixLikeString];
    }

#pragma mark 3. StudyID (Eid)
    
    NSRegularExpression *EidRegex=nil;
    NSString *StudyIDLikeString=nil;
    NSInteger StudyIDIndex=[names indexOfObject:@"StudyID"];
    if (StudyIDIndex!=NSNotFound)
    {
       StudyIDLikeString=[values[StudyIDIndex] sqlLikeEscapedString];
       [requestDict setObject:StudyIDLikeString forKey:@"StudyIDLikeString"];

        [canonicalQuery appendFormat:@"\"StudyID\":\"%@\",",StudyIDLikeString];
        NSString *cachedStudyID=cacheDict[@"StudyID"];
        if (cachedStudyID && ![StudyIDLikeString hasPrefix:cachedStudyID])
                     [cacheDict removeAllObjects];//force new
        else if (StudyIDLikeString) EidRegex=[NSRegularExpression regularExpressionWithPattern:StudyIDLikeString options:NSRegularExpressionCaseInsensitive error:&error];
        if (error) LOG_WARNING(@"%@",[error description]);
    }

    
#pragma mark 4. StudyDate (Eda)
//@"%@-%@-%@|%@-%@-%@"
    
    NSArray *StudyDateArray=nil;
    NSInteger StudyDateIndex=[names indexOfObject:@"StudyDate"];
    NSString *StudyDateString=nil;
    if (StudyDateIndex!=NSNotFound)
    {
        StudyDateString=values[StudyDateIndex];
        if (![DICMTypes isDA0or1PipeString:StudyDateString]) return [RSErrorResponse responseWithClientError:404 message:@"studyToken bad StudyDate %@",StudyDateString];
        [canonicalQuery appendFormat:@"\"StudyDate\":\"%@\",",StudyDateString];
        
        NSArray *StudyDateComponents=[StudyDateString componentsSeparatedByString:@"|"];
//StudyDateArray
         if (StudyDateComponents.count==1) StudyDateArray=@[StudyDateComponents[0]];//on
         else //two parts
         {
             if      (![StudyDateComponents[1] length]) StudyDateArray=@[StudyDateComponents[0],@""];    //since
             else if (![StudyDateComponents[0] length]) StudyDateArray=@[@"",@"",StudyDateComponents[1]];//until
             else                StudyDateArray=@[StudyDateComponents[0],@"",@"",StudyDateComponents[1]];//between
         }
        [requestDict setObject:StudyDateArray forKey:@"StudyDateArray"];

//cache restriction
        if (![StudyDateString isEqualToString:cacheDict[@"StudyDate"]])
        {
            NSArray *cacheComponents=[cacheDict[@"StudyDate"] componentsSeparatedByString:@"|"];
            if (cacheComponents.count==1) //on
            {
                if ((StudyDateComponents.count==2) || ![cacheComponents[0] isEqualToString:StudyDateString]) [cacheDict removeAllObjects];
            }
            else
            {
                //check start
                if ([cacheComponents[0] length] && ([cacheComponents[0] compare:StudyDateComponents[0]]==NSOrderedDescending))[cacheDict removeAllObjects];
                //check end
                if ([cacheComponents[1] length] && ([StudyDateComponents[1] compare:cacheComponents[1]]==NSOrderedDescending)) [cacheDict removeAllObjects];
                if (cacheDict.count)
                {
                    if ([cacheComponents[1] length]) [rDate setString:[StudyDateString stringByAppendingString:@" 23:59"]];
                    else [rDate setString:StudyDateString];
                }
            }
        
          }
    }

 
#pragma mark 5. StudyDescription (Elo)
     NSRegularExpression *EloRegex=nil;
     NSString *StudyDescriptionRegexpString=nil;
     NSInteger StudyDescriptionIndex=[names indexOfObject:@"StudyDescription"];
     if (StudyDescriptionIndex!=NSNotFound)
    {
       StudyDescriptionRegexpString=[values[StudyDescriptionIndex] regexQuoteEscapedString];
       [requestDict setObject:StudyDescriptionRegexpString forKey:@"StudyDescriptionRegexpString"];
       [canonicalQuery appendFormat:@"\"StudyDescription\":\"%@\",",StudyDescriptionRegexpString];
       NSString *cachedStudyDescription=cacheDict[@"StudyDescription"];
       if (cachedStudyDescription && ![StudyDescriptionRegexpString hasPrefix:cachedStudyDescription])
                    [cacheDict removeAllObjects];//force new
       else if (StudyDescriptionRegexpString) EloRegex=[NSRegularExpression regularExpressionWithPattern:StudyDescriptionRegexpString options:NSRegularExpressionCaseInsensitive error:&error];
       if (error) LOG_WARNING(@"%@",[error description]);
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
       if (!appendImmutableToCanonical(
                                  cacheDict,
                                  canonicalQuery,
                                  @"refInstitution",
                                  refInstitutionLikeString
                                  )
           ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
    }

    NSString *refServiceLikeString=nil;
    NSInteger refServiceIndex=[names indexOfObject:@"refService"];
    if (refServiceIndex!=NSNotFound)
    {
       refPart=true;
       refServiceLikeString=[values[refServiceIndex] regexQuoteEscapedString];
       [requestDict setObject:refServiceLikeString forKey:@"refServiceLikeString"];
       if (!appendImmutableToCanonical(
                                  cacheDict,
                                  canonicalQuery,
                                  @"refService",
                                  refServiceLikeString
                                  )
           ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
    }

    NSString *refUserLikeString=nil;
    NSInteger refUserIndex=[names indexOfObject:@"refUser"];
    if (refUserIndex!=NSNotFound)
    {
       refPart=true;
       refUserLikeString=[values[refUserIndex] regexQuoteEscapedString];
       [requestDict setObject:refUserLikeString forKey:@"refUserLikeString"];
       if (!appendImmutableToCanonical(
                                  cacheDict,
                             canonicalQuery,
                                  @"refUser",
                                  refUserLikeString
                                  )
           ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
    }

    NSString *refIDLikeString=nil;
    NSInteger refIDIndex=[names indexOfObject:@"refID"];
    if (refIDIndex!=NSNotFound)
    {
       refPart=true;
       refIDLikeString=[values[refIDIndex] regexQuoteEscapedString];
       [requestDict setObject:refIDLikeString forKey:@"refIDLikeString"];
       if (!appendImmutableToCanonical(
                                  cacheDict,
                                  canonicalQuery,
                                  @"refID",
                                  refIDLikeString
                                  )
           ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
    }

    NSString *refIDTypeLikeString=nil;
    NSInteger refIDTypeIndex=[names indexOfObject:@"refIDType"];
    if (refIDTypeIndex!=NSNotFound)
    {
       refPart=true;
       refIDTypeLikeString=[values[refIDTypeIndex] regexQuoteEscapedString];
       [requestDict setObject:refIDTypeLikeString forKey:@"refIDTypeLikeString"];
       if (!appendImmutableToCanonical(
                                  cacheDict,
                                  canonicalQuery,
                                  @"refIDType",
                                  refIDTypeLikeString
                                  )
           ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
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
            if (!appendImmutableToCanonical(
                                       cacheDict,
                                       canonicalQuery,
                                       @"refInstitution",
                                       refInstitutionLikeString
                                       )
                ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
         }
         if (refParts.count>1)
         {
            refServiceLikeString=refParts[1];
            [requestDict setObject:refServiceLikeString forKey:@"refServiceLikeString"];
            if (!appendImmutableToCanonical(
                                       cacheDict,
                                       canonicalQuery,
                                       @"refService",
                                       refServiceLikeString
                                       )
                ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
         }
         if (refParts.count>2)
         {
            refUserLikeString=refParts[2];
            [requestDict setObject:refUserLikeString forKey:@"refUserLikeString"];
            if (!appendImmutableToCanonical(
                                       cacheDict,
                                       canonicalQuery,
                                       @"refUser",
                                       refUserLikeString
                                       )
                ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
         }
         if (refParts.count>3)
         {
            refIDLikeString=refParts[3];
            [requestDict setObject:refIDLikeString forKey:@"refIDLikeString"];
            if (!appendImmutableToCanonical(
                                       cacheDict,
                                       canonicalQuery,
                                       @"refID",
                                       refIDLikeString
                                       )
                ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
          }
         if (refParts.count>4)
         {
            refIDTypeLikeString=refParts[4];
            [requestDict setObject:refIDTypeLikeString forKey:@"refIDTypeLikeString"];
            if (!appendImmutableToCanonical(
                                       cacheDict,
                                       canonicalQuery,
                                       @"refIDType",
                                       refIDTypeLikeString
                                       )
                ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
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
       if (!appendImmutableToCanonical(
                                  cacheDict,
                                  canonicalQuery,
                                  @"readInstitution",
                                  readInstitutionLikeString
                                  )
           ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
    }

    NSString *readServiceLikeString=nil;
    NSInteger readServiceIndex=[names indexOfObject:@"readService"];
    if (readServiceIndex!=NSNotFound)
    {
       readPart=true;
       readServiceLikeString=[values[readServiceIndex] regexQuoteEscapedString];
       [requestDict setObject:readServiceLikeString forKey:@"readServiceLikeString"];
       if (!appendImmutableToCanonical(
                                  cacheDict,
                                  canonicalQuery,
                                  @"readService",
                                  readServiceLikeString
                                  )
           ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
    }

    NSString *readUserLikeString=nil;
    NSInteger readUserIndex=[names indexOfObject:@"readUser"];
    if (readUserIndex!=NSNotFound)
    {
       readPart=true;
       readUserLikeString=[values[readUserIndex] regexQuoteEscapedString];
       [requestDict setObject:readUserLikeString forKey:@"readUserLikeString"];
       if (!appendImmutableToCanonical(
                                  cacheDict,
                                  canonicalQuery,
                                  @"readUser",
                                  readUserLikeString
                                  )
           ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
    }

    NSString *readIDLikeString=nil;
    NSInteger readIDIndex=[names indexOfObject:@"readID"];
    if (readIDIndex!=NSNotFound)
    {
       readPart=true;
       readIDLikeString=[values[readIDIndex] regexQuoteEscapedString];
       [requestDict setObject:readIDLikeString forKey:@"readIDLikeString"];
       if (!appendImmutableToCanonical(
                                  cacheDict,
                                  canonicalQuery,
                                  @"readID",
                                  readIDLikeString
                                  )
           ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
    }
    
    NSString *readIDTypeLikeString=nil;
    NSInteger readIDTypeIndex=[names indexOfObject:@"readIDType"];
    if (readIDTypeIndex!=NSNotFound)
    {
       readPart=true;
       readIDTypeLikeString=[values[readIDTypeIndex] regexQuoteEscapedString];
       [requestDict setObject:readIDTypeLikeString forKey:@"readIDTypeLikeString"];
       if (!appendImmutableToCanonical(
                                  cacheDict,
                                  canonicalQuery,
                                  @"readIDType",
                                  readIDTypeLikeString
                                  )
           ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
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
            if (!appendImmutableToCanonical(
                                       cacheDict,
                                       canonicalQuery,
                                       @"readInstitution",
                                       readInstitutionLikeString
                                       )
                ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
         }
         if (readParts.count>1)
         {
            readServiceLikeString=readParts[1];
            [requestDict setObject:readServiceLikeString forKey:@"readServiceLikeString"];
            if (!appendImmutableToCanonical(
                                       cacheDict,
                                       canonicalQuery,
                                       @"readService",
                                       readServiceLikeString
                                       )
                ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
         }
         if (readParts.count>2)
         {
            readUserLikeString=readParts[2];
            [requestDict setObject:readUserLikeString forKey:@"readUserLikeString"];
            if (!appendImmutableToCanonical(
                                       cacheDict,
                                       canonicalQuery,
                                       @"readUser",
                                       readUserLikeString
                                       )
                ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
         }
         if (readParts.count>3)
         {
            readIDLikeString=readParts[3];
            [requestDict setObject:readIDLikeString forKey:@"readIDLikeString"];
            if (!appendImmutableToCanonical(
                                       cacheDict,
                                       canonicalQuery,
                                       @"readID",
                                       readIDLikeString
                                       )
                ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
         }
         if (readParts.count>4)
         {
            readIDTypeLikeString=readParts[4];
            if (!appendImmutableToCanonical(
                                       cacheDict,
                                       canonicalQuery,
                                       @"readIDType",
                                       readIDTypeLikeString
                                       )
                ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
         }
      }
   }

    
#pragma mark 8. SOPClassInStudyString
    
   NSInteger SOPClassInStudyIndex=[names indexOfObject:@"SOPClassInStudy"];
   if ((SOPClassInStudyIndex!=NSNotFound) && [DICMTypes isSingleUIString:values[SOPClassInStudyIndex]])
   {
           [requestDict setObject:values[SOPClassInStudyIndex] forKey:@"SOPClassInStudyRegexpString"];
           if (!appendImmutableToCanonical(
                                      cacheDict,
                                      canonicalQuery,
                                      @"SOPClassInStudy",
                                      values[SOPClassInStudyIndex]
                                      )
               ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
   }

   
#pragma mark 9. ModalityInStudyString
   NSInteger ModalityInStudyIndex=[names indexOfObject:@"ModalityInStudy"];
   if ((ModalityInStudyIndex!=NSNotFound) && [DICMTypes isSingleCSString:values[ModalityInStudyIndex]])
   {
      [requestDict setObject:values[ModalityInStudyIndex] forKey:@"ModalityInStudyRegexpString"];
       [canonicalQuery appendFormat:@"\"ModalityInStudy\":\"%@\",",values[ModalityInStudyIndex]];
       if (!cacheDict[@"ModalityInStudy"]) [rMod setString:values[ModalityInStudyIndex]];
       else [cacheDict removeAllObjects];
   }

#pragma mark issuer
    
   NSArray *issuerArray=nil;
   NSInteger issuerIndex=[names indexOfObject:@"issuer"];
   if (issuerIndex!=NSNotFound)
   {
      if (!appendImmutableToCanonical(
                                 cacheDict,
                                 canonicalQuery,
                                 @"issuer",
                                 [values[issuerIndex] sqlEqualEscapedString]
                                 )
          ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
       
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
    NSString *SeriesInstanceUIDRegexString=nil;
   if (SeriesInstanceUIDIndex!=NSNotFound)
   {
       SeriesInstanceUIDRegexString=values[SeriesInstanceUIDIndex];
      [requestDict setObject:SeriesInstanceUIDRegexString forKey:@"SeriesInstanceUIDRegexString"];
      if (!appendImmutableToCanonical(
                                 cacheDict,
                                 canonicalQuery,
                                 @"SeriesInstanceUID",
                                 values[SeriesInstanceUIDIndex]
                                 )
          ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
   }
   
// SeriesNumber
   NSInteger SeriesNumberIndex=[names indexOfObject:@"SeriesNumber"];
   if (SeriesNumberIndex!=NSNotFound)
   {
      [requestDict setObject:values[SeriesNumberIndex] forKey:@"SeriesNumberRegexString"];
      if (!appendImmutableToCanonical(
                                 cacheDict,
                                 canonicalQuery,
                                 @"SeriesNumber",
                                 values[SeriesNumberIndex]
                                 )
          ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
   }

// SeriesDescription@StationName@Department@Institution
   NSInteger SeriesDescriptionIndex=[names indexOfObject:@"SeriesDescription"];
   if (SeriesDescriptionIndex!=NSNotFound)
   {
      [requestDict setObject:values[SeriesDescriptionIndex] forKey:@"SeriesDescriptionRegexString"];
       if (!appendImmutableToCanonical(
                                  cacheDict,
                                  canonicalQuery,
                                  @"SeriesDescription",
                                  values[SeriesDescriptionIndex]
                                  )
           ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
   }
   
// Modality
   NSInteger ModalityIndex=[names indexOfObject:@"Modality"];
   if (ModalityIndex!=NSNotFound)
   {
      [requestDict setObject:values[ModalityIndex] forKey:@"ModalityRegexString"];
      if (!appendImmutableToCanonical(
                                 cacheDict,
                                 canonicalQuery,
                                 @"Modality",
                                 values[ModalityIndex]
                                 )
          ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
   }

// SOPClass
   NSInteger SOPClassIndex=[names indexOfObject:@"SOPClass"];
   if (SOPClassIndex!=NSNotFound)
   {
      [requestDict setObject:values[SOPClassIndex] forKey:@"SOPClassRegexString"];
      if (!appendImmutableToCanonical(
                                 cacheDict,
                                 canonicalQuery,
                                 @"SOPClass",
                                 values[SOPClassIndex]
                                 )
          ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
   }
   
// SOPClassOff
   NSInteger SOPClassOffIndex=[names indexOfObject:@"SOPClassOff"];
   if (SOPClassOffIndex!=NSNotFound)
   {
      [requestDict setObject:values[SOPClassOffIndex] forKey:@"SOPClassOffRegexString"];
      if (!appendImmutableToCanonical(
                                 cacheDict,
                                 canonicalQuery,
                                 @"SOPClassOff",
                                 values[SOPClassOffIndex]
                                 )
          ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
   }

//hasSeriesRestriction?
   BOOL hasSeriesRestriction=
      requestDict[@"SeriesInstanceUIDRegexString"]
   || requestDict[@"SeriesNumberRegexString"]
   || requestDict[@"SeriesDescriptionRegexString"]
   || requestDict[@"ModalityRegexString"]
   || requestDict[@"SOPClassRegexString"]
   || requestDict[@"SOPClassOffRegexString"];
   [requestDict setObject:[NSNumber numberWithBool:hasSeriesRestriction] forKey:@"hasSeriesRestriction"];


   
#pragma mark wan
   for (NSString *devOID in wanArray)
   {
      NSLog(@"wan %@",devOID);
      //add nodes and start corresponding processes
   }

#pragma mark no cache -> create it
   BOOL studyRestriction=(cacheDict && cacheDict.count);
   if (! studyRestriction)
   {
      //new
       [canonicalQuery replaceCharactersInRange:NSMakeRange(canonicalQuery.length-1, 1) withString:@"}"];
       NSString *canonicalQuerySHA512String=[canonicalQuery MD5String];
       queryPath=[DRS.tokentmpDir stringByAppendingPathComponent:canonicalQuerySHA512String];
       
       if (![defaultManager fileExistsAtPath:queryPath])
       {
          //path.json is the corresponding canonical query
          [canonicalQuery writeToFile:[queryPath stringByAppendingPathExtension:@"json"] atomically:NO encoding:NSUTF8StringEncoding error:nil];
      
          //path is the folder containing a file for each of the pacs consulted
          [defaultManager createDirectoryAtPath:queryPath withIntermediateDirectories:NO attributes:nil error:nil];
       }
    }
    else queryPath=cachePath; //cache vigente
   

   
   switch (accessTypeNumber)
   {
#pragma mark - weasis
      case accessTypeWeasis:
      {
//loop each LAN pacs producing part
         for (NSString *devOID in lanArray)
         {
            [requestDict setObject:devOID forKey:@"devOID"];
            [requestDict setObject:[[queryPath stringByAppendingPathComponent:devOID]stringByAppendingPathExtension:@"xml"] forKey:@"devOIDXMLPath"];
            [requestDict setObject:[[queryPath stringByAppendingPathComponent:devOID]stringByAppendingPathExtension:@"plist"] forKey:@"devOIDPLISTPath"];

            [requestDict setObject:(DRS.pacs[devOID])[@"wadoweasisparameters"] forKey:@"wadoweasisparameters"];
            switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:(DRS.pacs[devOID])[@"select"]])
            {
               case selectTypeSql:
                  [DRS weasisSql4dictionary:requestDict];
            }
         }
//reply with result found in path
         NSArray *results=[defaultManager contentsOfDirectoryAtPath:queryPath error:nil];
         NSMutableString *resultString=[NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><manifest xmlns=\"http://www.weasis.org/xsd/2.5\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">"];
         for (NSString *resultFile in results)
         {
            if ([[resultFile pathExtension] isEqualToString:@"xml"])
            {
               [resultString appendString:
                [NSString
                 stringWithContentsOfFile:
                 [queryPath stringByAppendingPathComponent:resultFile]
                 encoding:NSUTF8StringEncoding
                 error:nil
                 ]
                ];
            }
         }
         [resultString appendString:@"</manifest>"];
         
//insert session

         NSInteger sessionIndex=[names indexOfObject:@"session"];
         if (sessionIndex!=NSNotFound)
         {
            [resultString
             replaceOccurrencesOfString:@"_sessionString_"
             withString:values[sessionIndex]
             options:0
             range:NSMakeRange(0, resultString.length)
             ];
         }

//insert proxyURI
          NSInteger proxyURIIndex=[names indexOfObject:@"proxyURI"];
           if (proxyURIIndex!=NSNotFound)
           {
              [resultString
               replaceOccurrencesOfString:@"_proxyURIString_"
               withString:values[proxyURIIndex]
               options:0
               range:NSMakeRange(0, resultString.length)
               ];
           }

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
          responseWithData:[[resultString dataUsingEncoding:NSUTF8StringEncoding] gzip]
          contentType:@"application/x-gzip"];
         else return [RSDataResponse
         responseWithData:[resultString dataUsingEncoding:NSUTF8StringEncoding] contentType:@"text/xml"];
      } break;
         
#pragma mark cornerstone
      case accessTypeCornerstone:
      {
//loop each LAN pacs producing part
         for (NSString *devOID in lanArray)
         {
            [requestDict setObject:devOID forKey:@"devOID"];
            [requestDict setObject:[[queryPath stringByAppendingPathComponent:devOID]stringByAppendingPathExtension:@"json"]forKey:@"devOIDJSONPath"];
            [requestDict setObject:[[queryPath stringByAppendingPathComponent:devOID]stringByAppendingPathExtension:@"plist"] forKey:@"devOIDPLISTPath"];

             switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:(DRS.pacs[devOID])[@"select"]])
            {
                case selectTypeSql:
                  [DRS cornerstoneSql4dictionary:requestDict];
            }
         }
//reply with result found in path
         NSArray *results=[defaultManager contentsOfDirectoryAtPath:queryPath error:nil];
         NSMutableString *resultString=[NSMutableString stringWithString:@"["];
         for (NSString *resultFile in results)
         {
            if ([[resultFile pathExtension] isEqualToString:@"json"])
            {
               [resultString appendString:
                [NSString
                 stringWithContentsOfFile:
                 [queryPath stringByAppendingPathComponent:resultFile]
                 encoding:NSUTF8StringEncoding
                 error:nil
                 ]
                ];
               [resultString appendString:@","];
            }
         }
         [resultString replaceOccurrencesOfString:@"," withString:@"]" options:0 range:NSMakeRange(resultString.length -1,1)];
         
//insert session

         NSInteger sessionIndex=[names indexOfObject:@"session"];
         if (sessionIndex!=NSNotFound)
         {
            [resultString
             replaceOccurrencesOfString:@"_sessionString_"
             withString:values[sessionIndex]
             options:0
             range:NSMakeRange(0, resultString.length)
             ];
         }

//insert proxyURI
          NSInteger proxyURIIndex=[names indexOfObject:@"proxyURI"];
           if (proxyURIIndex!=NSNotFound)
           {
              [resultString
               replaceOccurrencesOfString:@"_proxyURIString_"
               withString:values[proxyURIIndex]
               options:0
               range:NSMakeRange(0, resultString.length)
               ];
           }

         return
         [RSDataResponse
          responseWithData:[resultString dataUsingEncoding:NSUTF8StringEncoding] contentType:@"application/json"];
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
            NSString *devOIDPath=[queryPath stringByAppendingPathComponent:devOID];
            [requestDict setObject:devOIDPath forKey:@"devOIDPath"];
            [requestDict setObject:[[queryPath stringByAppendingPathComponent:devOID]stringByAppendingPathExtension:@"plist"] forKey:@"devOIDPLISTPath"];

             switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:(DRS.pacs[devOID])[@"select"]])
            {
                case selectTypeSql:
                  [DRS datateblesStudySql4dictionary:requestDict];
                  [DRS dicomzipSql4d:requestDict];
                  break;
            }
         }
          
         NSMutableArray *pathArray=[NSMutableArray array];
          NSArray *studiesSelected=nil;
          BOOL oneStudySelected=false;
          if (StudyInstanceUIDRegexpString)
          {
              studiesSelected=[StudyInstanceUIDRegexpString componentsSeparatedByString:@"|"];
              oneStudySelected=(studiesSelected.count == 1);
          }
         BOOL oneSeriesSelected=false;
         NSArray *seriesSelected=nil;
         if (SeriesInstanceUIDRegexString!=nil)
         {
             seriesSelected=[SeriesInstanceUIDRegexString componentsSeparatedByString:@"|"];
             oneSeriesSelected=(seriesSelected.count < 2);
         }
         NSArray *devOIDItems=[defaultManager contentsOfDirectoryAtPath:queryPath error:nil];
          for (NSString *devOIDItem in devOIDItems)
          {
              NSString *devOIDPath=[queryPath stringByAppendingPathComponent:devOIDItem];
              NSArray *studyFolders=[defaultManager contentsOfDirectoryAtPath:devOIDPath error:nil];
              if (studyFolders && studyFolders.count)
              {
                  if (!studiesSelected)
                  {
                      //every studies
                      for (NSString *studyFolder in studyFolders)
                      {
                           [pathArray addObject:[devOIDItem stringByAppendingPathComponent:studyFolder]];
                      }
                  }
                  else if (oneStudySelected)
                  {
                      //there is/are studies for this devOID
                      if ([studyFolders indexOfObject:StudyInstanceUIDRegexpString]!=NSNotFound)
                      {
                          //study found
                          if (seriesSelected)
                          {
                              NSString *studyPath=[devOIDPath stringByAppendingPathComponent:StudyInstanceUIDRegexpString];
                              NSArray *seriesFolders=[defaultManager contentsOfDirectoryAtPath:studyPath error:nil];
                              for (NSString *seriesFolder in seriesFolders)
                              {
                                  if ([seriesSelected indexOfObject:seriesFolder]!=NSNotFound)
                                  [pathArray addObject:[[devOIDItem stringByAppendingPathComponent:StudyInstanceUIDRegexpString] stringByAppendingPathComponent:seriesFolder]];
                              }
                          }
                          else //complete study
                          {
                              [pathArray addObject:[devOIDItem stringByAppendingPathComponent:StudyInstanceUIDRegexpString]];
                          }
                      }
                  }
                  else //multiple studies
                  {
                      //more than one study selected
                      for (NSString *studyFolder in studyFolders)
                      {
                          if ([studiesSelected indexOfObject:studyFolder]!=NSNotFound)
                              [pathArray addObject:[devOIDItem stringByAppendingPathComponent:studyFolder]];
                          
                      }
                  }
              }
          }
          //LOG_INFO(@"%@",[pathArray description]);
          NSString *zipPath=[[queryPath lastPathComponent] stringByAppendingPathExtension:@"zip"];
          NSMutableString *zipCommand=
          [NSMutableString
           stringWithFormat:@"cd %@;rm -f %@;/usr/bin/zip -r %@ %@",
           queryPath,
           zipPath,
           zipPath,
           [pathArray componentsJoinedByString:@" "]
           ];
          NSMutableData *zipstdout=[NSMutableData data];
          if (execUTF8Bash(@{},zipCommand,zipstdout)!=0) LOG_ERROR(@"zip error");
          NSLog(@"%@",[queryPath stringByAppendingPathExtension:@"zip"]);
         return
         [RSDataResponse
          responseWithData:[NSData dataWithContentsOfFile:[queryPath stringByAppendingPathComponent:zipPath]]
          contentType:@"application/zip"];//application/octet-stream
         return nil;// [NSData dataWithContentsOfFile:[queryPath stringByAppendingPathExtension:@"zip"]]
      } break;
         
#pragma mark osirix
      case accessTypeOsirix:
      {
      } break;

#pragma mark datatables
      case accessTypeDatatables:
      case accessTypeDatatablesstudies:
      case accessTypeDatatablespatient:
      {
         NSLog(@"%@",[values description]);
          
          NSUInteger newIndex=[names indexOfObject:@"new"];
          if ((newIndex!=NSNotFound) && [values[newIndex] isEqualToString:@"true"])
          {
              [defaultManager removeItemAtPath:requestPath error:nil];
              [defaultManager createDirectoryAtPath:requestPath  withIntermediateDirectories:NO attributes:nil error:nil];
          }

         if (!studyRestriction)
         {
            //is not a restriction of existing results
//loop each LAN pacs producing part
            for (NSString *devOID in lanArray)
            {
               [requestDict setObject:devOID forKey:@"devOID"];
               [requestDict setObject:[[queryPath stringByAppendingPathComponent:devOID]stringByAppendingPathExtension:@"plist"] forKey:@"devOIDPLISTPath"];
               NSUInteger maxCountIndex=[names indexOfObject:@"max"];
               if (maxCountIndex!=NSNotFound)[requestDict setObject:values[maxCountIndex] forKey:@"max"];

               switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:(DRS.pacs[devOID])[@"select"]])
               {
                   case selectTypeSql:
                     [DRS datateblesStudySql4dictionary:requestDict];
                     break;
               }
            }
         }

#pragma mark resultsArray
         NSMutableArray *resultsArray=[NSMutableArray array];
         NSArray *resultsDirectory=[defaultManager contentsOfDirectoryAtPath:queryPath error:nil];
         for (NSString *resultFile in resultsDirectory)
         {
            if ([[resultFile pathExtension] isEqualToString:@"plist"])
            {
                NSArray *partialArray=[NSArray arrayWithContentsOfFile:[queryPath stringByAppendingPathComponent:resultFile]];
                if ((partialArray.count==1)
                && [partialArray[0] isKindOfClass:[NSNumber class]])
                {
                    LOG_WARNING(@"datatables filter not sufficiently selective for path %@",requestDict[@"queryPath"]);
                    return [RSDataResponse responseWithData:
                            [NSJSONSerialization
                             dataWithJSONObject:
                             @{
                              @"draw":values[[names indexOfObject:@"draw"]],
                              @"recordsFiltered":[NSNumber numberWithLongLong:resultsArray.count],
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
         }

          NSMutableDictionary *dict=[NSMutableDictionary dictionary];
          NSUInteger drawIndex=[names indexOfObject:@"draw"];
          if (drawIndex!=NSNotFound)
              [dict setObject:values[drawIndex] forKey:@"draw"];

         //no response?
          if (!resultsArray.count)
          {
              [dict setObject:@0 forKey:@"recordsFiltered"];
              [dict setObject:@0 forKey:@"recordsTotal"];
              [dict setObject:@[] forKey:@"data"];
              return [RSDataResponse
              responseWithData:
                      [NSJSONSerialization
                       dataWithJSONObject:dict
                       options:0
                       error:nil
                      ]
              contentType:@"application/dicom+json"
              ];
          }
         //check max of total answers
          
         if (    requestDict[@"max"]
              && ([requestDict[@"max"] longLongValue] < resultsArray.count)
             )
         {
            LOG_WARNING(@"datatables filter not sufficiently selective for path %@",requestDict[@"queryPath"]);
             [dict setObject:[NSNumber numberWithLongLong:resultsArray.count] forKey:@"recordsFiltered"];
            [dict setObject:[NSNumber numberWithLongLong:resultsArray.count] forKey:@"recordsTotal"];
             [dict setObject:@[] forKey:@"data"];
             [dict setObject:[NSString stringWithFormat:@"you need a narrower filter. The browser table accepts up to %@ matches only. There were %lu",requestDict[@"max"],(unsigned long)resultsArray.count] forKey:@"error"];

            return [RSDataResponse
                    responseWithData:
                    [NSJSONSerialization
                     dataWithJSONObject:dict
                     options:0
                     error:nil
                    ]
                    contentType:@"application/dicom+json"
                    ];
         }
         
#pragma mark studyRestriction
        if (studyRestriction)
        {
         //create compound predicate
           NSPredicate *compoundPredicate = [NSPredicate predicateWithBlock:^BOOL(NSArray *row, NSDictionary *bindings)
           {
               //AccessionNumber
               if (AccessionNumberRestriction && ![row[13] hasPrefix:AccessionNumberRestriction]) return false;
               
               //PatientID
               if (rPID.length && ![row[23] hasPrefix:rPID]) return false;

               //PatientName
               if (  rFamily.length
                   ||rGiven.length
                   ||rMiddle.length
                   ||rPrefix.length
                   ||rSuffix.length
                   )
               {
                  NSArray *n=[row[4] componentsSeparatedByString:@"^"];
                  NSUInteger c=n.count;
                  if ((c > 0) && rFamily.length && ([n[0] length]))
                  {
                     if ([[n[0] componentsSeparatedByString:rFamily] count] < 2) return false;
                  }
                  if ((c > 1) && rGiven.length && ([n[1] length]))
                  {
                     if ([[n[1] componentsSeparatedByString:rGiven] count] < 2) return false;
                  }
                  if ((c > 2) && rMiddle.length && ([n[2] length]))
                  {
                     if ([[n[2] componentsSeparatedByString:rMiddle] count] < 2) return false;
                  }
                  if ((c > 3) && rPrefix.length && ([n[3] length]))
                  {
                     if ([[n[3] componentsSeparatedByString:rPrefix] count] < 2) return false;
                  }
                  if ((c > 4) && rSuffix.length && ([n[4] length]))
                  {
                     if ([[n[4] componentsSeparatedByString:rSuffix] count] < 2) return false;
                  }

               }

               if (rDate.length)
               {
                  //@"%@-%@-%@|%@-%@-%@"
                  NSArray *d=[rDate componentsSeparatedByString:@"|"];
                  if ((d.count==1) && ![row[5] hasPrefix:d[0]]) return false;
                  //two parts
                  if ([d[0] length] && ([d[0] compare:row[5]]==NSOrderedDescending)) return false;
                  if ([d[1] length] && [d[1] compare:[row[5] substringToIndex:10]]==NSOrderedAscending) return false;
               }
                    
               if (rMod.length && [[row[6] componentsSeparatedByString:rMod] count] < 2) return false;
              
               if (EloRegex && ![EloRegex numberOfMatchesInString:row[7] options:0 range:NSMakeRange(0,[row[7] length])]) return false;
               
                if (EidRegex && ![EidRegex numberOfMatchesInString:row[15] options:0 range:NSMakeRange(0,[row[15] length])]) return false;

               return true;
            }];
         
            [resultsArray filterUsingPredicate:compoundPredicate];
         }
         
         
#pragma mark order
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
 
          [dict setObject:[NSNumber numberWithLongLong:resultsArray.count] forKey:@"recordsFiltered"];
          [dict setObject:[NSNumber numberWithLongLong:resultsArray.count] forKey:@"recordsTotal"];
          [dict setObject:page forKey:@"data"];

        return [RSDataResponse
                responseWithData:
                                [NSJSONSerialization
                                 dataWithJSONObject:dict
                                 options:0
                                 error:nil
                                 ]
                 contentType:@"application/dicom+json"
          ];

      } break;
   }
   return [RSErrorResponse responseWithClientError:404 message:@"inesperate end of studyToken for %@", requestPath];
}


@end
