#import "RequestMwlitems.h"
#import "NSMutableURLRequest+DRS.h"

@implementation RequestMwlitems

+(NSMutableURLRequest*)getFromPacs:(NSDictionary*)pacs
                   accessionNumber:(NSString*)an
{
   if (!pacs[@"dcm4cheelocaluri"] || ![pacs[@"dcm4cheelocaluri"] length]) return nil;
   if (!an || ![an length]) return nil;

   NSMutableString *URLString=nil;
   URLString=[NSMutableString stringWithFormat:@"%@/rs/mwlitems?AccessionNumber=%@",
         pacs[@"dcm4cheelocaluri"],
         an
         ];
   
   return [NSMutableURLRequest DRSRequestPacs:pacs
                                    URLString:URLString
                                       method:GET
           ];
}

@end
