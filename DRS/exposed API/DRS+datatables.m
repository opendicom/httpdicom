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
   /*
    is a new query to datatables study
    */
    
    NSRegularExpression *dtpatientRegex = [NSRegularExpression regularExpressionWithPattern:@"/datatables/patient" options:0 error:NULL];

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
       
       //check validity of cache
       NSUInteger cacheIndex=[names indexOfObject:@"cache"];
       NSUInteger institutionIndex=[names indexOfObject:@"institution"];
       if (
              (cacheIndex!=NSNotFound)
           && (institutionIndex!=NSNotFound)
           && [[NSFileManager defaultManager]
               fileExistsAtPath:
               [[[DRS.tokentmpDir
                  stringByAppendingPathComponent:values[cacheIndex]]
                 stringByAppendingPathComponent:values[institutionIndex]]
                stringByAppendingPathExtension:@"plist"]
               isDirectory:false
               ]
           )
       {
          NSLog(@"%@",[names description]);
          NSLog(@"%@",[values description]);

          //remove filters
          
          //add filters
          
          
          
          return [DRS
                studyTokenSocket:request.socketNumber
                requestURL:request.URL
                requestPath:@"/datatables"
                names:names
                values:values
                acceptsGzip:request.acceptsGzipContentEncoding
                ];
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


-(void)addDatatablesSeriesHandler
{
   /*output data for each series
    
   @[
   @"",
   @"SeriesInstanceUID",
   @"SeriesNumber",
   @"Modality",
   @"SeriesDate",
   @"SeriesTime",
   @"SeriesDescription",
   @"institiution",//pacs OID
   @"StudyInstanceUID"
   ];
    */
   
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
       NSUInteger institutionIndex=[names indexOfObject:@"institution"];
       NSDictionary *devDict=DRS.pacs[values[institutionIndex]];
       NSUInteger EUIDIndex=[names indexOfObject:@"StudyInstanceUID"];
       NSUInteger EKeyIndex=[names indexOfObject:@"EKey"];

       
       if (
              (cacheIndex!=NSNotFound)
           && (institutionIndex!=NSNotFound)
           && (institutionIndex!=NSNotFound)
           && (EUIDIndex!=NSNotFound)
           && (EKeyIndex!=NSNotFound)
           && [[NSFileManager defaultManager]
               fileExistsAtPath:
               [[[DRS.tokentmpDir
                  stringByAppendingPathComponent:values[cacheIndex]]
                 stringByAppendingPathComponent:values[institutionIndex]]
                stringByAppendingPathExtension:@"plist"]
               isDirectory:false
               ]
           )
       {
           switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:devDict[@"select"]])
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
                   
                    //sql init
                    NSDictionary *sqlcredentials=@{devDict[@"sqlcredentials"]:devDict[@"sqlpassword"]};
                    NSString *sqlprolog=devDict[@"sqlprolog"];
                    NSDictionary *sqlDictionary=DRS.sqls[devDict[@"sqlmap"]];

                    //find the series belonging to the key
                    NSMutableData *seriesData=[NSMutableData data];
                    if (execUTF8Bash(sqlcredentials,
                                      [NSString stringWithFormat:
                                       sqlDictionary[@"S"],
                                       sqlprolog,
                                       values[EKeyIndex],
                                       @"",
                                       sqlRecordThirteenUnits
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
                           /*
                            0    series.pk
                            1    series.series_iuid
                            2    series.series_desc
                            3    series.series_no
                            4    series.modality
                            5    series.institution
                            6    series.department
                            7    series.station_name
                            8    series.performingPhysician
                            9    series.laterality
                            10   num_instances
                            11   ssp_start_date
                            12   ssp_start_time
                            */
                           [seriesArray addObject:
                            @[
                               @"",
                               seriesSqlProperties[1],
                               seriesSqlProperties[3],
                               seriesSqlProperties[4],
                               seriesSqlProperties[11],
                               seriesSqlProperties[12],
                               seriesSqlProperties[2],
                               values[institutionIndex],
                               values[EKeyIndex]
                            ]
                            ];
                        }
                        
                        //finalize the response

                        NSMutableDictionary *resp = [NSMutableDictionary dictionary];
                        NSUInteger drawIndex=[names indexOfObject:@"draw"];
                        if (drawIndex!=NSNotFound)[resp setObject:values[drawIndex] forKey:@"draw"];
                        NSNumber *count=[NSNumber numberWithUnsignedInteger:seriesArray.count];
                        [resp setObject:count forKey:@"recordsTotal"];
                        [resp setObject:seriesArray forKey:@"data"];

                        NSLog(@"%@",[resp description]);

                        return [RSDataResponse responseWithData:
                                [NSJSONSerialization
                                 dataWithJSONObject:resp
                                 options:0
                                 error:nil
                                ]
                                contentType:@"application/dicom+json"
                                ];
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
