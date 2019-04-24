#import "RequestStudy.h"
#import "NSMutableURLRequest+DRS.h"


@implementation RequestStudy

+(NSMutableURLRequest*)existsInPacs:(NSDictionary*)pacs
  accessionNumber:(NSString*)accessionNumber
  accessionIssuer:(NSString*)accessionIssuer
  accessionType:(NSString*)accessionType
  returnAttributes:(BOOL)returnAttributes
{
   NSMutableString *URLString=nil;
   if ([accessionType length])
      URLString=[NSMutableString stringWithFormat:@"%@/rs/studies?AccessionNumber=%@&00080051.00400032=%@&00080051.00400033=%@&includefield=00100021",
                 pacs[@"dcm4cheelocaluri"],
                 accessionNumber,
                 accessionIssuer,
                 accessionType
                 ];

   else if ([accessionType length])
      URLString=[NSMutableString stringWithFormat:@"%@/rs/studies?AccessionNumber=%@&00080051.00400031=%@&includefield=00100021",
                 pacs[@"dcm4cheelocaluri"],
                 accessionNumber,
                 accessionIssuer
                 ];
   else
      URLString=[NSMutableString stringWithFormat:@"%@/rs/studies?AccessionNumber=%@&includefield=00100021",
         pacs[@"dcm4cheelocaluri"],
         accessionNumber
         ];

   //GET or HEAD?
   if ((returnAttributes==false) && [pacs[@"headavailable"]boolValue])
      return [NSMutableURLRequest DRSRequestPacs:pacs
                                       URLString:URLString
                                          method:HEAD
              ];
   
   
   return [NSMutableURLRequest DRSRequestPacs:pacs
                                    URLString:URLString
                                       method:GET
           ];
}


+(NSMutableURLRequest*)existsInPacs:(NSDictionary*)pacs
               studyUID:(NSString*)studyUID
              seriesUID:(NSString*)seriesUID
                 sopUID:(NSString*)sopUID
       returnAttributes:(BOOL)returnAttributes
{
   NSMutableString *URLString=[NSMutableString stringWithFormat:@"%@/rs/",pacs[@"dcm4cheelocaluri"]];
   if (sopUID)
   {
      [URLString appendString:@"instances?SOPInstanceUID="];
      [URLString appendString:sopUID];
      
      if (seriesUID)
      {
         [URLString appendString:@"&SeriesInstanceUID="];
         [URLString appendString:seriesUID];
      }
      
      if (studyUID)
      {
         [URLString appendString:@"&StudyInstanceUID="];
         [URLString appendString:studyUID];
      }
   }
   else if (seriesUID)
   {
      [URLString appendString:@"series?SeriesInstanceUID="];
      [URLString appendString:seriesUID];
      
      if (studyUID)
      {
         [URLString appendString:@"&StudyInstanceUID="];
         [URLString appendString:studyUID];
      }
   }
   else if (studyUID)
   {
      [URLString appendString:@"studies?StudyInstanceUID="];
      [URLString appendString:studyUID];
   }
   else //no level
   {
      return nil;
   }
   [URLString appendString:@"&includefield=00100021"];

   
   //GET or HEAD?
   if ((returnAttributes==false) && [pacs[@"headavailable"]boolValue])
      return [NSMutableURLRequest DRSRequestPacs:pacs
                                       URLString:URLString
                                          method:HEAD
              ];
   
   
   return [NSMutableURLRequest DRSRequestPacs:pacs
                                    URLString:URLString
                                       method:GET
           ];
}
@end
