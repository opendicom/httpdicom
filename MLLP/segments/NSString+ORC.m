#import "NSString+ORC.h"
#import "DICMTypes.h"

@implementation NSString(ORC)

+(NSString*)
   orderControl   :(NSString*)ORC_1
   isrPlacerNumber:(NSString*)ORC_2
   isrFillerNumber:(NSString*)ORC_3
   reqPriority    :(NSString*)ORC_7_
   spsOrderStatus :(NSString*)ORC_5
   spsDateTime    :(NSString*)ORC_7
{
   if (!ORC_3)return nil;
   if (!ORC_1)ORC_1=@"NW";
   if (!ORC_2)ORC_2=@"";
   if (!ORC_5)ORC_5=@"SC";//SCHEDULED
   if (!ORC_7)ORC_7=[DICMTypes DTStringFromDate:[NSDate date]];
   if (!ORC_7_)ORC_7_=@"T";//T=Medium, S=STAT A,P,C=HIGH, R=ROUTINE

   return [NSString stringWithFormat:
           @"ORC|%@|%@|%@||%@||^^^%@^^%@",
           ORC_1,
           ORC_2,
           ORC_3,
           ORC_5,
           ORC_7,
           ORC_7_
           ];
}

@end
