#import "RequestWadouri.h"
#import "NSMutableURLRequest+DRS.h"

@implementation RequestWadouri


+(NSMutableURLRequest*)requestDICMFromPacs:(NSDictionary*)pacs
                                      EUID:(NSString*)euid
                                      SUID:(NSString*)suid
                                      IUID:(NSString*)iuid
{
   return [RequestWadouri requestDICMFromPacs:(NSDictionary*)pacs
                                         EUID:euid
                                         SUID:suid
                                         IUID:iuid
                                    anonymize:NO
                               transferSyntax:@"*"
           ];
}



+(NSMutableURLRequest*)requestDICMFromPacs:(NSDictionary*)pacs
                                      EUID:(NSString*)euid
                                      SUID:(NSString*)suid
                                      IUID:(NSString*)iuid
                                 anonymize:(BOOL)anonymize
                            transferSyntax:(NSString*)transferSyntax
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
   //&anonymize=%@&transferSyntax=%@
   NSMutableString *URLString=[NSMutableString stringWithFormat:@"%@?requestType=WADO&studyUID=%@&seriesUID=%@&objectUID=%@&contentType=application%%2Fdicom",
                               pacs[@"wadouri"],
                               euid,
                               suid,
                               iuid//,
                               //anonymize?@"yes":@"no",
                               //transferSyntax
                               ];
   
   return [NSMutableURLRequest
           DRSRequestPacs:pacs
           URLString:URLString
           method:GET
          ];
}


//-----------------------------------------------------------------------


//part 18 B.1 Simple DICOM image in JPEG
+(NSMutableURLRequest*)requestDefaultJPEGFromPacs:(NSDictionary*)pacs
                                             EUID:(NSString*)euid
                                             SUID:(NSString*)suid
                                             IUID:(NSString*)iuid
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
   
   NSMutableString *URLString=[NSMutableString stringWithFormat:@"%@?requestType=WADO&studyUID=%@&seriesUID=%@&objectUID=%@",
                               pacs[@"wadouri"],
                               euid,
                               suid,
                               iuid
                               ];
   
   return [NSMutableURLRequest
           DRSRequestPacs:pacs
           URLString:URLString
           method:GET
           ];
}


//-----------------------------------------------------------------------


/*
 mediaTypes accepted
 ===================
 
 image/jpeg (default)
 image/gif (single or multi frame)
 image/png
 image/jp2
 
 video/mpeg
 video/mp4
 video/H265
 
 text/html
 text/plain
 text/xml
 text/rtf
 
 application/pdf
 
 
 Opendicom additions for encapsulated
 ------------------------------------
 
 text/x-dscd+xml
 text/x-scd+xml
 text/x-cda+xml
 */
+(NSMutableURLRequest*)requestMIMEFromPacs:(NSDictionary*)pacs
                                      EUID:(NSString*)euid
                                      SUID:(NSString*)suid
                                      IUID:(NSString*)iuid
                           acceptMediaType:(NSString*)mediaType
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
   
   NSMutableString *URLString=[NSMutableString stringWithFormat:@"%@?requestType=WADO&studyUID=%@&seriesUID=%@&objectUID=%@&contentType=%@",
                               pacs[@"wadouri"],
                               euid,
                               suid,
                               iuid,
                               mediaType
                               ];
   
   return [NSMutableURLRequest
           DRSRequestPacs:pacs
           URLString:URLString
           method:GET
           ];
}



@end
