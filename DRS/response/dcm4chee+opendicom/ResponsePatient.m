#import "ResponsePatient.h"
#import "RequestPatient.h"
#import "ODLog.h"

@implementation ResponsePatient

// [] no existe
// [{}] existe y es único
// [{},{}...] existen y no son únicos

+(NSArray*)getFromPacs:(NSDictionary*)pacs
                   pid:(NSString*)pid
                issuer:(NSString*)issuer
{

   NSMutableURLRequest *request=[RequestPatient getFromPacs:pacs pid:pid issuer:issuer];
   if (request==nil) return nil;
   
   NSHTTPURLResponse *response=nil;
   NSError *error=nil;
   NSData *responseData=[NSURLSessionDataTask sendSynchronousRequest:request returningResponse:&response error:&error];

   //expected
   if (response.statusCode==200)
   {
      //case there is no corresponding patient
      if (![responseData length]) return @[];

      //other cases
      NSArray *arrayOfDicts=[NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
      if (error)
      {
         LOG_WARNING(@"JSON response is not an array:\r\n%@\r\n%@", [[NSString alloc]initWithData:responseData encoding:NSUTF8StringEncoding],[error description]);
         return nil;
      }
      return arrayOfDicts;
   }
   
   //unexpected
   LOG_WARNING(@"%@\r\n%ld [ResponsePatient existsInPacs:(description above) pid:%@ issuer:%@ ",pacs, response.statusCode,pid,issuer );
   if (error) LOG_ERROR(@"%@",[error description]);
   return nil;
}

//returns nil if the request could not be performed
//returns @"" when the patient was registered
//returns @"error message" if the server responded with an error
+(NSString*)putToPacs:(NSDictionary*)pacs
                 name:(NSString*)name
                  pid:(NSString*)pid
               issuer:(NSString*)issuer
            birthdate:(NSString*)birthdate
                  sex:(NSString*)sex
          contentType:(NSString*)contentType
{
   NSMutableURLRequest *request=
   [RequestPatient
    putToPacs:pacs
    name:name
    pid:pid
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
+(NSString*)postHtml5dicomuserForPacs:(NSDictionary*)pacs
                          institution:(NSString*)institution
                             username:(NSString*)username
                             password:(NSString*)password
                            firstname:(NSString*)firstname
                             lastname:(NSString*)lastname
                             isactive:(BOOL)isactive
{
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
   
   if (!password || ![password length])
   {
      LOG_VERBOSE(@"no password -> no user created in html5dicom");
      return @"no password -> no user created in html5dicom";
   }
   
   NSMutableURLRequest *request=
   [RequestPatient
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

@end
