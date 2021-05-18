#import "DRS+wadouri.h"
#import "NSURLComponents+PCS.h"
#import "DICMTypes.h"

@implementation DRS (wadouri)

//wado application/dicom ony
-(void)addWadoHandler
{
    //route
    NSRegularExpression *wadouriRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\/" options:NSRegularExpressionCaseInsensitive error:NULL];
    
    //request and completion
    [self addHandler:@"GET" regex:wadouriRegex processBlock:
     ^(RSRequest* request, RSCompletionBlock completionBlock){completionBlock(^RSResponse* (RSRequest* request)
         {
             NSURLComponents *urlComponents=[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
             
             //valid wado url params syntax? (uses first occurrence only)
             BOOL requestType=false;
             BOOL contentType=false;
             BOOL studyUID=false;
             BOOL seriesUID=false;
             BOOL objectUID=false;

             for (NSURLQueryItem* i in urlComponents.queryItems)
             {
                 if (!requestType && [i.name isEqualToString:@"requestType"] && [i.value isEqualToString:@"WADO"]) requestType=true;
                 else if (!contentType && [i.name isEqualToString:@"contentType"]) contentType=true;
                 else if (!studyUID && [i.name isEqualToString:@"studyUID"] && [DICMTypes.UIRegex numberOfMatchesInString:i.value options:0 range:NSMakeRange(0,[i.value length])]) studyUID=true;
                 else if (!seriesUID && [i.name isEqualToString:@"seriesUID"] && [DICMTypes.UIRegex numberOfMatchesInString:i.value options:0 range:NSMakeRange(0,[i.value length])]) seriesUID=true;
                 else if (!objectUID && [i.name isEqualToString:@"objectUID"] && [DICMTypes.UIRegex numberOfMatchesInString:i.value options:0 range:NSMakeRange(0,[i.value length])]) objectUID=true;
             }

            //content type can be different
            // && [i.value isEqualToString:@"application/dicom"]
            
             if (!(requestType && contentType && studyUID && seriesUID && objectUID))
             {
                 if (contentType==false) NSLog(@"wado 'contentType' parameter not found");//warning
                 if (studyUID==false)    NSLog(@"wado 'studyUID parameter not found");//warning
                 if (seriesUID==false)   NSLog(@"wado 'seriesUID parameter not found");//warning
                 if (objectUID==false)   NSLog(@"wado 'objectUID parameter not found");//warning

                NSLog(@"wado Path: %@",urlComponents.path);//debug
                NSLog(@"wado Query: %@",urlComponents.query);//debug
                NSLog(@"wado Content-Type:\"%@\"",request.contentType);//debug
                return [RSErrorResponse responseWithClientError:404 message:@"bad wado: %@",[request.URL absoluteString]];
             }
             
             
             //additional routing parameter pacs
             NSString *pacsUID=[urlComponents firstQueryItemNamed:@"pacs"];

#pragma mark existing pacs?
             NSDictionary *pacs=DRS.pacs[pacsUID];
             if (!pacs) return [RSErrorResponse responseWithClientError:404 message:@"pacs %@ not known]",pacsUID];
             
             
             //(b) sql+filesystem?
             if (   [pacs[@"filesystembaseuri"] length]
                 && [pacs[@"select"] isEqualToString:@"sql"])
             {
#pragma mark TODO wado simulated by sql+filesystem
                 return [RSErrorResponse responseWithClientError:404 message:@"wado por sql+filesystem not available yet"];
             }
             
             
             //(c) wadouri?
             if ([pacs[@"wadouri"] length])
             {
                 NSString *uriString=[NSString stringWithFormat:@"%@?%@",
                                      pacs[@"wadouri"],
                                      [urlComponents queryWithoutItemNamed:@"pacs"]
                                      ];
                NSLog(@"wado proxying localmente to:\r\n%@",uriString);//verbose
                 
                 
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
                                 NSLog(@"urlProxy: %lu chunk in %fs for:\r\n%@",__chunks,[[NSDate date] timeIntervalSinceDate:__date],[__response description]);//debug
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
#pragma mark TODO (f) verify global

             if ([pacs[@"custodianglobaluri"] length])
             {
                 NSString *uriString=[NSString stringWithFormat:@"%@?%@",
                                      pacs[@"custodianglobaluri"],
                                      [urlComponents query]
                                      ];
                NSLog(@"[wado] proxying to another custodian:\r\n%@",uriString);//verbose
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
                                 NSLog(@"urlProxy: %lu chunk in %fs for:\r\n%@",__chunks,[[NSDate date] timeIntervalSinceDate:__date],[__response description]);//NSLog
                             }
                             else
                             {
                                 
                                 completionBlock(__data, nil);
                                 __chunks++;
                             }
                         }];
             }
             
             
             //(g) not available
            NSLog(@"%@",[[urlComponents queryItems]description]);//debug
             return [RSErrorResponse responseWithClientError:404 message:@"[wado] pacs %@ not available",pacsUID];
             
         }(request));}];

}
@end
