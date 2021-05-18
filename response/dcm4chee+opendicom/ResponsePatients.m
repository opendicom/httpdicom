#import "ResponsePatients.h"
#import "RequestPatients.h"
#import "NSArray+PCS.h"


@implementation ResponsePatients

+(NSArray*)getFromPacs:(NSDictionary*)pacs
                 patID:(NSString*)patID
                issuer:(NSString*)issuer
{

   NSMutableURLRequest *request=[RequestPatients getFromPacs:pacs patID:patID issuer:issuer];
   if (request==nil) return nil;
   
   NSHTTPURLResponse *response=nil;
   NSError *error=nil;
   NSData *responseData=[NSURLSessionDataTask sendSynchronousRequest:request returningResponse:&response error:&error];

   //expected
   if (response.statusCode==200) return [NSArray arrayWithJsonData:responseData];
   //unexpected
   NSLog(@"%@\r\n%ld ResponsePatients getFromPacs:patID:%@ issuer:%@ ",pacs, response.statusCode,patID,issuer );//warning
   if (error) NSLog(@"%@",[error description]);
   return nil;
}

+(NSString*)putToPacs:(NSDictionary*)pacs
              family1:(NSString*)family1
              family2:(NSString*)family2
                given:(NSString*)given
                patID:(NSString*)patID
               issuer:(NSString*)issuer
            birthdate:(NSString*)birthdate
                  sex:(NSString*)sex
          contentType:(NSString*)contentType
{
   NSMutableURLRequest *request=
   [RequestPatients
    putToPacs:pacs
    family1:family1
    family2:family2
    given:given
    patID:patID
    issuer:issuer
    birthdate:birthdate
    sex:sex
    contentType:contentType
   ];
   if (request==nil) return nil;
   
   NSHTTPURLResponse *HTTPURLResponse=nil;
   NSError *error=nil;
   //URL properties: expectedContentLength, MIMEType, textEncodingName
   //HTTP properties: statusCode, allHeaderFields
   NSData *responseData=[NSURLSessionDataTask sendSynchronousRequest:request returningResponse:&HTTPURLResponse error:&error];
   NSString *responseString=[[NSString alloc]initWithData:responseData encoding:NSUTF8StringEncoding];
   NSLog(@"patient putToPacs <- %ld %@",(long)HTTPURLResponse.statusCode,responseString);//verbose
   if ( error || HTTPURLResponse.statusCode>299)
   {
      NSLog(@"patient putToPacs <- %ld %@",(long)HTTPURLResponse.statusCode,[error description]);
      return [NSString stringWithFormat:@"patient putToPacs <- %ld %@",(long)HTTPURLResponse.statusCode,[error description]];
   }
   return @"";
}

@end
