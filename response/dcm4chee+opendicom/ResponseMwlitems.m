#import "ResponseMwlitems.h"
#import "RequestMwlitems.h"
#import "NSArray+PCS.h"


@implementation ResponseMwlitems

+(NSArray*)getFromPacs:(NSDictionary*)pacs
       accessionNumber:(NSString*)an
{

   NSMutableURLRequest *request=[RequestMwlitems getFromPacs:pacs accessionNumber:an];
   if (request==nil) return nil;
   
   NSHTTPURLResponse *response=nil;
   NSError *error=nil;
   NSData *responseData=[NSURLSessionDataTask sendSynchronousRequest:request returningResponse:&response error:&error];

   //expected
   if (response.statusCode==200) return [NSArray arrayWithJsonData:responseData];
   //unexpected
   NSLog(@"%@\r\n%ld ResponseMwlitems getFromPacs:accessionNumber:%@ ",pacs, response.statusCode,an );//warning
   if (error) NSLog(@"%@",[error description]);//error
   return nil;
}

@end
