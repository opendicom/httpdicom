#import "ResponseWadouri.h"
#import "ODLog.h"
#import "NSArray+PCS.h"

@implementation ResponseWadouri

+(NSData*)objectFromPacs:(NSDictionary*)pacs
                    EUID:(NSString*)euid
                    SUID:(NSString*)suid
                    IUID:(NSString*)iuid
         acceptMediaType:(NSString*)mediaType
{
   NSMutableURLRequest *request=
   [RequestWadouri
    requestMIMEFromPacs:pacs
                   EUID:euid
                   SUID:suid
                   IUID:iuid
        acceptMediaType:mediaType
   ];
   if (request==nil) return nil;
   
   NSHTTPURLResponse *response=nil;
   NSError *error=nil;
   NSData *responseData=[NSURLSessionDataTask sendSynchronousRequest:request returningResponse:&response error:&error];
   
   //expected
   if (response.statusCode==200) return responseData;

   //unexpected
   LOG_WARNING(@"<-%ld (object not found for study:%@ series:%@, sopInstance:%@)", response.statusCode,euid,suid,iuid );
   if (error) LOG_ERROR(@"%@",[error description]);
   
   return nil;
}

+(NSData*)XMLStringFromPacs:(NSDictionary*)pacs
                       EUID:(NSString*)euid
                       SUID:(NSString*)suid
                       IUID:(NSString*)iuid
{
   return [ResponseWadouri
           objectFromPacs:pacs
                     EUID:euid
                     SUID:suid
                     IUID:iuid
          acceptMediaType:@"text/xml"
           ];
}

@end
