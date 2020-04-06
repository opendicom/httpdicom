#import "NSString+PV1.h"

@implementation NSString(PV1)

+(NSString*)
isrInsurance:(NSString*)PV1_8
isrReferring:(NSString*)PV1_15
{
   if (!PV1_8)PV1_8=@"";
   if (!PV1_15)PV1_15=@"";

   return [NSString
           stringWithFormat:@"PV1||||||||%@|||||||%@",
           PV1_8,
           PV1_15
           ];
}

@end
