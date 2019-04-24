#import "RequestXMLMetadata.h"
#import "NSMutableURLRequest+DRS.h"

@implementation RequestXMLMetadata


+(NSMutableURLRequest*)requestFromPacs:(NSDictionary*)pacs
                      StudyInstanceUID:(NSString*)euid
{
   if (   !pacs
       || !euid || ![euid length]
       )
   {
      NSLog(@"pacs + StudyInstanceUID required");
      return nil;
   }
   
   NSMutableString *URLString=[NSMutableString stringWithFormat:@"%@/studies/%@/metadata", pacs[@"wadors"], euid];
   
      return [NSMutableURLRequest
              DRSRequestPacs:pacs
              URLString:URLString
              method:GET
              accept:@"multipart/related;type=\"application/dicom+xml\""
              ];
}


+(NSMutableURLRequest*)requestFromPacs:(NSDictionary*)pacs
                      StudyInstanceUID:(NSString*)euid
                     SeriesInstanceUID:(NSString*)suid
{
   if (   !pacs
       || !euid || ![euid length]
       || !suid || ![suid length]
       )
   {
      NSLog(@"pacs + StudyInstanceUID + SeriesInstanceUID required");
      return nil;
   }
   
   NSMutableString *URLString=[NSMutableString stringWithFormat:@"%@/studies/%@/series/%@/metadata",
                               pacs[@"wadors"],
                               euid,
                               suid
                               ];
   
   return [NSMutableURLRequest
           DRSRequestPacs:pacs
           URLString:URLString
           method:GET 
           accept:@"multipart/related;type=\"application/dicom+xml\""
           ];
}


+(NSMutableURLRequest*)requestFromPacs:(NSDictionary*)pacs
                      StudyInstanceUID:(NSString*)euid
                     SeriesInstanceUID:(NSString*)suid
                        SOPInstanceUID:(NSString*)iuid
{
   if (   !pacs
       || !euid || ![euid length]
       || !suid || ![suid length]
       || !iuid || ![iuid length]
       )
   {
      NSLog(@"pacs + StudyInstanceUID + SeriesInstanceUID + SOPInstanceUID required");
      return nil;
   }
   
   NSMutableString *URLString=[NSMutableString stringWithFormat:@"%@/studies/%@/series/%@/instances/%@/metadata",
                               pacs[@"wadors"],
                               euid,
                               suid,
                               iuid
                               ];
   
   return [NSMutableURLRequest
           DRSRequestPacs:pacs
           URLString:URLString
           method:GET
           accept:@"multipart/related;type=\"application/dicom+xml\""
           ];
}


@end
