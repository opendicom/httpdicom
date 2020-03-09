#import "DRS+datatables.h"
#import "DRS+studyToken.h"
#import "DRS+datatablesStudy.h"

@implementation DRS (datatables)

/*
http://192.168.1.102:11114/datatablesstudy?StudyDate=2020-01-10&PatientID=31847350
 */



-(void)addDatatablesStudiesHandler
{
#pragma mark init
    NSArray *roles=@[
   @"Paciente",
   @"Radiologo",
   @"Solicitante",
   @"Medico",
   @"Autrenticador"
   ];
   enum rolesEnum{
      rolPatient,
      rolReading,
      rolReferring,
      rolLocalPhysician,
      rolAuthenticator
   };
   
   NSRegularExpression *dtstudiesRegex = [NSRegularExpression regularExpressionWithPattern:@"/datatables/studies" options:0 error:NULL];

[self addHandler:@"GET" regex:dtstudiesRegex processBlock:
 ^(RSRequest* request, RSCompletionBlock completionBlock){completionBlock(^RSResponse* (RSRequest* request)
   {
#pragma mark - parsing URL
     NSString *datatablesQueryPart=[request.URL.absoluteString componentsSeparatedByString:@"/datatables/studies?"][1];

     NSMutableArray *names=[NSMutableArray array];
     NSMutableArray *values=[NSMutableArray array];
     NSArray *datatablesRequestItems=[datatablesQueryPart componentsSeparatedByString:@"&"];
    
     for (NSString *param in datatablesRequestItems)
     {
         NSArray *nameValue=[param componentsSeparatedByString:@"="];
         if ([nameValue[1] length])
         {
             [names addObject:nameValue[0]];
             [values addObject:nameValue[1]];
         }
     }

     NSUInteger date_startIndex=[names indexOfObject:@"date_start"];
     NSUInteger date_endIndex=  [names indexOfObject:@"date_end"];
     BOOL hasDate_start=(date_startIndex != NSNotFound);
     BOOL hasDate_end=(date_endIndex != NSNotFound);

     if ( hasDate_start || hasDate_end)
     {
          [names addObject:@"StudyDate"];
          
          if (hasDate_start)
          {
             if (hasDate_end)
             {
                if ([values[date_startIndex] isEqualToString:values[date_endIndex]])
                {
                   //this day
                   [values
                    addObject:
                    [NSString stringWithFormat:@"%@-%@-%@",
                     [values[date_startIndex] substringToIndex:4],
                     [values[date_startIndex] substringWithRange:NSMakeRange(4,2)],
                     [values[date_startIndex] substringFromIndex:6]
                     ]
                    ];

                }
                else
                {
                   //between
                   [values
                    addObject:
                    [NSString stringWithFormat:@"%@-%@-%@|%@-%@-%@",
                     [values[date_startIndex] substringToIndex:4],
                     [values[date_startIndex] substringWithRange:NSMakeRange(4,2)],
                     [values[date_startIndex] substringFromIndex:6],
                     [values[date_endIndex] substringToIndex:4],
                     [values[date_endIndex] substringWithRange:NSMakeRange(4,2)],
                     [values[date_endIndex] substringFromIndex:6]
                     ]
                    ];
                }
             }
             else
             {
                //since
                [values
                 addObject:
                 [NSString stringWithFormat:@"%@-%@-%@|",
                  [values[date_startIndex] substringToIndex:4],
                  [values[date_startIndex] substringWithRange:NSMakeRange(4,2)],
                  [values[date_startIndex] substringFromIndex:6]
                  ]
                 ];
             }
          }
          else
          {
             //until
             [values
              addObject:
              [NSString stringWithFormat:@"|%@-%@-%@",
               [values[date_endIndex] substringToIndex:4],
               [values[date_endIndex] substringWithRange:NSMakeRange(4,2)],
               [values[date_endIndex] substringFromIndex:6]
               ]
              ];
          }
       }


#pragma mark adding name/value : institution, modality, rol
    [names addObject:@"institution"];
    NSString *custodiantitle=values[[names indexOfObject:@"custodiantitle"]];
    NSString *aet=values[[names indexOfObject:@"aet"]];
    NSString *institutionOID=(DRS.pacs[[custodiantitle stringByAppendingPathExtension:aet]])[@"pacsoid"];
    [values addObject:institutionOID];

     
    NSString *modality=nil;
    NSUInteger modalitiesIndex=[names indexOfObject:@"Modalities"];
    if ((modalitiesIndex != NSNotFound) && ![names[modalitiesIndex] isEqualToString:@"ALL"])
    {
       modality=names[modalitiesIndex];
       [names addObject:@"ModalityInStudy"];
       [values addObject:modality];
    }

    // rol
    // also applies to StudyInstanceUID and AccessionNumber
    switch ([roles indexOfObject:values[[names indexOfObject:@"role"]]])
    {
          
          
       case rolPatient:
       {
          NSUInteger patientIDIndex=[names indexOfObject:@"PatientID"];
          NSUInteger usernameIndex=[names indexOfObject:@"username"];
          if (patientIDIndex==NSNotFound)
          {
             [names addObject:@"PatientID"];
             [values addObject:values[usernameIndex]];
          }
       } break;


          
       case rolReading:
       {
          if (institutionOID.length)
          {
             [names addObject:@"readInstitution"];
             [values addObject:institutionOID];
          }
           
          if (modality.length)
          {
             [names addObject:@"readService"];
             [values addObject:modality];
          }
           
          [names addObject:@"readUser"];
          [values addObject:values[[names indexOfObject:@"username"]]];
           
           NSUInteger useroidIndex=[names indexOfObject:@"useroid"];
          if (useroidIndex != NSNotFound)
          {
             [names addObject:@"readID"];
             [values addObject:values[useroidIndex]];
          }
           
          //[names addObject:@"readIDType"];
          //[values addObject:];
           
       } break;
              
              
       case rolReferring:
       {
          if (institutionOID.length)
          {
             [names addObject:@"refInstitution"];
             [values addObject:institutionOID];
          }
           
          if (modality.length)
          {
             [names addObject:@"refService"];
             [values addObject:modality];
          }
           
          [names addObject:@"refUser"];
          [values addObject:values[[names indexOfObject:@"username"]]];
           
           NSUInteger useroidIndex=[names indexOfObject:@"useroid"];
          if (useroidIndex != NSNotFound)
          {
             [names addObject:@"refID"];
             [values addObject:values[useroidIndex]];
          }
           
          //[names addObject:@"readIDType"];
          //[values addObject:];
       } break;
            
        case rolLocalPhysician:
        {
        } break;

                
        case rolAuthenticator:
        {
        } break;

    }
    
    
    return [DRS
            studyTokenSocket:request.socketNumber
            requestURL:request.URL
            requestPath:request.path
            names:names
            values:values
            acceptsGzip:request.acceptsGzipContentEncoding
            ];
         }
    (request));}];
    }



-(void)addDatatablesPatientHandler
{
    NSArray *patientColumnNames=@[
    @"_0",
    @"_1",
    @"",//Serie #
    @"",//Modalidad
    @"",//Fecha
    @"",//Hora
    @""//Descripción
    ];
    
    NSRegularExpression *dtpatientRegex = [NSRegularExpression regularExpressionWithPattern:@"/datatables/series" options:0 error:NULL];

    [self addHandler:@"GET" regex:dtpatientRegex processBlock:
    ^(RSRequest* request, RSCompletionBlock completionBlock){completionBlock(^RSResponse* (RSRequest* request)
    {

           NSString *datatablesQueryPart=[request.URL.absoluteString componentsSeparatedByString:@"/datatables/patient?"][1];

           NSMutableArray *names=[NSMutableArray array];
           NSMutableArray *values=[NSMutableArray array];
           NSArray *datatablesRequestItems=[datatablesQueryPart componentsSeparatedByString:@"&"];
          
           for (NSString *param in datatablesRequestItems)
           {
               NSArray *nameValue=[param componentsSeparatedByString:@"="];
               if ([nameValue[1] length])
               {
                   [names addObject:nameValue[0]];
                   [values addObject:nameValue[1]];
               }
           }
           NSUInteger cacheIndex=[names indexOfObject:@"cache"];
           NSUInteger pacsIndex=[names indexOfObject:@"pacs"];
           
           if (
                  (cacheIndex!=NSNotFound)
               && (pacsIndex!=NSNotFound)
               && [[NSFileManager defaultManager]
                   fileExistsAtPath:
                   [[[DRS.tokentmpDir
                      stringByAppendingPathComponent:values[cacheIndex]]
                     stringByAppendingPathComponent:values[pacsIndex]]
                    stringByAppendingPathExtension:@"array"]
                   isDirectory:false
                   ]
               )
           {
               //find studies for this patient in all the available pacs
               
               switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:(DRS.pacs[names[pacsIndex]])[@"select"]])
               {
                   case selectTypeSql:
                   {
                       //find E (study key) from record pointed at by URL thanks to DEUID or AN+ANIssuerUID
                       /*
                        13 DEAN, AccessionNumber
                        14 DEANIssuerUID, IssuerOfAccessionNumber.UniversalEntityID
                           DEID,
                        16 DEUID,StudyInstanceUID
                           DEDateTime2,
                           DEInstitution,
                           DEPKey,
                        20 DEEKey,
                        */
                       

                       
                       NSUInteger EKeyIndex=[names indexOfObject:@"EKey"];
                       if (EKeyIndex!=NSNotFound)
                       {
                           //sql init
                           NSDictionary *devDict=DRS.pacs[values[pacsIndex]];
                           NSDictionary *sqlcredentials=@{devDict[@"sqlcredentials"]:devDict[@"sqlpassword"]};
                           NSString *sqlprolog=devDict[@"sqlprolog"];
                           NSDictionary *sqlDictionary=DRS.sqls[devDict[@"sqlmap"]];

                           //find the series belonging to the key
                           NSMutableData *seriesData=[NSMutableData data];
                           if (execUTF8Bash(sqlcredentials,
                                             [NSString stringWithFormat:
                                              sqlDictionary[@"S"],
                                              sqlprolog,
                                              [values[EKeyIndex] stringValue],
                                              @"",
                                              sqlRecordElevenUnits
                                              ],
                                             seriesData)
                               !=0) LOG_ERROR(@"datatables/series  db error");
                           else
                           {
                               NSArray *seriesSqlPropertiesArray=[seriesData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:3 decreasing:NO];//NSUTF8StringEncoding
                               
                               //init the response
                               
                               //loop the series
                               NSMutableArray *seriesArray=[NSMutableArray array];
                               for (NSArray *seriesSqlProperties in seriesSqlPropertiesArray)
                               {
                                   NSLog(@"");
                               }
                               
                               //finalize the response

                               NSMutableDictionary *resp = [NSMutableDictionary dictionary];
                               NSUInteger drawIndex=[names indexOfObject:@"draw"];
                               if (drawIndex)[resp setObject:values[drawIndex] forKey:@"draw"];
                               NSNumber *count=[NSNumber numberWithUnsignedInteger:seriesArray.count];
                               [resp setObject:count forKey:@"recordsTotal"];
                               [resp setObject:seriesArray forKey:@"data"];

                               return [RSDataResponse responseWithData:
                                       [NSJSONSerialization
                                        dataWithJSONObject:resp
                                        options:0
                                        error:nil
                                       ]
                                       contentType:@"application/dicom+json"
                                       ];
                            }

                        }
                   } break;
               }
           }
           return [RSDataResponse responseWithData:
                   [NSJSONSerialization
                    dataWithJSONObject:
                    @{
                     @"draw":values[[names indexOfObject:@"draw"]],
                     @"recordsTotal":@0,
                     @"data":@[],
                     @"error":@"bad URL"
                    }
                    options:0
                    error:nil
                   ]
                   contentType:@"application/dicom+json"
                   ];
       }
    (request));}];
    }
/*
//ventana emergente con todos los estudios del paciente
//"datatables/patient
//PatientID=33333333&IssuerOfPatientID.UniversalEntityID=NULL&session=1"

NSRegularExpression *dtpatientRegex = [NSRegularExpression regularExpressionWithPattern:@"/datatables/patient" options:0 error:NULL];
[self addHandler:@"GET" regex:dtpatientRegex processBlock:
 ^(RSRequest* request, RSCompletionBlock completionBlock){completionBlock(^RSResponse* (RSRequest* request)
     {
         LOG_DEBUG(@"client: %@",request.remoteAddressString);
         NSURLComponents *urlComponents=[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
         //NSArray *pComponents=[urlComponents.path componentsSeparatedByString:@"/"];
         
         
         NSDictionary *q=request.query;
         
         NSString *session=q[@"session"];
         if (!session || [session isEqualToString:@""]) return [RSDataResponse responseWithData:[NSData jsonpCallback:q[@"callback"] forDraw:q[@"draw"] withErrorString:@"query without required 'session' parameter"] contentType:@"application/dicom+json"];
         
         if (!q[@"PatientID"]) return [RSDataResponse responseWithData:[NSData jsonpCallback:q[@"callback"] forDraw:q[@"draw"] withErrorString:@"studies of patient query without required 'patientID' parameter"] contentType:@"application/dicom+json"];
         
         //WHERE study.rejection_state!=2    (or  1=1)
         //following filters use formats like " AND a like 'b'"
         
         //find dest
         NSString *destOID=DRS.pacs[[q[@"custodiantitle"] stringByAppendingPathExtension:q[@"aet"]]];
         NSDictionary *entityDict=DRS.pacs[destOID];
         
         NSDictionary *destSql=DRS.sqls[entityDict[@"sqlmap"]];
         if (!destSql) return [RSErrorResponse responseWithClientError:404 message:@"%@ [sql not found]",urlComponents.path];
         
         NSMutableString *studiesWhere=[NSMutableString stringWithString:destSql[@"studiesWhere"]];
         [studiesWhere appendString:
          [NSString mysqlEscapedFormat:@" AND %@ like '%@'"
                           fieldString:destSql[@"PatientID"]
                           valueString:q[@"PatientID"]
           ]
          ];
         //PEP por custodian aets
         
         //[studiesWhere appendFormat:
         //@" AND %@ in ('%@')",
         //destSql[@"accessControlId"],
         //[custodianTitlesaets[q[@"custodiantitle"]] componentsJoinedByString:@"','"]
         //];
         
         LOG_INFO(@"WHERE %@",[studiesWhere substringFromIndex:38]);
         
         
         NSString *sqlDataQuery=[NSString stringWithFormat:@"%@%@%@%@",
                                 entityDict[@"sqlprolog"],
                                 destSql[@"datatablesStudiesProlog"],
                                 studiesWhere,
                                 [NSString stringWithFormat: destSql[@"datatablesStudiesEpilog"],session,
                                  session
                                  ]
                                 ];
         
         NSMutableArray *studiesArray=jsonMutableArray(sqlDataQuery, (NSStringEncoding) [entityDict[@"sqlstringencoding"]integerValue]);
         
         //sorted study date (5) desc
         [studiesArray sortWithOptions:0 usingComparator:^NSComparisonResult(id obj1, id obj2) {
             return [obj2[5] caseInsensitiveCompare:obj1[5]];
         }];
         
         
         NSMutableDictionary *resp = [NSMutableDictionary dictionary];
         if (q[@"draw"])[resp setObject:q[@"draw"] forKey:@"draw"];
         NSNumber *count=[NSNumber numberWithUnsignedInteger:[studiesArray count]];
         [resp setObject:count forKey:@"recordsTotal"];
         [resp setObject:count forKey:@"recordsFiltered"];
         [resp setObject:studiesArray forKey:@"data"];
         return [RSDataResponse
                 responseWithData:[NSData jsonpCallback:q[@"callback"]withDictionary:resp]
                 contentType:@"application/dicom+json"
                 ];
     }
                                                                          (request));}];
}
*/



/*
-(void)addDatatablesSeriesHandler
{
    //"datatables/series?AccessionNumber=22&IssuerOfAccessionNumber.UniversalEntityID=NULL&StudyIUID=2.16.858.2.10000675.72769.20160411084701.1.100&session=1"
NSRegularExpression *dtseriesRegex = [NSRegularExpression regularExpressionWithPattern:@"/datatables/series" options:0 error:NULL];
[self addHandler:@"GET" regex:dtseriesRegex processBlock:
 ^(RSRequest* request, RSCompletionBlock completionBlock){completionBlock(^RSResponse* (RSRequest* request)
     {
         LOG_DEBUG(@"client: %@",request.remoteAddressString);
         NSURLComponents *urlComponents=[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
         //NSArray *pComponents=[urlComponents.path componentsSeparatedByString:@"/"];
         
         
         NSDictionary *q=request.query;
         NSString *session=q[@"session"];
         if (!session || [session isEqualToString:@""]) return [RSDataResponse responseWithData:[NSData jsonpCallback:q[@"callback"] forDraw:q[@"draw"] withErrorString:@"query without required 'session' parameter"] contentType:@"application/dicom+json"];
         
         
         //find dest
         NSString *destOID=DRS.pacs[[q[@"custodiantitle"] stringByAppendingPathExtension:q[@"aet"]]];
         NSDictionary *entityDict=DRS.pacs[destOID];
         
         NSDictionary *destSql=DRS.sqls[entityDict[@"sqlmap"]];
         if (!destSql) return [RSErrorResponse responseWithClientError:404 message:@"%@ [sql not found]",urlComponents.path];
         NSString *where=nil;
         NSString *an=q[@"AccessionNumber"];
         NSString *siuid=q[@"StudyInstanceUID"];
         if (
             [entityDict[@"preferredStudyIdentificator"] isEqualToString:@"AccessionNumber"]
             && an
             && ![an isEqualToString:@"NULL"])
         {
             NSString *IssuerOfAccessionNumber=q[@"IssuerOfAccessionNumber.UniversalEntityID"];
             if (IssuerOfAccessionNumber && ![IssuerOfAccessionNumber isEqualToString:@"NULL"]) where=[NSString stringWithFormat:@"%@ AND %@='%@' AND %@='%@'", destSql[@"seriesWhere"],destSql[@"AccessionNumber"],an,destSql[@"IssuerOfAccessionNumber"],IssuerOfAccessionNumber];
             else where=[NSString stringWithFormat:@"%@ AND %@='%@'",destSql[@"seriesWhere"],destSql[@"AccessionNumber"],an];
             
         }
         else if (siuid && ![siuid isEqualToString:@"NULL"])
             where=[NSString stringWithFormat:@"%@ AND %@='%@'",destSql[@"seriesWhere"],destSql[@"StudyInstanceUID"],siuid];
         else return [RSDataResponse responseWithData:[NSData jsonpCallback:q[@"callback"] forDraw:q[@"draw"] withErrorString:@"query without required 'AccessionNumber' or 'StudyInstanceUID' parameter"] contentType:@"application/dicom+json"];
         
         
         LOG_INFO(@"WHERE %@",[where substringFromIndex:38]);
         
         NSString *sqlDataQuery=[NSString stringWithFormat:@"%@%@%@%@",
                                 entityDict[@"sqlprolog"],
                                 destSql[@"datatablesSeriesProlog"],
                                 where,
                                 [NSString stringWithFormat:
                                  destSql[@"datatablesSeriesEpilog"],
                                  session,
                                  session
                                  ]
                                 ];
         
         NSMutableArray *seriesArray=jsonMutableArray(sqlDataQuery,(NSStringEncoding) [entityDict[@"sqlstringencoding"] integerValue]);
         //LOG_INFO(@"series array:%@",[seriesArray description]);
         
         NSMutableDictionary *resp = [NSMutableDictionary dictionary];
         if (q[@"draw"])[resp setObject:q[@"draw"] forKey:@"draw"];
         NSNumber *count=[NSNumber numberWithUnsignedInteger:[seriesArray count]];
         [resp setObject:count forKey:@"recordsTotal"];
         [resp setObject:count forKey:@"recordsFiltered"];
         [resp setObject:seriesArray forKey:@"data"];
         return [RSDataResponse
                 responseWithData:[NSData jsonpCallback:q[@"callback"]withDictionary:resp]
                 contentType:@"application/dicom+json"
                 ];
     }
(request));}];
}
 */

//"datatables/series?AccessionNumber=22&IssuerOfAccessionNumber.UniversalEntityID=NULL&StudyIUID=2.16.858.2.10000675.72769.20160411084701.1.100&cache=x@pacs=1.2"
-(void)addDatatablesSeriesHandler
{
   NSArray *seriesColumnNames=@[
   @"_0",
   @"_1",
   @"",//Serie #
   @"",//Modalidad
   @"",//Fecha
   @"",//Hora
   @""//Descripción
   ];
   
   NSRegularExpression *dtseriesRegex = [NSRegularExpression regularExpressionWithPattern:@"/datatables/series" options:0 error:NULL];

   [self addHandler:@"GET" regex:dtseriesRegex processBlock:
   ^(RSRequest* request, RSCompletionBlock completionBlock){completionBlock(^RSResponse* (RSRequest* request)
   {
       NSString *datatablesQueryPart=[request.URL.absoluteString componentsSeparatedByString:@"/datatables/series?"][1];

       NSMutableArray *names=[NSMutableArray array];
       NSMutableArray *values=[NSMutableArray array];
       NSArray *datatablesRequestItems=[datatablesQueryPart componentsSeparatedByString:@"&"];
      
       for (NSString *param in datatablesRequestItems)
       {
           NSArray *nameValue=[param componentsSeparatedByString:@"="];
           if ([nameValue[1] length])
           {
               [names addObject:nameValue[0]];
               [values addObject:nameValue[1]];
           }
       }
       NSUInteger cacheIndex=[names indexOfObject:@"cache"];
       NSUInteger pacsIndex=[names indexOfObject:@"pacs"];
       
       if (
              (cacheIndex!=NSNotFound)
           && (pacsIndex!=NSNotFound)
           && [[NSFileManager defaultManager]
               fileExistsAtPath:
               [[[DRS.tokentmpDir
                  stringByAppendingPathComponent:values[cacheIndex]]
                 stringByAppendingPathComponent:values[pacsIndex]]
                stringByAppendingPathExtension:@"array"]
               isDirectory:false
               ]
           )
       {
           switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:(DRS.pacs[names[pacsIndex]])[@"select"]])
           {
               case selectTypeSql:
               {
                   //find E (study key) from record pointed at by URL thanks to DEUID or AN+ANIssuerUID
                   /*
                    13 DEAN, AccessionNumber
                    14 DEANIssuerUID, IssuerOfAccessionNumber.UniversalEntityID
                       DEID,
                    16 DEUID,StudyInstanceUID
                       DEDateTime2,
                       DEInstitution,
                       DEPKey,
                    20 DEEKey,
                    */
                   

                   
                   NSUInteger EKeyIndex=[names indexOfObject:@"EKey"];
                   if (EKeyIndex!=NSNotFound)
                   {
                       //sql init
                       NSDictionary *devDict=DRS.pacs[values[pacsIndex]];
                       NSDictionary *sqlcredentials=@{devDict[@"sqlcredentials"]:devDict[@"sqlpassword"]};
                       NSString *sqlprolog=devDict[@"sqlprolog"];
                       NSDictionary *sqlDictionary=DRS.sqls[devDict[@"sqlmap"]];

                       //find the series belonging to the key
                       NSMutableData *seriesData=[NSMutableData data];
                       if (execUTF8Bash(sqlcredentials,
                                         [NSString stringWithFormat:
                                          sqlDictionary[@"S"],
                                          sqlprolog,
                                          [values[EKeyIndex] stringValue],
                                          @"",
                                          sqlRecordElevenUnits
                                          ],
                                         seriesData)
                           !=0) LOG_ERROR(@"datatables/series  db error");
                       else
                       {
                           NSArray *seriesSqlPropertiesArray=[seriesData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:3 decreasing:NO];//NSUTF8StringEncoding
                           
                           //init the response
                           
                           //loop the series
                           NSMutableArray *seriesArray=[NSMutableArray array];
                           for (NSArray *seriesSqlProperties in seriesSqlPropertiesArray)
                           {
                               NSLog(@"");
                           }
                           
                           //finalize the response

                           NSMutableDictionary *resp = [NSMutableDictionary dictionary];
                           NSUInteger drawIndex=[names indexOfObject:@"draw"];
                           if (drawIndex)[resp setObject:values[drawIndex] forKey:@"draw"];
                           NSNumber *count=[NSNumber numberWithUnsignedInteger:seriesArray.count];
                           [resp setObject:count forKey:@"recordsTotal"];
                           [resp setObject:seriesArray forKey:@"data"];

                           return [RSDataResponse responseWithData:
                                   [NSJSONSerialization
                                    dataWithJSONObject:resp
                                    options:0
                                    error:nil
                                   ]
                                   contentType:@"application/dicom+json"
                                   ];
                        }

                    }
               } break;
           }
       }
       return [RSDataResponse responseWithData:
               [NSJSONSerialization
                dataWithJSONObject:
                @{
                 @"draw":values[[names indexOfObject:@"draw"]],
                 @"recordsTotal":@0,
                 @"data":@[],
                 @"error":@"bad URL"
                }
                options:0
                error:nil
               ]
               contentType:@"application/dicom+json"
               ];
   }
(request));}];
}

@end


//subsampling with block predicate
// //https://developer.apple.com/reference/foundation/nsmutablearray/1412085-filterusingpredicate?language=objc
// https://stackoverflow.com/questions/13767516/nspredicate-on-array-of-arrays/33779086
// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Predicates/Articles/pBNF.html#//apple_ref/doc/uid/TP40001796-217950
