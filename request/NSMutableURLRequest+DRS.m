#import "NSMutableURLRequest+DRS.h"

@implementation NSMutableURLRequest (DRS)

NSTimeInterval const defaultTimeout=10;

static NSData *emptyData;
static NSString *emptyString;
+(void)initialize {
   emptyData=[[NSData alloc]init];
   emptyString=[[NSString alloc]init];
}

+(NSMutableURLRequest*)DRSRequestPacs:(NSDictionary*)pacs
                            URLString:(NSMutableString*)URLString
                               method:(HTTPRequestMethod)method
                          contentType:(NSString*)contentType
                             bodyData:(NSData*)bodyData
                               accept:(NSString*)accept
{
   //WADO uses a parameter for expected accept media type
   BOOL iswadouri=[URLString containsString:@"requestType=WADO"];
   if (iswadouri && [accept length]) [URLString appendFormat:@"contentType=%@",accept];

   
   NSURLRequestCachePolicy cachepolicy;
   if ([pacs[@"cachepolicy"]length])
      cachepolicy=[pacs[@"cachepolicy"] integerValue];
   else
      cachepolicy=NSURLRequestReloadIgnoringCacheData;//1
   
   NSTimeInterval timeoutinterval;
   if ([pacs[@"timeoutinterval"]length])
      timeoutinterval=[pacs[@"timeoutinterval"] doubleValue];
   else
      timeoutinterval=defaultTimeout;
   
   //cache policy and timeout
   // https://developer.apple.com/reference/foundation/nsurlrequestcachepolicy?language=objc;
   NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString] cachePolicy:cachepolicy timeoutInterval:timeoutinterval];
   
   switch (method) {
      case GET:
         [request setHTTPMethod:@"GET"];
         break;
      case HEAD:
         [request setHTTPMethod:@"HEAD"];
         break;
      case POST:
         [request setHTTPMethod:@"POST"];
         break;
      case PUT:
         [request setHTTPMethod:@"PUT"];
         break;
      case DELETE:
         [request setHTTPMethod:@"DELETE"];
         break;
      case CONNECT:
         [request setHTTPMethod:@"CONNECT"];
         break;
      case OPTIONS:
         [request setHTTPMethod:@"OPTIONS"];
         break;
      case TRACE:
         [request setHTTPMethod:@"TRACE"];
         break;
      case PATCH:
         [request setHTTPMethod:@"PATCH"];
         break;
      default:
         return nil;
         break;
   }
   
   
   //request body
   if ([contentType length] || [bodyData length])
   {
      if ([contentType length] && [bodyData length])
      {
         [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
         [request setHTTPBody:bodyData];
      }
      else if ([contentType isEqualToString:@"application/x-www-form-urlencoded"])
      {
         [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
      }
      else if ([contentType length])
      {
         NSLog(@"content type %@ requires body",contentType);
         return nil;
      }
      else
      {
         NSLog(@"body without content type");
         return nil;
      }
   }
   
   
   if ([accept length] && !iswadouri)
   {
      [request setValue:contentType forHTTPHeaderField:@"accept"];
   }
   
   
   return request;
}



+(NSMutableURLRequest*)DRSRequestPacs:(NSDictionary*)pacs
                            URLString:(NSMutableString*)URLString
                               method:(HTTPRequestMethod)method
                          contentType:(NSString*)contentType
                             bodyData:(NSData*)bodyData
{
   return [NSMutableURLRequest DRSRequestPacs:pacs
                                    URLString:URLString
                                       method:method
                                  contentType:contentType
                                     bodyData:bodyData
                                       accept:emptyString
           ];
}

+(NSMutableURLRequest*)DRSRequestPacs:(NSDictionary*)pacs
                            URLString:(NSMutableString*)URLString
                               method:(HTTPRequestMethod)method
                               accept:(NSString*)accept
{
   return [NSMutableURLRequest DRSRequestPacs:pacs
                                    URLString:URLString
                                       method:method
                                  contentType:emptyString
                                     bodyData:emptyData
                                       accept:accept
           ];
}


+(NSMutableURLRequest*)DRSRequestPacs:(NSDictionary*)pacs
                            URLString:(NSMutableString*)URLString
                               method:(HTTPRequestMethod)method
{
   return [NSMutableURLRequest DRSRequestPacs:pacs
                                    URLString:URLString
                                       method:method
                                  contentType:emptyString
                                     bodyData:emptyData
                                       accept:emptyString
           ];
}

@end
