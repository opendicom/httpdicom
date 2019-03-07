#import "NSMutableURLRequest+DRS.h"

@implementation NSMutableURLRequest (DRS)

+(NSMutableURLRequest*)DRSRequestPacs:(NSDictionary*)pacs
                            URLString:(NSMutableString*)URLString
                               method:(NSString*)method
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
   
   
   [request setHTTPMethod:method];
   
   
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

@end
