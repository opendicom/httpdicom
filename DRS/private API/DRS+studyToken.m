/*
 TODO
 socket in messages
 access types other lan and wan nodes
 osirix dcmURLs
 wadors study
 wadors series
 */

#import "DRS+studyToken.h"

NSMutableArray *buildPNArray(
   NSMutableArray *names,
   NSMutableArray *values,
   NSUInteger PNConcatIndex,
   NSUInteger PNIndex[],
   NSArray *PNLabel,
   NSMutableDictionary *cachedQueryDict,
   NSMutableDictionary *studyRestrictionDict,
   NSMutableString *canonicalQuery
)
{
   NSMutableArray *PNArray=[NSMutableArray array];
   if (PNConcatIndex!=NSNotFound)
   {
       
      [PNArray setArray:[[values[PNConcatIndex] regexQuoteEscapedString] componentsSeparatedByString:@"^"]];
      NSUInteger i=PNArray.count;
      while (i > 0)
      {
         i--;
         if ([PNArray[i] length])
         {
            if (cachedQueryDict[PNLabel[i]])
            {
               if(![PNArray[i] hasPrefix:cachedQueryDict[PNLabel[i]]]) return nil;
            }
             if ([@[@"ref",@"read"] indexOfObject:PNLabel[i]]!=NSNotFound)
                 [studyRestrictionDict setObject:PNArray[i] forKey:PNLabel[i]];
             else
             {
                 NSError *error=nil;
                 [studyRestrictionDict setObject:[NSRegularExpression regularExpressionWithPattern:PNArray[i] options:NSRegularExpressionCaseInsensitive error:&error] forKey:PNLabel[i]];
                 if (error) LOG_WARNING(@"%@",[error debugDescription]);
             }
             [canonicalQuery appendFormat:@"\"%@\":\"%@\",",PNLabel[i],PNArray[i]];
         }
      }
   }
   else if (  (PNIndex[0]!=NSNotFound)
            ||(PNIndex[1]!=NSNotFound)
            ||(PNIndex[2]!=NSNotFound)
            ||(PNIndex[3]!=NSNotFound)
            ||(PNIndex[4]!=NSNotFound)
           )
   {
      for (NSUInteger i=4;i<0;i--)
      {
         if (PNIndex[i]!=NSNotFound)
         {
            NSString *partString=[values[i] regexQuoteEscapedString];
            [PNArray insertObject:partString atIndex:0];
            if (cachedQueryDict[PNLabel[i]] && ![partString hasPrefix:cachedQueryDict[PNLabel[i]]]) return nil;
            
             if ([@[@"ref",@"read"] indexOfObject:PNLabel[i]]!=NSNotFound)
                 [studyRestrictionDict setObject:partString forKey:PNLabel[i]];
             else
             {
                 NSError *error=nil;
                 [studyRestrictionDict setObject:[NSRegularExpression regularExpressionWithPattern:partString options:NSRegularExpressionCaseInsensitive error:&error] forKey:PNLabel[i]];
                 if (error) LOG_WARNING(@"%@",[error debugDescription]);
             }
            [canonicalQuery appendFormat:@"\"%@\":\"%@\",",PNLabel[i],partString];
         }
         else if (PNArray.count) [PNArray insertObject:@"" atIndex:0];
      }
   }
   return PNArray;
}

BOOL appendImmutableToCanonical(
    NSMutableDictionary *cachedQueryDict,
    NSMutableDictionary *studyRestrictionDict,
    NSMutableString *canonicalQuery,
    NSString* name,
    NSString* value
)
{
    [canonicalQuery appendFormat:@"\"%@\":\"%@\",",name,value];
    if ((cachedQueryDict[name]) && ![value hasPrefix:cachedQueryDict[name]]) return false;

    NSError *error=nil;
    [studyRestrictionDict setObject:[NSRegularExpression regularExpressionWithPattern:value options:NSRegularExpressionCaseInsensitive error:&error] forKey:name];
     if (error) LOG_WARNING(@"%@",[error debugDescription]);
    return true;
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
    regex:[NSRegularExpression regularExpressionWithPattern:@"^/(studyToken|osirix.dcmURLs|weasis.xml|dicom.zip|wadors.dicom|cornerstone.json)$" options:0 error:NULL]
    processBlock:^(RSRequest* request,RSCompletionBlock completionBlock)
    {
       completionBlock(^RSResponse* (RSRequest* request) {return [DRS studyToken:request];}(request));
    }
   ];

   [self
    addHandler:@"GET"
    regex:[NSRegularExpression regularExpressionWithPattern:@"^/(studyToken|osirix.dcmURLs|weasis.xml|dicom.zip|wadors.dicom|cornerstone.json)$" options:0 error:NULL]
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
                     @"wadors.dicom"
                  ]
                  indexOfObject:values[accessTypeIndex]
                  ];
      if (accessTypeNumber==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"studyToken accessType %@ unknown",values[accessTypeIndex]];
   }

#pragma mark cache?
   /*
    if cachedQueryDict, evalutate changes:
    case datatables/study
    -> evaluate if it is a restriction and if so, filter already existing results
    case dicomzip,cornerstone,weasis, etc
    -> should declare bad url
    */
    NSString *queryPath=nil;
    NSUInteger cacheIndex=[names indexOfObject:@"cache"];
    NSString *cachePath=nil;
   
    NSMutableDictionary *cachedQueryDict=nil;
    if (   (cacheIndex!=NSNotFound)
        && ([values[cacheIndex] length])
       )
    {
        cachePath=[DRS.tokentmpDir stringByAppendingPathComponent:values[cacheIndex]];
        NSData *cacheData=[NSData dataWithContentsOfFile:[cachePath stringByAppendingPathExtension:@"json"]];
        if (cacheData) cachedQueryDict=[NSJSONSerialization JSONObjectWithData:cacheData options:NSJSONReadingMutableContainers error:nil];
     }
    
    NSMutableString *canonicalQuery=[NSMutableString stringWithString:@"{"];
    
    NSMutableDictionary *requestDict=[NSMutableDictionary dictionaryWithObject:@"1000" forKey:@"max"];
    NSMutableDictionary *studyRestrictionDict=[NSMutableDictionary dictionary];
    NSMutableDictionary *seriesRestrictionDict=[NSMutableDictionary dictionary];

    NSInteger tokenIndex=[names indexOfObject:@"token"];
    if (tokenIndex!=NSNotFound) [requestDict setObject:values[tokenIndex] forKey:@"tokenString"];



#pragma mark institution
#pragma mark TODO revise oid vs orgaet.deviceaet
   /*
    oid => wado direct from html5dicom to pacs
    orgaet.deviceaet => wado to httpdicom proxy
    */
    NSInteger custodianIndex=[names indexOfObject:@"custodiantitle"];
    if (custodianIndex!=NSNotFound) [requestDict setObject:values[custodianIndex] forKey:@"custodiantitle"];
    NSInteger aetIndex=[names indexOfObject:@"aet"];
    if (aetIndex!=NSNotFound) [requestDict setObject:values[aetIndex] forKey:@"aet"];


   NSMutableArray *lanArray=[NSMutableArray array];
   NSMutableArray *wanArray=[NSMutableArray array];
   
   NSInteger orgIndex=[names indexOfObject:@"institution"];
   if (orgIndex==NSNotFound)
   {
      orgIndex=[names indexOfObject:@"lanPacs"];
      if (orgIndex!=NSNotFound) [lanArray addObjectsFromArray:[values[orgIndex] componentsSeparatedByString:@"|"]];
      orgIndex=[names indexOfObject:@"wanPacs"];
      if (orgIndex!=NSNotFound) [wanArray addObjectsFromArray:[values[orgIndex] componentsSeparatedByString:@"|"]];
   }
   else
   {
      [requestDict setObject:values[orgIndex] forKey:@"institutionString"];
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
                     cachedQueryDict,
                     studyRestrictionDict,
                     canonicalQuery,
                     @"StudyInstanceUID",
                     StudyInstanceUIDRegexpString
                  )) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
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
        if (!appendImmutableToCanonical(
              cachedQueryDict,
              studyRestrictionDict,
              canonicalQuery,
              @"AccessionNumber",
              AccessionNumberEqualString
           )) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
    }


   
#pragma mark 1. PatientID (Pid)
    NSString *PatientIDLikeString=nil;
    NSInteger PatientIDIndex=[names indexOfObject:@"PatientID"];
    if (PatientIDIndex!=NSNotFound)
    {
       PatientIDLikeString=[values[PatientIDIndex] sqlLikeEscapedString];
       [requestDict setObject:PatientIDLikeString forKey:@"PatientIDLikeString"];
       if (!appendImmutableToCanonical(
              cachedQueryDict,
              studyRestrictionDict,
              canonicalQuery,
              @"PatientID",
              PatientIDLikeString
           )) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
    }
   
#pragma mark 2. PatientName (Ppn)
   
   NSUInteger patientIndex[5];
   patientIndex[0]=[names indexOfObject:@"patientFamily"];
   patientIndex[1]=[names indexOfObject:@"patientGiven"];
   patientIndex[2]=[names indexOfObject:@"patientMiddle"];
   patientIndex[3]=[names indexOfObject:@"patientPrefix"];
   patientIndex[4]=[names indexOfObject:@"patientSuffix"];
   NSMutableArray *patientArray=buildPNArray(
     names,
     values,
     [names indexOfObject:@"PatientName"],
     patientIndex,
     @[@"patientFamily",@"patientGiven",@"patientMiddle",@"patientPrefix",@"patientSuffix"],
     cachedQueryDict,
     studyRestrictionDict,
     canonicalQuery
   );
   if (!patientArray) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
   if (patientArray.count) [requestDict setObject:patientArray forKey:@"patientArray"];


#pragma mark 3. StudyID (Eid)
    
    NSRegularExpression *StudyIDRestrictionRegex=nil;
    NSString *StudyIDLikeString=nil;
    NSInteger StudyIDIndex=[names indexOfObject:@"StudyID"];
    if (StudyIDIndex!=NSNotFound)
    {
       StudyIDLikeString=[values[StudyIDIndex] sqlLikeEscapedString];
       [requestDict setObject:StudyIDLikeString forKey:@"StudyIDLikeString"];

       if (!appendImmutableToCanonical(
             cachedQueryDict,
             studyRestrictionDict,
             canonicalQuery,
             @"StudyID",
             StudyIDLikeString
          )) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
       
       StudyIDRestrictionRegex=[NSRegularExpression regularExpressionWithPattern:StudyIDLikeString options:NSRegularExpressionCaseInsensitive error:&error];

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
        if (![StudyDateString isEqualToString:cachedQueryDict[@"StudyDate"]])
        {
            NSArray *cacheComponents=[cachedQueryDict[@"StudyDate"] componentsSeparatedByString:@"|"];
            if (cacheComponents.count==1) //on
            {
                if ((StudyDateComponents.count==2) || ![cacheComponents[0] isEqualToString:StudyDateString]) [cachedQueryDict removeAllObjects];
            }
            else
            {
                //check start
                if ([cacheComponents[0] length] && ([StudyDateComponents[0] compare:cacheComponents[0]]==NSOrderedAscending))[cachedQueryDict removeAllObjects];
                
                //check end
                if ([cacheComponents[1] length] && ([StudyDateComponents.lastObject compare:cacheComponents[1]]==NSOrderedDescending)) [cachedQueryDict removeAllObjects];
                if (cachedQueryDict.count)
                {
                   if ([cacheComponents[1] length]) [studyRestrictionDict setObject:[StudyDateString stringByAppendingString:@" 23:59"] forKey:@"StudyDate"];
                    else [studyRestrictionDict setObject:StudyDateString forKey:@"StudyDate"];
                }
            }
        
         }
    }

 
#pragma mark 5. StudyDescription (Elo)
   NSRegularExpression *StudyDescriptionRestrictionRegex=nil;
   NSString *StudyDescriptionRegexpString=nil;
   NSInteger StudyDescriptionIndex=[names indexOfObject:@"StudyDescription"];
   if (StudyDescriptionIndex!=NSNotFound)
   {
       StudyDescriptionRegexpString=[values[StudyDescriptionIndex] regexQuoteEscapedString];
       [requestDict setObject:StudyDescriptionRegexpString forKey:@"StudyDescriptionRegexpString"];
       
       if (!appendImmutableToCanonical(
             cachedQueryDict,
             studyRestrictionDict,
             canonicalQuery,
             @"StudyDescription",
             StudyDescriptionRegexpString
          )) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
       StudyDescriptionRestrictionRegex=[NSRegularExpression regularExpressionWithPattern:StudyDescriptionRegexpString options:NSRegularExpressionCaseInsensitive error:&error];
    }

    
#pragma mark 6. ref

   NSUInteger refIndex[5];
   refIndex[0]=[names indexOfObject:@"refIDType"];
   refIndex[1]=[names indexOfObject:@"refID"];
   refIndex[2]=[names indexOfObject:@"refUser"];
   refIndex[3]=[names indexOfObject:@"refService"];
   refIndex[4]=[names indexOfObject:@"refInstitution"];

   NSMutableArray *refArray=buildPNArray(
     names,
     values,
     [names indexOfObject:@"ref"],
     refIndex,
     @[@"refInstitution",@"refService",@"refUser",@"refID",@"refIDType"],
     cachedQueryDict,
     studyRestrictionDict,
     canonicalQuery
   );
   if (!refArray) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
   if (refArray.count) [requestDict setObject:refArray forKey:@"refArray"];


#pragma mark 7. read

    NSUInteger readIndex[5];
    readIndex[0]=[names indexOfObject:@"readIDType"];
    readIndex[1]=[names indexOfObject:@"readID"];
    readIndex[2]=[names indexOfObject:@"readUser"];
    readIndex[3]=[names indexOfObject:@"readService"];
    readIndex[4]=[names indexOfObject:@"readInstitution"];

    NSMutableArray *readArray=buildPNArray(
      names,
      values,
      [names indexOfObject:@"read"],
      readIndex,
      @[@"readInstitution",@"readService",@"readUser",@"readID",@"readIDType"],
      cachedQueryDict,
      studyRestrictionDict,
      canonicalQuery
    );
    if (!readArray) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
    if (readArray.count) [requestDict setObject:readArray forKey:@"readArray"];

    
#pragma mark 8. SOPClassInStudyString
    
   NSInteger SOPClassInStudyIndex=[names indexOfObject:@"SOPClassInStudy"];
   if ((SOPClassInStudyIndex!=NSNotFound) && [DICMTypes isSingleUIString:values[SOPClassInStudyIndex]])
   {
           [requestDict setObject:values[SOPClassInStudyIndex] forKey:@"SOPClassInStudyRegexpString"];
           if (!appendImmutableToCanonical(
                                      cachedQueryDict,
                                      studyRestrictionDict,
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
       if (!appendImmutableToCanonical(
                                  cachedQueryDict,
                                  studyRestrictionDict,
                                  canonicalQuery,
                                  @"ModalityInStudy",
                                  values[ModalityInStudyIndex]
                                  )
           ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
   }

#pragma mark issuer
    
   NSArray *issuerArray=nil;
   NSInteger issuerIndex=[names indexOfObject:@"issuer"];
   if (issuerIndex!=NSNotFound)
   {
      if (!appendImmutableToCanonical(
                                 cachedQueryDict,
                                 studyRestrictionDict,
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
            else if ([array[0] length]<65) issuerArray=[NSArray arrayWithArray:array];
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
                                 cachedQueryDict,
                                 seriesRestrictionDict,
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
                                 cachedQueryDict,
                                 seriesRestrictionDict,
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
                                  cachedQueryDict,
                                  seriesRestrictionDict,
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
                                 cachedQueryDict,
                                 seriesRestrictionDict,
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
                                 cachedQueryDict,
                                 seriesRestrictionDict,
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
                                 cachedQueryDict,
                                 seriesRestrictionDict,
                                 canonicalQuery,
                                 @"SOPClassOff",
                                 values[SOPClassOffIndex]
                                 )
          ) return [RSErrorResponse responseWithClientError:404 message:@"bad URL"];
   }

//hasSeriesFilter?
   BOOL hasSeriesFilter=
      requestDict[@"SeriesInstanceUIDRegexString"]
   || requestDict[@"SeriesNumberRegexString"]
   || requestDict[@"SeriesDescriptionRegexString"]
   || requestDict[@"ModalityRegexString"]
   || requestDict[@"SOPClassRegexString"]
   || requestDict[@"SOPClassOffRegexString"];
   [requestDict setObject:[NSNumber numberWithBool:hasSeriesFilter] forKey:@"hasSeriesFilter"];


   
#pragma mark wan
   for (NSString *devOID in wanArray)
   {
      NSLog(@"wan %@",devOID);
      //add nodes and start corresponding processes
   }

#pragma mark no cache -> create it
   BOOL isStudyRestriction=(cachedQueryDict && cachedQueryDict.count);
   if (! isStudyRestriction)
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
   
    
#pragma mark get or create plist
    
    NSUInteger newIndex=[names indexOfObject:@"new"];
    if ((newIndex!=NSNotFound) && [values[newIndex] isEqualToString:@"true"])
    {
      [defaultManager removeItemAtPath:requestPath error:nil];
      [defaultManager createDirectoryAtPath:requestPath  withIntermediateDirectories:NO attributes:nil error:nil];
    }

   
    if (!isStudyRestriction)
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
   else
   {
      //create corresponding predicate and add it to the request dictionary
      [requestDict setObject:[NSPredicate predicateWithBlock:^BOOL(NSArray *row, NSDictionary *bindings)
      {
          //AccessionNumber
          if (studyRestrictionDict[@"AccessionNumber"] && ![studyRestrictionDict[@"AccessionNumber"] numberOfMatchesInString:row[13] options:0 range:NSMakeRange(0,[row[13] length])]) return false;
          
          //PatientID
          if (studyRestrictionDict[@"PatientID"] && ![studyRestrictionDict[@"PatientID"] numberOfMatchesInString:row[23] options:0 range:NSMakeRange(0,[row[23] length])]) return false;

          //PatientName
          if (  studyRestrictionDict[@"patientFamily"]
              ||studyRestrictionDict[@"patientGiven"]
              ||studyRestrictionDict[@"patientMiddle"]
              ||studyRestrictionDict[@"patientPrefix"]
              ||studyRestrictionDict[@"patientSuffix"]
              )
          {
             NSArray *n=[row[4] componentsSeparatedByString:@"^"];
             NSUInteger c=n.count;
             if ((c > 0) && studyRestrictionDict[@"patientFamily"] && ([n[0] length]))
             {
                if (![studyRestrictionDict[@"patientFamily"] numberOfMatchesInString:n[0] options:0 range:NSMakeRange(0,[n[0] length])]) return false;
             }
              if ((c > 1) && studyRestrictionDict[@"patientGiven"] && ([n[1] length]))
              {
                 if (![studyRestrictionDict[@"patientGiven"] numberOfMatchesInString:n[1] options:0 range:NSMakeRange(0,[n[1] length])]) return false;
              }
              if ((c > 2) && studyRestrictionDict[@"patientMiddle"] && ([n[2] length]))
              {
                 if (![studyRestrictionDict[@"patientMiddle"] numberOfMatchesInString:n[2] options:0 range:NSMakeRange(0,[n[2] length])]) return false;
              }
              if ((c > 3) && studyRestrictionDict[@"patientPrefix"] && ([n[3] length]))
              {
                 if (![studyRestrictionDict[@"patientPrefix"] numberOfMatchesInString:n[3] options:0 range:NSMakeRange(0,[n[3] length])]) return false;
              }
              if ((c > 4) && studyRestrictionDict[@"patientSuffix"] && ([n[4] length]))
              {
                 if (![studyRestrictionDict[@"patientSuffix"] numberOfMatchesInString:n[4] options:0 range:NSMakeRange(0,[n[4] length])]) return false;
              }
          }

          if (studyRestrictionDict[@"StudyDate"])
          {
             //@"%@-%@-%@|%@-%@-%@"
             NSArray *d=[studyRestrictionDict[@"StudyDate"] componentsSeparatedByString:@"|"];
             if ((d.count==1) && ![row[5] hasPrefix:d[0]]) return false;
             //two parts
             if ([d[0] length] && ([d[0] compare:row[5]]==NSOrderedDescending)) return false;
             if ([d[1] length] && [d[1] compare:[row[5] substringToIndex:10]]==NSOrderedAscending) return false;
          }
               
          if (studyRestrictionDict[@"ModalityInStudy"] && ![studyRestrictionDict[@"ModalityInStudy"] numberOfMatchesInString:row[6] options:0 range:NSMakeRange(0,[row[6] length])]) return false;
         
          if (studyRestrictionDict[@"StudyDescription"] && ![studyRestrictionDict[@"StudyDescription"] numberOfMatchesInString:row[7] options:0 range:NSMakeRange(0,[row[7] length])]) return false;
         
          if (studyRestrictionDict[@"StudyID"] && ![studyRestrictionDict[@"StudyID"] numberOfMatchesInString:row[15] options:0 range:NSMakeRange(0,[row[15] length])]) return false;

          return true;
      }] forKey:@"studyPredicate"];
       
      NSMutableString *predicateString=[NSMutableString string];
      for (NSString *key in [studyRestrictionDict allKeys])
      {
          if ([key isEqualToString:@"StudyDate"])
              [predicateString appendFormat:@"%@:'%@' ",key,studyRestrictionDict[key]];
          else
              [predicateString appendFormat:@"%@:'%@' ",key,[studyRestrictionDict[key] pattern]];
      }
      LOG_VERBOSE(@"%@",predicateString);
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
                 if ([lanArray indexOfObject:[resultFile stringByDeletingPathExtension]]!=NSNotFound)
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
                 if ([lanArray indexOfObject:[resultFile stringByDeletingPathExtension]]!=NSNotFound)
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
      {
         NSMutableArray *seriesPaths=[NSMutableArray array];
         for (NSString *devOID in lanArray)
         {
            [requestDict setObject:devOID forKey:@"devOID"];
            [requestDict setObject:[[queryPath stringByAppendingPathComponent:devOID]stringByAppendingPathExtension:@"plist"] forKey:@"devOIDPLISTPath"];
             [requestDict setObject:(DRS.pacs[devOID])[@"filesystems"] forKey:@"mountPoints"];

            switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:(DRS.pacs[devOID])[@"select"]])
            {
                case selectTypeSql:
                  [DRS datateblesStudySql4dictionary:requestDict];
                  //[seriesPaths addObjectsFromArray:[DRS dicomzipSql4d:requestDict]];
                  [DRS addSeriesPathFor:requestDict toArray:seriesPaths];
                  break;
            }
         }

         //return [DRS dicomzipStreamForQueryPath:queryPath];
         return [DRS dicomzipStreamForSeriesPaths:seriesPaths];

         /*
           
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
              if ([lanArray indexOfObject:devOIDItem]!=NSNotFound)
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
         */
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

#pragma mark resultsArray
          /*
         NSData *_institution_=[@"_institution_" dataUsingEncoding:NSUTF8StringEncoding];
         NSData *_cache_=[@"_cache_" dataUsingEncoding:NSUTF8StringEncoding];
         NSData *_cache_replace=[[queryPath lastPathComponent] dataUsingEncoding:NSUTF8StringEncoding];
           */
         NSMutableArray *resultsArray=[NSMutableArray array];
          
         NSArray *resultsDirectory=[defaultManager contentsOfDirectoryAtPath:queryPath error:nil];
         for (NSString *resultFile in resultsDirectory)
         {
            if ([[resultFile pathExtension] isEqualToString:@"plist"])
            {
                if ([lanArray indexOfObject:[resultFile stringByDeletingPathExtension]]!=NSNotFound)
                {
                   NSArray *partialArray=[NSArray arrayWithContentsOfFile:[queryPath stringByAppendingPathComponent:resultFile]];
                   if ((partialArray.count==1) && [partialArray[0] isKindOfClass:[NSNumber class]])
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
         
#pragma mark isStudyRestriction
        if (isStudyRestriction)
        {
            [resultsArray filterUsingPredicate:requestDict[@"studyPredicate"]];
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
