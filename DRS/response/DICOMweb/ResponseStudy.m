#import "ResponseStudy.h"
#import "RequestStudy.h"
#import "ODLog.h"

@implementation ResponseStudy

+(NSArray*)existsInPacs:(NSDictionary*)pacs
        accessionNumber:(NSString*)accessionNumber
        accessionIssuer:(NSString*)accessionIssuer
          accessionType:(NSString*)accessionType
       returnAttributes:(BOOL)returnAttributes
{
   if (!accessionNumber || ![accessionNumber length])
   {
      LOG_WARNING(@"no accession number");
      return nil;
   }
   
   NSMutableURLRequest *request=[RequestStudy
                                 existsInPacs:pacs
                                 accessionNumber:accessionNumber
                                 accessionIssuer:accessionIssuer
                                 accessionType:accessionType
                                 returnAttributes:returnAttributes
                                 ];

   NSHTTPURLResponse *response=nil;
   NSError *error=nil;
   NSData *responseData=[NSURLSessionDataTask sendSynchronousRequest:request returningResponse:&response error:&error];

   
   if ((returnAttributes==false) && [pacs[@"headavailable"] boolValue])
   {
      if (response.statusCode==200) return @{};//exists
      else return nil;//doesn't exist
   }
   else
   {
      if (response.statusCode==200)
      {
         if (![responseData length])
         {
            LOG_WARNING(@"[NSURLSessionDataTask+DRS] GETAccessionNumber empty response");
            return nil;
         }
         NSArray *arrayOfDicts=[NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
         if (error)
         {
            LOG_WARNING(@"badly formed json answer: %@", [error description]);
            return nil;
         }
         if ([arrayOfDicts count]==0) return nil;
         if ([arrayOfDicts count]!=1)
         {
            LOG_WARNING(@"more than one study identified by an:%@ issuerLocal:%@ issuerUniversal:%@ issuerType:%@", an, issuerLocal, issuerUniversal, issuerType);
            return nil;
         }
         return arrayOfDicts[0];
      }
      LOG_WARNING(@"%ld",response.statusCode);
      if (error) LOG_ERROR(@"[%@",[error description]);
   }
   return nil;
}

+(NSArray*)existsInPacs:(NSDictionary*)pacs
               studyUID:(NSString*)studyUID
              seriesUID:(NSString*)seriesUID
                 sopUID:(NSString*)sopUID
       returnAttributes:(BOOL)returnAttributes
{
   NSMutableURLRequest *request=[RequestStudy
                                 existsInPacs:pacs
                                 studyUID:studyUID
                                 seriesUID:seriesUID
                                 sopUID:sopUID
                                 returnAttributes:returnAttributes
                                 ];
   NSHTTPURLResponse *response=nil;
   NSError *error=nil;
   NSData *responseData=[NSURLSessionDataTask sendSynchronousRequest:request returningResponse:&response error:&error];

   
   if ((returnAttributes==false) && [pacs[@"headavailable"] boolValue])
   {
      if (response.statusCode==200) return @[];//exists
      else return nil;//doesn't exist
   }
   else
   {
     if (response.statusCode==200)
      {
         if (![responseData length])
         {
            LOG_WARNING(@"[NSURLSessionDataTask+DRS] GET qido empty response");
            return nil;
         }
         NSArray *arrayOfDicts=[NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
         if (error)
         {
            LOG_WARNING(@"[NSURLSessionDataTask+DRS] GET qido badly formed json answer: %@", [error description]);
            return nil;
         }
         if ([arrayOfDicts count]==0) return nil;
         return arrayOfDicts;
      }
      LOG_WARNING(@"[NSURLSessionDataTask+DRS] GET wado %ld",response.statusCode);
      if (error) LOG_ERROR(@"[NSURLSessionDataTask+DRS] GET wado error:\r\n%@",[error description]);
   }
   return nil;
}

@end
