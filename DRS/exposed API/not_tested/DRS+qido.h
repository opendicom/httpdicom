//
//  DRS+qido.h
//  httpdicom
//
//  Created by jacquesfauquex on 20180119.
//  Copyright © 2018 opendicom.com. All rights reserved.
//

/*
 Syntax
 
 /patients?|studies?|/series?|/instances? (added patient, like in dcm4chee-arc)
 
 A
 &pacs={HomeCommunityID, attribute DICOM (0040,E031) | RepositoryUniqueID, attribute DICOM (0040,E030)}
 if not present... trying with any locally declared pacs
 
 B
 &includefield=all (default)
 &includefield=attributeID (may be repeated any times, triggers restricted list of field included in the response (study, series and instance uid are added automatically, in order to deduplicate)
 
 C
 orderby=attributeID (optional, allowed only once) added to includefield if not already there
 
 D,E
 &offset and &limit (used for pagination of the results. If not defined, default values apply)

 F
 filters
 -----
 Nota:
 - studies/{oid}/series?
 - studies/{oid}/series/{oid}/instances?
 are transformed to the base request with additional parameters

 X-Result-Count is used in the header of the response to indicate the total of answer found
 */

#import "DRS.h"

@interface DRS (qido)

-(void)addQidoHandler;
-(NSUInteger)countSqlProlog:(NSString*)prolog from:(NSString*)from leftjoin:(NSString*)leftjoin where:(NSString*)where;

//-----------------------------------------------

#pragma mark wado application/dicom (default handler)

//http://dicom.nema.org/medical/dicom/current/output/chtml/part18/sect_6.2.html
//http://dicom.nema.org/medical/dicom/current/output/chtml/part18/sect_6.3.html

//does support transitive (to other PCS) operation
//does support distributive (to inner pacs) operation
//does not support response consolidation (wado uri always return one object only)


// /wado
//?requestType=WADO
//&contentType=application/dicom
//&studyUID={studyUID}
//&seriesUID={seriesUID}
//&objectUID={objectUID}

//&pacs={pacsOID} (added, optional)

//alternative processing:
//(a) proxy custodian
//(b) local entity wado
//(c) local entity sql, filesystem
//(d) not available
#pragma mark wadouri
/*
 NSRegularExpression *wadouriRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\/" options:NSRegularExpressionCaseInsensitive error:NULL];
 [httpdicomServer addHandler:@"GET" regex:wadouriRegex processBlock:
 ^(RSRequest* request, RSCompletionBlock completionBlock){completionBlock(^RSResponse* (RSRequest* request)
 {
 NSURLComponents *urlComponents=[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
 
 //valid params syntax?
 NSString *wadoDicomQueryItemsError=[urlComponents wadoDicomQueryItemsError];
 if (wadoDicomQueryItemsError)
 {
 LOG_DEBUG(@"[any] Path: %@",urlComponents.path);
 LOG_DEBUG(@"[any] Query: %@",urlComponents.query);
 LOG_DEBUG(@"[any] Content-Type:\"%@\"",request.contentType);
 LOG_DEBUG(@"[any] Body: %@",[request.data description]);
 return [RSErrorResponse responseWithClientError:404 message:@"[any]<br/> unkwnown path y/o query:<br/>%@?%@",urlComponents.path,urlComponents.query];
 }
 
 NSString *pacsUID=[urlComponents firstQueryItemNamed:@"pacs"];
 
 // (a) ningún pacs especificado
 #pragma mark TODO reemplazar la lógica con qidos para encontrar el pacs, tanto local como remotamente. Se podría ordenar los qido por proximidad.... sql,qido,custodian
 
 if (!pacsUID)
 {
 LOG_VERBOSE(@"[wado] no param named \"pacs\" in: %@",urlComponents.query);
 
 //Find wado in any of the local device (recursive)
 for (NSString *oid in localOIDs)
 {
 NSData *wadoResp=[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://127.0.0.1:%lld/%@?%@&pacs=%@", port, urlComponents.path, urlComponents.query, oid]]];
 if (wadoResp && [wadoResp length] > 512) return [RSDataResponse responseWithData:wadoResp contentType:@"application/dicom"];
 }
 return [RSErrorResponse responseWithClientError:404 message:@"[wado] not found locally: %@",urlComponents.query];
 }
 
 //(a) pacs?
 NSDictionary *pacs=pacs[pacsUID];
 if (!pacs) return [RSErrorResponse responseWithClientError:404 message:@"[wado] pacs %@ not known]",pacsUID];
 
 
 //(b) sql+filesystem?
 NSString *filesystembaseuri=pacs[@"filesystembaseuri"];
 NSString *sqlobjectmodel=pacs[@"sqlobjectmodel"];
 if ([filesystembaseuri length] && [sqlobjectmodel length])
 {
 #pragma mark TODO wado simulated by sql+filesystem
 return [RSErrorResponse responseWithClientError:404 message:@"%@ [wado] not available]",urlComponents.path];
 }
 
 
 //(c) wadolocaluri?
 if ([pacs[@"wadolocaluri"] length])
 {
 NSString *uriString=[NSString stringWithFormat:@"%@?%@",
 pacs[@"wadolocaluri"],
 [urlComponents queryWithoutItemNamed:@"pacs"]
 ];
 LOG_VERBOSE(@"[wado] proxying localmente to:\r\n%@",uriString);
 
 
 NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:uriString]];
 [request setValue:@"application/dicom" forHTTPHeaderField:@"Accept"];
 //application/dicom+json not accepted !!!!!
 
 __block dispatch_semaphore_t __urlProxySemaphore = dispatch_semaphore_create(0);
 __block NSURLResponse *__response;
 __block NSError *__error;
 __block NSDate *__date;
 __block unsigned long __chunks=0;
 __block NSData *__data;//block including __data get passed to completion handler of async response
 
 NSURLSessionDataTask * const dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
 {
 __data=data;
 __response=response;
 __error=error;
 dispatch_semaphore_signal(__urlProxySemaphore);
 }];
 __date=[NSDate date];
 [dataTask resume];
 dispatch_semaphore_wait(__urlProxySemaphore, DISPATCH_TIME_FOREVER);
 //completionHandler of dataTask executed only once and before returning
 
 
 return [RSStreamedResponse responseWithContentType:@"application/dicom" asyncStreamBlock:^(RSBodyReaderCompletionBlock completionBlock)
 {
 if (__error) completionBlock(nil,__error);
 if (__chunks)
 {
 completionBlock([NSData data], nil);
 LOG_DEBUG(@"urlProxy: %lu chunk in %fs for:\r\n%@",__chunks,[[NSDate date] timeIntervalSinceDate:__date],[__response description]);
 }
 else
 {
 
 completionBlock(__data, nil);
 __chunks++;
 }
 }];
 }
 
 #pragma mark TODO (d) DICOM c-get
 
 #pragma mark TODO (e) DICOM c-move
 
 //(f) global?
 if ([pacs[@"custodianglobaluri"] length])
 {
 NSString *uriString=[NSString stringWithFormat:@"%@?%@",
 pacs[@"custodianglobaluri"],
 [urlComponents query]
 ];
 LOG_VERBOSE(@"[wado] proxying to another custodian:\r\n%@",uriString);
 NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:uriString]];
 [request setValue:@"application/dicom" forHTTPHeaderField:@"Accept"];
 //application/dicom+json not accepted !!!!!
 
 __block dispatch_semaphore_t __urlProxySemaphore = dispatch_semaphore_create(0);
 __block NSURLResponse *__response;
 __block NSError *__error;
 __block NSDate *__date;
 __block unsigned long __chunks=0;
 __block NSData *__data;
 
 NSURLSessionDataTask * const dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
 {
 __data=data;
 __response=response;
 __error=error;
 dispatch_semaphore_signal(__urlProxySemaphore);
 }];
 __date=[NSDate date];
 [dataTask resume];
 dispatch_semaphore_wait(__urlProxySemaphore, DISPATCH_TIME_FOREVER);
 //completionHandler of dataTask executed only once and before returning
 
 
 return [RSStreamedResponse responseWithContentType:@"application/dicom" asyncStreamBlock:^(RSBodyReaderCompletionBlock completionBlock)
 {
 if (__error) completionBlock(nil,__error);
 if (__chunks)
 {
 completionBlock([NSData data], nil);
 LOG_DEBUG(@"urlProxy: %lu chunk in %fs for:\r\n%@",__chunks,[[NSDate date] timeIntervalSinceDate:__date],[__response description]);
 }
 else
 {
 
 completionBlock(__data, nil);
 __chunks++;
 }
 }];
 }
 
 
 //(g) not available
 LOG_DEBUG(@"%@",[[urlComponents queryItems]description]);
 return [RSErrorResponse responseWithClientError:404 message:@"[wado] pacs %@ not available",pacsUID];
 
 }(request));}];
 */

@end




//-----------------------------------------------


#pragma mark QIDO
// /(studies|series|instances)
// &pacs={oid}
/*
NSRegularExpression *qidoRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\/(studies|series|instances)$" options:NSRegularExpressionCaseInsensitive error:NULL];
[httpdicomServer addHandler:@"GET" regex:qidoRegex processBlock:
 ^(RSRequest* request, RSCompletionBlock completionBlock){completionBlock(^RSResponse* (RSRequest* request)
                                                                          {
                                                                              //use it to tag DEBUG logs
                                                                              LOG_DEBUG(@"[qido] client: %@",request.remoteAddressString);
                                                                              
                                                                              NSURLComponents *urlComponents=[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
                                                                              
                                                                              if ([urlComponents.queryItems count] < 1)
                                                                                  return [RSErrorResponse responseWithClientError:404
                                                                                                                          message:@"[qido] requires at least one filter in: %@",[request.URL absoluteString]];
                                                                              
                                                                              //valid params syntax?
                                                                              //NSString *qidoQueryItemsError=[urlComponents qidoQueryItemsError:(*)];
                                                                              //if (qidoQueryItemsError) return [RSErrorResponse responseWithClientError:404 message:@"[qido] query item %@ error in: %@",qidoQueryItemsError,urlComponents.query];
                                                                              
                                                                              //param pacs
                                                                              NSString *pacs=[urlComponents firstQueryItemNamed:@"pacs"];
                                                                              
                                                                              // (a) any local pacs
                                                                              if (!pacs)
                                                                              {
                                                                                  LOG_VERBOSE(@"[qido] no param named \"pacs\" in: %@",urlComponents.query);
                                                                                  //Find qido in any of the local device (recursive)
                                                                                  for (NSString *oid in localOIDs)
                                                                                  {
#pragma mark TODO wado any local
                                                                                  }
                                                                                  
                                                                              }
                                                                              
                                                                              //find entityDict
                                                                              NSDictionary *entityDict=pacs[pacs];
                                                                              if (!entityDict) return [RSErrorResponse responseWithClientError:404 message:@"[qido] pacs %@ not known]",pacs];
                                                                              
                                                                              
                                                                              
                                                                              //(b) sql available
                                                                              NSDictionary *sqlobjectmodel=sql[entityDict[@"sqlobjectmodel"]];
                                                                              if (sqlobjectmodel)
                                                                              {
                                                                                  //create where
                                                                                  NSUInteger level=[qidoLastPathComponent indexOfObject:urlComponents.path];
                                                                                  NSMutableString *whereString = [NSMutableString string];
                                                                                  switch (level) {
                                                                                      case 1:
                                                                                          [whereString appendFormat:@" %@ ",(sqlobjectmodel[@"where"])[@"study"]];
                                                                                          break;
                                                                                      case 2:
                                                                                          [whereString appendFormat:@" %@ ",(sqlobjectmodel[@"where"])[@"series"]];
                                                                                          break;
                                                                                      case 3:
                                                                                          [whereString appendFormat:@" %@ ",(sqlobjectmodel[@"where"])[@"instance"]];
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
                                                                                                            fieldString:(sqlobjectmodel[@"attribute"])[key]
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
                                                                                                    (sqlobjectmodel[@"attribute"])[key]
                                                                                                    sqlFilterWithStart:startEnd[0]
                                                                                                    end:startEnd[0]
                                                                                                    ]
                                                                                                   ];
                                                                                                  break;
                                                                                              case 2:;
                                                                                                  [whereString appendString:
                                                                                                   [
                                                                                                    (sqlobjectmodel[@"attribute"])[key]
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
                                                                                              [select appendFormat:@"%@,",(sqlobjectmodel[@"attribute"])[key]];
                                                                                          }
                                                                                          [select deleteCharactersInRange:NSMakeRange([select length]-1,1)];
                                                                                          sqlScriptString=[NSString stringWithFormat:@"%@%@%@%@%@",
                                                                                                           entityDict[@"sqlprolog"],
                                                                                                           select,
                                                                                                           (sqlobjectmodel[@"from"])[@"studypatient"],
                                                                                                           whereString,
                                                                                                           qido[@"studyformat"]
                                                                                                           ];
                                                                                          break;
                                                                                      case 2:;
                                                                                          for (NSString* key in qido[@"seriesselect"])
                                                                                          {
                                                                                              [select appendFormat:@"%@,",(sqlobjectmodel[@"attribute"])[key]];
                                                                                          }
                                                                                          [select deleteCharactersInRange:NSMakeRange([select length]-1,1)];
                                                                                          
                                                                                          sqlScriptString=[NSString stringWithFormat:@"%@%@%@%@%@",
                                                                                                           entityDict[@"sqlprolog"],
                                                                                                           select,
                                                                                                           (sqlobjectmodel[@"from"])[@"seriesstudypatient"],
                                                                                                           whereString,
                                                                                                           qido[@"seriesformat"]
                                                                                                           ];
                                                                                          break;
                                                                                      case 3:;
                                                                                          for (NSString* key in qido[@"instanceselect"])
                                                                                          {
                                                                                              [select appendFormat:@"%@,",(sqlobjectmodel[@"attribute"])[key]];
                                                                                          }
                                                                                          [select deleteCharactersInRange:NSMakeRange([select length]-1,1)];
                                                                                          sqlScriptString=[NSString stringWithFormat:@"%@%@%@%@%@",
                                                                                                           entityDict[@"sqlprolog"],
                                                                                                           select,
                                                                                                           (sqlobjectmodel[@"from"])[@"instansceseriesstudypatient"],
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
                                                                                  if ([mutableData length]<10) return [RSDataResponse responseWithData:emptymatchRoot contentType:@"application/json"];
                                                                                  
                                                                                  //db response may be in latin1
                                                                                  NSStringEncoding charset=(NSStringEncoding)[entityDict[@"sqlstringencoding"] longLongValue ];
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
                                                                              if ([entityDict[@"qidolocaluri"] length])
                                                                              {
                                                                                  NSString *qidolocaluriLevel=[entityDict[@"qidolocaluri"] stringByAppendingString:urlComponents.path];
                                                                              }
                                                                              */
                                                                              
                                                                              
                                                                              /*
                                                                               NSString *qidoLocalString=entityDict[@"qidolocaluri"];
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
                                                                               if ([entityDict[@"custodianglobaluri"] length])
                                                                               {
                                                                               #pragma mark TODO qido global proxying
                                                                               
                                                                               }
                                                                               
                                                                               
                                                                               //(e) not available
                                                                               return [RSErrorResponse responseWithClientError:404 message:@"[qido] pacs %@ not available",pacs];
                                                                               
                                                                               }(request));}];
                                                                               */
                                                                              
