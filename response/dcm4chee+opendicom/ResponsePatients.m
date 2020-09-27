#import "ResponsePatients.h"
#import "RequestPatients.h"
#import "NSArray+PCS.h"
#import "ODLog.h"

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
   LOG_WARNING(@"%@\r\n%ld ResponsePatients getFromPacs:patID:%@ issuer:%@ ",pacs, response.statusCode,patID,issuer );
   if (error) LOG_ERROR(@"%@",[error description]);
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
   LOG_VERBOSE(@"patient putToPacs <- %ld %@",(long)HTTPURLResponse.statusCode,responseString);
   if ( error || HTTPURLResponse.statusCode>299)
   {
      LOG_ERROR(@"patient putToPacs <- %ld %@",(long)HTTPURLResponse.statusCode,[error description]);
      return [NSString stringWithFormat:@"patient putToPacs <- %ld %@",(long)HTTPURLResponse.statusCode,[error description]];
   }
   return @"";
}


//returns nil if the request could not be performed
//returns @"" when the patient was registered
//returns @"error message" if the server responded with an error
/*
 Url : http://ip:puerto/accounts/api/user
 found in services1dict html5dicomuserserviceuri
 
 Content-Type : application/json
 
 Body
 {
 "institution": “IRP",
 "username": "15993195-1",
 "password": "clave",
 "first_name": "Claudio Anibal",
 "last_name": "Baeza Gonzalez",
 "is_active": “False"
 }
 
 Para la MWL “is_active" debe ser False
 Para el informe “is_active” debe ser True
 */
/*
+(NSString*)postHtml5dicomuserForPacs:(NSDictionary*)pacs
                          institution:(NSString*)institution
                             username:(NSString*)username
                             password:(NSString*)password
                            firstname:(NSString*)firstname
                             lastname:(NSString*)lastname
                             isactive:(BOOL)isactive
{
   
   if (!password || ![password length])
   {
      LOG_VERBOSE(@"no password -> no user created in html5dicom");
      return @"no password -> no user created in html5dicom";
   }
   
   NSMutableURLRequest *request=
   [RequestPatients
    postHtml5dicomuserForPacs:pacs
    institution:institution
    username:username
    password:password
    firstname:firstname
    lastname:lastname
    isactive:isactive
    ];
   if (!request) return nil;
         
   NSHTTPURLResponse *HTTPURLResponse=nil;
   NSError *error=nil;
   NSData *responseData=[NSURLSessionDataTask sendSynchronousRequest:request returningResponse:&HTTPURLResponse error:&error];
      
   //OK
   if (HTTPURLResponse.statusCode==201)
   {
      LOG_VERBOSE(@"html5user created");
      return @"";
   }
      
   //Problem
   NSString *responseString=[[NSString alloc]initWithData:responseData encoding:NSUTF8StringEncoding];
   LOG_WARNING(@"%@",responseString);
   return responseString;
}
*/
@end
