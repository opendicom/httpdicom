#import "RequestQidoStudy.h"
#import "NSMutableURLRequest+DRS.h"

@implementation RequestQidoStudy


+(NSMutableURLRequest*)toPacs:(NSDictionary*)pacs
                     studyUID:(NSString*)studyUID
{
   return [NSMutableURLRequest
           DRSRequestPacs:pacs
           URLString:[NSMutableString
                      stringWithFormat:@"%@?StudyInstanceUID=%@",
                      pacs[@"qido"],
                      studyUID]
           method:GET
           ];
}

@end
