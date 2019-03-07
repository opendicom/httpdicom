#import "ResponsePatient.h"
#import "RequestPatient.h"
#import "ODLog.h"

@implementation ResponsePatient

+(NSArray*)existsInPacs:(NSDictionary*)pacs
                    pid:(NSString*)pid
                 issuer:(NSString*)issuer
       returnAttributes:(BOOL)returnAttributes
{
   if (!pid) return nil;//return NSMutableURLRequest echo error message

   NSMutableURLRequest *request=[RequestPatient
                                 existsInPacs:pacs
                                 pid:pid
                                 issuer:issuer
                                 returnAttributes:returnAttributes
                                 ];
   NSHTTPURLResponse *response=nil;
   NSError *error=nil;
   NSData *responseData=[NSURLSessionDataTask sendSynchronousRequest:request returningResponse:&response error:&error];

   if ((returnAttributes==false) && [pacs[@"headavailable"]boolValue])
   {
      //expected
      if (response.statusCode==200) return @[];//contents
      if (response.statusCode==204) return nil;//no content
      //unexpected
      LOG_WARNING(@"[NSURLSessionDataTask+DRS] HEADpid %ld",response.statusCode);
      if (error) LOG_ERROR(@"[NSURLSessionDataTask+DRS] HEADpid error:\r\n%@",[error description]);
      return nil;
   }

   //expected
   if (response.statusCode==200)
   {
      if (![responseData length])
      {
         LOG_WARNING(@"[NSURLSessionDataTask+DRS] GETpid empty response");
         return nil;
      }
      NSArray *arrayOfDicts=[NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
      if (error)
      {
         LOG_WARNING(@"[NSURLSessionDataTask+DRS] GETpid badly formed json answer: %@", [error description]);
         return nil;
      }
      if ([arrayOfDicts count]>1) LOG_WARNING(@"[NSURLSessionDataTask+DRS] GETAccessionNumber more than one patient identified by pid:%@ issuer:%@", pid, issuer);
      return arrayOfDicts;
   }
   //unexpected
   LOG_WARNING(@"[NSURLSessionDataTask+DRS] GETpid %ld",response.statusCode);
   if (error) LOG_ERROR(@"[NSURLSessionDataTask+DRS] GETpid error:\r\n%@",[error description]);
   return nil;
}

@end
