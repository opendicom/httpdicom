#import "NSString+PV1.h"

@implementation NSString(PV1)

+(NSString*)
   VisitNumber      :(NSString*)PV1_8
   ReferringDoctor  :(NSString*)PV1_15
   AmbultatoryStatus:(NSString*)PV1_19
{
   if (!PV1_8)PV1_8=@"";
   if (!PV1_15)PV1_15=@"";
   if (!PV1_19)PV1_19=@"";

   return [NSString
           stringWithFormat:@"PV1||||||||%@|||||||%@||||%@",
           PV1_8,
           PV1_15,
           PV1_19
           ];
}

@end
