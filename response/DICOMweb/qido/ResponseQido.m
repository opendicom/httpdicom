#import "ResponseQido.h"

#import "NSArray+PCS.h"

@implementation ResponseQido

+(NSArray*)foundInPacs:(NSDictionary*)pacs
             URLString:(NSMutableString*)URLString
         fuzzymatching:(BOOL)fuzzymatching
                 limit:(unsigned int)limit
                offset:(unsigned int)offset
                accept:(qidoAccept)accept
{
   return nil;
}


+(NSArray*)foundInPacs:(NSDictionary*)pacs
             URLString:(NSMutableString*)URLString
{
   return nil;
}

+(NSArray*)studiesFoundInPacs:(NSDictionary*)pacs
              accessionNumber:(NSString*)accessionNumber
              accessionIssuer:(NSString*)accessionIssuer
                accessionType:(NSString*)accessionType
{
   NSMutableURLRequest *request=[RequestQido
                                 studiesFoundInPacs:pacs
                                 accessionNumber:accessionNumber
                                 accessionIssuer:accessionIssuer
                                 accessionType:accessionType
                                 ];
   if (request==nil) return nil;

   NSHTTPURLResponse *response=nil;
   NSError *error=nil;
   NSData *responseData=[NSURLSessionDataTask sendSynchronousRequest:request returningResponse:&response error:&error];
   
   //expected
   if (response.statusCode==200) return [NSArray arrayWithJsonData:responseData];   
   //unexpected
   NSLog(@"%@\r\n%ld ResponseQido srtudiesFoundInPacs:accessionNumber:%@ ",pacs, response.statusCode,accessionNumber );//warning
   if (error) NSLog(@"%@",[error description]);

   return nil;
}


+(NSArray*)objectsFoundInPacs:(NSDictionary*)pacs
                     studyUID:(NSString*)studyUID
                    seriesUID:(NSString*)seriesUID
                       sopUID:(NSString*)sopUID
{
   NSMutableURLRequest *request=[RequestQido
                                 objectsFoundInPacs:pacs
                                 studyUID:studyUID
                                 seriesUID:seriesUID
                                 sopUID:sopUID
                                 ];
   if (request==nil) return nil;
   
   NSHTTPURLResponse *response=nil;
   NSError *error=nil;
   NSData *responseData=[NSURLSessionDataTask sendSynchronousRequest:request returningResponse:&response error:&error];
   
   //expected
   if (response.statusCode==200) return [NSArray arrayWithJsonData:responseData];
   //unexpected
   NSLog(@"<-%ld (NO studiesFoundInPacs:studyUID:%@)", response.statusCode,studyUID );//warning
   if (error) NSLog(@"%@",[error description]);//error
   
   return nil;
}

@end
