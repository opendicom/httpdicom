#import "DRS+datatables.h"
#import "DRS+studyToken.h"

@implementation DRS (datatables)

/*
http://192.168.1.102:11114/datatablesstudy?StudyDate=2020-01-10&PatientID=31847350
 */



-(void)addDatatablesStudiesHandler
{
#pragma mark init
   NSArray *studyBeforeColumnsNames=@[
   @"callback",
   @"draw"
   ];
   
   NSArray *studyColumnNames=@[
   @"_0",
   @"_1",
   @"_2",
   @"PatientID",//Documento
   @"PatientName",//Nombre
   @"Fecha",
   @"Modalidades",
   @"StudyDescription",//Descripción
   @"ReferringPhysicianName",
   @"PatientInsurancePlanCodeSequence",
   @"IssuerOfPatientID",
   @"PatientBirthDate",
   @"PatientSex",
   @"AccessionNumber",
   @"IssuerOfAccessionNumber",
   @"StudyID",
   @"StudyInstanceUID",
   @"StudyTime",
   @"InstitutionName"
   ];

   NSArray *studyAfterColumnsNames=@[
   @"start",
   @"length",
   @"searchValue",
   @"searchRegex",
   @"date_start",
   @"date_end",
   @"username",
   @"useroid",
   @"session",
   @"custodiantitle",
   @"aet",
   @"role",
   @"max",
   @"new",
   @"_"
   ];
   enum namedColumnEnum{
      startColumn,
      lengthColumn,
      searchValueColumn,
      searchRegexColumn,
      date_startColumn,
      date_endColumn,
      usernameColumn,
      useroidColumn,
      sessionColumn,
      custodiantitleColumn,
      aetColumn,
      roleColumn,
      maxColumn,
      newColumn,
      _Column
   };

   NSArray *roles=@[
   @"Paciente",
   @"Radiologo",
   @"Solicitante"
   ];
   enum rolesEnum{
      rolPatient,
      rolReading,
      rolRefering
   };
   
   NSRegularExpression *dtstudiesRegex = [NSRegularExpression regularExpressionWithPattern:@"/datatables/studies" options:0 error:NULL];

[self addHandler:@"GET" regex:dtstudiesRegex processBlock:
 ^(RSRequest* request, RSCompletionBlock completionBlock){completionBlock(^RSResponse* (RSRequest* request)
   {
#pragma mark - parsing URL
    NSString *datatablesQueryPart=[request.URL.absoluteString componentsSeparatedByString:@"/datatables/studies?"][1];

//init URLString
    NSMutableString *studyTokenURLString=
    [NSMutableString stringWithFormat:
     @"http://localhost/datatablesstudies?%@start=%@",
     [datatablesQueryPart componentsSeparatedByString:@"columns"][0],
     [datatablesQueryPart componentsSeparatedByString:@"&start="][1]];

//init queryItems
    NSArray *datatablesRequestItems=[datatablesQueryPart componentsSeparatedByString:@"&"];

//init names y values with callback and draw
    NSMutableArray *names=[NSMutableArray arrayWithArray:studyBeforeColumnsNames];
    NSMutableArray *values=[NSMutableArray array];
    [values addObject:[datatablesRequestItems[0] componentsSeparatedByString:@"="][1]];
    [values addObject:[datatablesRequestItems[1] componentsSeparatedByString:@"="][1]];

//add columns
    NSUInteger datatablesRequestItemsCount=datatablesRequestItems.count;
    NSUInteger afterColumn=datatablesRequestItemsCount -15;
    NSUInteger columnIndex=0;
    for (NSUInteger item=6; item < afterColumn; item+=6)
    {
      NSString *value=[datatablesRequestItems[item] componentsSeparatedByString:@"="][1];
      if (value.length > 0)
      {
         [studyTokenURLString appendFormat:@"&%@=%@",studyColumnNames[columnIndex],value];
         [names addObject:studyColumnNames[columnIndex]];
         [values addObject:value];
      }
      columnIndex+=1;
    }
    columnIndex=values.count;
    
//init names y values with queryItems after columns
    [names addObjectsFromArray:studyAfterColumnsNames];
    for (NSUInteger i=afterColumn; i<datatablesRequestItemsCount;i++)
    {
       [values addObject:[datatablesRequestItems[i] componentsSeparatedByString:@"="][1]];
    }
    
    
#pragma mark - filters
    
#pragma mark · AccessionNumber
    NSString *accessionNumberFilter=[datatablesRequestItems[afterColumn+searchValueColumn] componentsSeparatedByString:@"="][1];
    if (accessionNumberFilter.length > 0)
    {
        [names addObject:@"AccessionNumber"];
        [values addObject:accessionNumberFilter];
    }
    else
    {
#pragma mark · StudyDate
       NSString *dateStartFilter=values[columnIndex+date_startColumn];
       NSString *dateEndFilter=values[columnIndex+date_endColumn];
       if ( (dateStartFilter.length == 8) || (dateEndFilter.length == 8))
       {
          [names addObject:@"StudyDate"];
          
          if (dateStartFilter.length > 0)
          {
             if (dateEndFilter.length == 8)
             {
                if ([dateStartFilter isEqualToString:dateEndFilter])
                {
                   //this day
                   [values
                    addObject:
                    [NSString stringWithFormat:@"%@-%@-%@",
                     [dateStartFilter substringToIndex:4],
                     [dateStartFilter substringWithRange:NSMakeRange(4,2)],
                     [dateStartFilter substringFromIndex:6]
                     ]
                    ];

                }
                else
                {
                   //between
                   [values
                    addObject:
                    [NSString stringWithFormat:@"%@-%@-%@|%@-%@-%@",
                     [dateStartFilter substringToIndex:4],
                     [dateStartFilter substringWithRange:NSMakeRange(4,2)],
                     [dateStartFilter substringFromIndex:6],
                     [dateEndFilter substringToIndex:4],
                     [dateEndFilter substringWithRange:NSMakeRange(4,2)],
                     [dateEndFilter substringFromIndex:6]
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
                  [dateStartFilter substringToIndex:4],
                  [dateStartFilter substringWithRange:NSMakeRange(4,2)],
                  [dateStartFilter substringFromIndex:6]
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
               [dateEndFilter substringToIndex:4],
               [dateEndFilter substringWithRange:NSMakeRange(4,2)],
               [dateEndFilter substringFromIndex:6]
               ]
              ];
          }
       }
    }



#pragma mark adding name/value : institution, modality, rol
    [names addObject:@"institution"];
    NSString *custodiantitle=values[columnIndex+custodiantitleColumn];
    NSString *aet=values[columnIndex+aetColumn];
    NSString *institutionOID=(DRS.pacs[[custodiantitle stringByAppendingPathExtension:aet]])[@"pacsoid"];
    [values addObject:institutionOID];

    //@"ModalityInStudy",//Modalidades (may not have been copied to values. This is why we look for it in datatablesRequestItems)
    NSString *modality=nil;
    NSUInteger modalidadesIndex=[names indexOfObject:@"modalidades"];
    if ((modalidadesIndex != NSNotFound) && ![names[modalidadesIndex] isEqualToString:@"ALL"])
    {
       modality=names[modalidadesIndex];
       [names addObject:@"ModalityInStudy"];
       [values addObject:modality];
    }

    // rol
    // also applies to StudyInstanceUID and AccessionNumber
    switch ([roles indexOfObject:values[columnIndex+roleColumn]])
    {
          
          
       case rolPatient:
       {
          NSUInteger patientIDIndex=[names indexOfObject:@"PatientID"];
          NSUInteger usernameIndex=[names indexOfObject:@"username"];
          if (patientIDIndex)
             [
              values
              replaceObjectAtIndex:patientIDIndex
              withObject:values[usernameIndex]
              ];
          else
          {
             [names addObject:@"PatientID"];
             [values addObject:values[usernameIndex]];
          }

          NSUInteger useroidIndex=[names indexOfObject:@"useroid"];
          if ([values[useroidIndex] length])
          {
             NSUInteger patientIDIssuerIndex=[names indexOfObject:@"PatientIDIssuer"];

             if (patientIDIssuerIndex)
                [
                 values
                 replaceObjectAtIndex:patientIDIssuerIndex
                 withObject:values[useroidIndex]
                 ];
             else
             {
                [names addObject:@"PatientIDIssuer"];
                [values addObject:values[useroidIndex]];
             }
          }
       }

          
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
          [values addObject:values[columnIndex+usernameColumn]];
          if ([values[columnIndex+useroidColumn] length]>0)
          {
             [names addObject:@"readID"];
             [values addObject:values[columnIndex+useroidColumn]];
          }
          //[names addObject:@"readIDType"];
          //[values addObject:];
       } break;
              
              
       case rolRefering:
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
          [values addObject:values[columnIndex+usernameColumn]];
          if ([values[columnIndex+useroidColumn] length]>0)
          {
             [names addObject:@"refID"];
             [values addObject:values[columnIndex+useroidColumn]];
          }
          //[names addObject:@"refIDType"];
          //[values addObject:];
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

#pragma mark - for errors
/*for errors
return [RSDataResponse responseWithData:[NSData jsonpCallback:q[@"callback"] forDraw:q[@"draw"] withErrorString:@"query without required 'session' parameter"] contentType:@"application/dicom+json"];
*/

/*
 recordsTotal=[countString intValue];
 int maxCount=[q[@"max"]intValue];
             LOG_INFO(@"total:%d, max:%d",recordsTotal,maxCount);
             if (recordsTotal > maxCount) return [RSDataResponse responseWithData:[NSData jsonpCallback:q[@"callback"] forDraw:q[@"draw"] withErrorString:[NSString stringWithFormat:@"you need a narrower filter. The browser table accepts up to %d matches. %d matches were found",maxCount, recordsTotal]] contentType:@"application/dicom+json"];
*/
#pragma mark empty response
/*
 
 
 
 
    return [RSDataResponse
                                        responseWithData:[NSData jsonpCallback:q[@"callback"]withDictionary:@{
                                                                                                              @"draw":q[@"draw"],
                                                                                                              @"recordsTotal":@0,
                                                                                                              @"recordsFiltered":@0,
                                                                                                              @"data":@[]
                                                                                                              }]
                                        contentType:@"application/dicom+json"
                                        ];
 
 */
#pragma mark block predicate
 /*            //https://developer.apple.com/reference/foundation/nsmutablearray/1412085-filterusingpredicate?language=objc
             
                     
                     //create compound predicate
                     NSPredicate *compoundPredicate = [NSPredicate predicateWithBlock:^BOOL(NSArray *row, NSDictionary *bindings) {
                         if (PatientIDRegex)
                         {
                             //LOG_INFO(@"patientID filter");
                             if (![PatientIDRegex numberOfMatchesInString:row[3] options:0 range:NSMakeRange(0,[row[3] length])]) return false;
                         }
                         if (PatientNameRegex)
                         {
                             //LOG_INFO(@"patientName filter");
                             if (![PatientNameRegex numberOfMatchesInString:row[4] options:0 range:NSMakeRange(0,[row[4] length])]) return false;
                         }
                         if (until)
                         {
                             //LOG_INFO(@"until filter");
                             if ([until compare:row[5]]==NSOrderedDescending) return false;
                         }
                         if (since)
                         {
                             //LOG_INFO(@"since filter");
                             if ([since compare:row[5]]==NSOrderedAscending) return false;
                         }
                         //row[6] contains modalitiesInStudies. Ej: CT\OT
                         if (![row[6] containsString:modalitySelected]) return false;
                         
                         if (StudyDescriptionRegex)
                         {
                             //LOG_INFO(@"description filter");
                             if (![StudyDescriptionRegex numberOfMatchesInString:row[7] options:0 range:NSMakeRange(0,[row[7] length])]) return false;
                         }
                         return true;
                     }];
                     
                     [Filtered[session] filterUsingPredicate:compoundPredicate];
                 }
             }
         }
  
  */
#pragma mark --order
    /*
         if (q[@"order[0][column]"] && q[@"order[0][dir]"])
         {
             LOG_INFO(@"ordering with %@, %@",q[@"order[0][column]"],q[@"order[0][dir]"]);
             
             int column=[q[@"order[0][column]"]intValue];
             if ([q[@"order[0][dir]"]isEqualToString:@"desc"])
             {
                 [Filtered[session] sortWithOptions:0 usingComparator:^NSComparisonResult(id obj1, id obj2) {
                     return [obj2[column] caseInsensitiveCompare:obj1[column]];
                 }];
             }
             else
             {
                 [Filtered[session] sortWithOptions:0 usingComparator:^NSComparisonResult(id obj1, id obj2) {
                     return [obj1[column] caseInsensitiveCompare:obj2[column]];
                 }];
             }
         }
  */
#pragma mark --response
 /*
         NSMutableDictionary *resp = [NSMutableDictionary dictionary];
         NSUInteger recordsFiltered=[Filtered[session]count];
         [resp setObject:q[@"draw"] forKey:@"draw"];
         [resp setObject:[NSNumber numberWithInt:recordsTotal] forKey:@"recordsTotal"];
         [resp setObject:[NSNumber numberWithUnsignedInteger:recordsFiltered] forKey:@"recordsFiltered"];
         
         if (!recordsFiltered)  return [RSDataResponse
                                        responseWithData:[NSData jsonpCallback:q[@"callback"]withDictionary:@{@"draw":q[@"draw"],@"recordsTotal":@0,@"recordsFiltered":@0,@"data":@[]}]
                                        contentType:@"application/dicom+json"
                                        ];
         else
         {
             //start y length
             long ps=[q[@"start"]intValue];
             long pl=[q[@"length"]intValue];
             //LOG_INFO(@"paging desired (start=[%ld],filas=[%ld],last=[%lu])",ps,pl,recordsFiltered-1);
             if (ps < 0) ps=0;
             if (ps > recordsFiltered-1) ps=0;
             if (ps+pl+1 > recordsFiltered) pl=recordsFiltered-ps;
             //LOG_INFO(@"paging applied (start=[%ld],filas=[%ld],last=[%lu])",ps,pl,recordsFiltered-1);
             NSArray *page=[Filtered[session] subarrayWithRange:NSMakeRange(ps,pl)];
             if (!page)page=@[];
             [resp setObject:page forKey:@"data"];
         }
 */
#pragma mark response jsonp
/*
         return [RSDataResponse
                 responseWithData:[NSData jsonpCallback:q[@"callback"]withDictionary:resp]
                 contentType:@"application/dicom+json"
                 ];
     }
(request));}];
}
*/

#pragma mark - Patient
/*
-(void)addDatatablesPatientHandler
{

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
      return nil;
   }
(request));}];
}

@end
