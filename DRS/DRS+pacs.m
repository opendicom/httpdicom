#import "DRS+pacs.h"
#import "K.h"
#import "DICMTypes.h"

@implementation DRS (pacs)

-(void)addGETCustodiansHandler
{
    NSRegularExpression *custodiansRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\/custodians" options:0 error:NULL];
    [self addHandler:@"GET" regex:custodiansRegex processBlock:
     ^(RSRequest* request, RSCompletionBlock completionBlock)
     {completionBlock(^RSResponse* (RSRequest* request){
        
        //using NSURLComponents instead of RSRequest
        NSURLComponents *urlComponents=[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
        
        NSArray *pComponents=[urlComponents.path componentsSeparatedByString:@"/"];
        NSUInteger pCount=[pComponents count];
        if ([[pComponents lastObject]isEqualToString:@""]) pCount--;
        
        if (pCount<3) return [RSErrorResponse responseWithClientError:400 message:@"path should start with /custodians/titles or /custodians/oids"];
        
        if ([pComponents[2]isEqualToString:@"titles"])
        {
            //custodians/titles
            if (pCount==3) return [RSDataResponse responseWithData:DRS.titlesdata contentType:@"application/json"];
            
            NSUInteger p3Length = [pComponents[3] length];
            if (  (p3Length>16)
                ||![DICMTypes.SHRegex numberOfMatchesInString:pComponents[3] options:0 range:NSMakeRange(0,p3Length)])
                return [RSErrorResponse responseWithClientError:404 message:@"%@ [{title} datatype should be DICOM SH]",urlComponents.path];
            
            if (!DRS.titles[pComponents[3]])
                return [RSErrorResponse responseWithClientError:404 message:@"%@ [{title} not found]",urlComponents.path];
            
            //custodians/titles/{TITLE}
            if (pCount==4) return [RSDataResponse responseWithData:[NSJSONSerialization dataWithJSONObject:[NSArray arrayWithObject:DRS.titles[pComponents[3]]] options:0 error:nil] contentType:@"application/json"];
            
            if (![pComponents[4]isEqualToString:@"aets"])
                return [RSErrorResponse responseWithClientError:404 message:@"%@ [{title} unique resource is 'aets']",urlComponents.path];
            
            //custodians/titles/{title}/aets
            if ((pCount==5)||((pCount==6)&&![pComponents[5]length]))
                return [RSDataResponse responseWithData:[NSJSONSerialization dataWithJSONObject:[DRS.titlesaets objectForKey:pComponents[3]] options:0 error:nil] contentType:@"application/json"];
            
            NSUInteger p5Length = [pComponents[5]length];
            if (  (p5Length>16)
                ||![DICMTypes.SHRegex numberOfMatchesInString:pComponents[5] options:0 range:NSMakeRange(0,p5Length)])
                return [RSErrorResponse responseWithClientError:404 message:@"%@ [{aet}datatype should be DICOM SH]",urlComponents.path];
            
            NSUInteger aetIndex=[[DRS.titlesaets objectForKey:pComponents[3]] indexOfObject:pComponents[5]];
            if (aetIndex==NSNotFound)
                return [RSErrorResponse responseWithClientError:404 message:@"%@ [{aet} not found]",urlComponents.path];
            
            if (pCount>6) return [RSErrorResponse responseWithClientError:400 message:@"%@ [no handler]",urlComponents.path];
            
            //custodians/titles/{title}/aets/{aet}
            return [RSDataResponse responseWithData:
                    [NSJSONSerialization dataWithJSONObject:
                     [NSArray arrayWithObject:(DRS.oidsaeis[DRS.titles[pComponents[3]]])[aetIndex]]
                                                    options:0
                                                      error:nil
                     ]
                                        contentType:@"application/json"
                    ];
        }
        
        
        if ([pComponents[2]isEqualToString:@"oids"])
        {
            //custodians/oids
            if (pCount==3) return [RSDataResponse responseWithData:DRS.oidsdata contentType:@"application/json"];
            
            NSUInteger p3Length = [pComponents[3] length];
            if (  (p3Length>64)
                ||![DICMTypes.UIRegex numberOfMatchesInString:pComponents[3] options:0 range:NSMakeRange(0,p3Length)]
                )
                return [RSErrorResponse responseWithClientError:404 message:@"%@ [{OID} datatype should be DICOM UI]",urlComponents.path];
            
            if (!DRS.oids[pComponents[3]])
                return [RSErrorResponse responseWithClientError:404 message:@"%@ [{OID} not found]",urlComponents.path];
            
            //custodian/oids/{OID}
            if (pCount==4) return [RSDataResponse responseWithData:[NSJSONSerialization dataWithJSONObject:[NSArray arrayWithObject:DRS.oids[pComponents[3]]] options:0 error:nil] contentType:@"application/json"];
            
            if (![pComponents[4]isEqualToString:@"aeis"])
                return [RSErrorResponse responseWithClientError:404 message:@"%@ [{OID} unique resource is 'aeis']",urlComponents.path];
            
            //custodian/oids/{OID}/aeis
            if ((pCount==5)||((pCount==6)&&![pComponents[5]length]))
                return [RSDataResponse responseWithData:[NSJSONSerialization dataWithJSONObject:[DRS.oidsaeis objectForKey:pComponents[3]] options:0 error:nil] contentType:@"application/json"];
            
            NSUInteger p5Length = [pComponents[5]length];
            if (  (p5Length>64)
                ||![DICMTypes.UIRegex numberOfMatchesInString:pComponents[5] options:0 range:NSMakeRange(0,p5Length)]
                )
                return [RSErrorResponse responseWithClientError:404 message:@"%@ [{aei}datatype should be DICOM UI]",urlComponents.path];
            
            NSUInteger aeiIndex=[[DRS.oidsaeis objectForKey:pComponents[3]] indexOfObject:pComponents[5]];
            if (aeiIndex==NSNotFound)
                return [RSErrorResponse responseWithClientError:404 message:@"%@ [{aei} not found]",urlComponents.path];
            
            if (pCount>6) return [RSErrorResponse responseWithClientError:400 message:@"%@ [no handler]",urlComponents.path];
            
            //custodian/oids/{OID}/aeis/{aei}
            return [RSDataResponse responseWithData:
                    [NSJSONSerialization dataWithJSONObject:
                     [NSArray arrayWithObject:(DRS.pacs[pComponents[5]])[@"dicomaet"]]
                                                    options:0
                                                      error:nil
                     ]
                                        contentType:@"application/json"
                    ];
        }
        return [RSErrorResponse responseWithClientError:404 message:@"%@ [no handler]",urlComponents.path];
        
    }(request));}];
}

-(void)addGETPacsHandler
{
   NSRegularExpression *pacsRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\/pacs" options:0 error:NULL];
   [self addHandler:@"GET" regex:pacsRegex processBlock:
    ^(RSRequest* request, RSCompletionBlock completionBlock)
    {completionBlock(^RSResponse* (RSRequest* request){
      
      //using NSURLComponents instead of RSRequest
      NSURLComponents *urlComponents=[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
      
      NSArray *pComponents=[urlComponents.path componentsSeparatedByString:@"/"];
      NSUInteger pCount=[pComponents count];
      if ([[pComponents lastObject]isEqualToString:@""]) pCount--;
      
      //  /pacs
      if (pCount==2) return [RSDataResponse responseWithData:DRS.pacskeysdata contentType:@"application/json"];
      
      //pacs/{key}
      NSDictionary *pacsproperties=DRS.pacs[pComponents[2]];
      if (!pacsproperties) return [RSErrorResponse responseWithClientError:404 message:@"%@ [unknown pacs]",pComponents[2]];
      
      if (pCount==3) return [RSDataResponse responseWithData:[NSJSONSerialization dataWithJSONObject:pacsproperties options:0 error:nil] contentType:@"application/json"];
      
      //pacs/{key}/{property}
      id pacsproperty=pacsproperties[pComponents[3]];
      if (!pacsproperty) return [RSErrorResponse responseWithClientError:404 message:@"%@ [unknown property]",pComponents[3]];
      
      if (pCount==4)
      {
         if ([pacsproperty isKindOfClass:[NSString class]])
            return [RSDataResponse responseWithData:[pacsproperty dataUsingEncoding:NSUTF8StringEncoding] contentType:@"text/plain"];
         
         if ([pacsproperty isKindOfClass:[NSNumber class]])
         {
            if ([pacsproperty boolValue]==true)
               return [RSDataResponse responseWithData:[@"true" dataUsingEncoding:NSUTF8StringEncoding] contentType:@"text/plain"];
            return [RSDataResponse responseWithData:[@"false" dataUsingEncoding:NSUTF8StringEncoding] contentType:@"text/plain"];
         }
         
         if ([pacsproperty isKindOfClass:[NSDictionary class]])
         {
            return [RSDataResponse responseWithData:[NSJSONSerialization dataWithJSONObject:pacsproperty options:0 error:nil] contentType:@"application/json"];
         }
      }

      return [RSErrorResponse responseWithClientError:404 message:@"%@ [no handler]",urlComponents.path];
      
   }(request));}];
}

-(void)addGETSqlsHandler
{
   NSRegularExpression *sqlsRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\/sqls" options:0 error:NULL];
   [self addHandler:@"GET" regex:sqlsRegex processBlock:
    ^(RSRequest* request, RSCompletionBlock completionBlock)
    {completionBlock(^RSResponse* (RSRequest* request){
      
      //using NSURLComponents instead of RSRequest
      NSURLComponents *urlComponents=[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
      
      NSArray *pComponents=[urlComponents.path componentsSeparatedByString:@"/"];
      NSUInteger pCount=[pComponents count];
      if ([[pComponents lastObject]isEqualToString:@""]) pCount--;
      
      //  /sqls
      if (pCount==2) return [RSDataResponse responseWithData:[NSJSONSerialization dataWithJSONObject:[DRS.sqls allKeys] options:0 error:nil] contentType:@"application/json"];
      
      //pacs/{key}
      NSDictionary *sqlproperties=DRS.sqls[pComponents[2]];
      if (!sqlproperties) return [RSErrorResponse responseWithClientError:404 message:@"%@ [unknown sql]",pComponents[2]];
      
      if (pCount==3) return [RSDataResponse responseWithData:[NSJSONSerialization dataWithJSONObject:sqlproperties options:0 error:nil] contentType:@"application/json"];
      
      //pacs/{key}/{property}
      id sqlproperty=sqlproperties[pComponents[3]];
      if (!sqlproperty) return [RSErrorResponse responseWithClientError:404 message:@"%@ [unknown property]",pComponents[3]];
      
      if (pCount==4)
      {
         if ([sqlproperty isKindOfClass:[NSString class]])
            return [RSDataResponse responseWithData:[sqlproperty dataUsingEncoding:NSUTF8StringEncoding] contentType:@"text/plain"];
         
         if ([sqlproperty isKindOfClass:[NSNumber class]])
         {
            if ([sqlproperty boolValue]==true)
               return [RSDataResponse responseWithData:[@"true" dataUsingEncoding:NSUTF8StringEncoding] contentType:@"text/plain"];
            return [RSDataResponse responseWithData:[@"false" dataUsingEncoding:NSUTF8StringEncoding] contentType:@"text/plain"];
         }
         
         if ([sqlproperty isKindOfClass:[NSDictionary class]])
         {
            return [RSDataResponse responseWithData:[NSJSONSerialization dataWithJSONObject:sqlproperty options:0 error:nil] contentType:@"application/json"];
         }
      }
      
      return [RSErrorResponse responseWithClientError:404 message:@"%@ [no handler]",urlComponents.path];
      
   }(request));}];
}

@end
