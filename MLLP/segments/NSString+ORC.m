#import "NSString+ORC.h"
#import "DICMTypes.h"

@implementation NSString(ORC)

+(NSString*)
   OrderControl        :(NSString*)ORC_1
   sendingRisName      :(NSString*)ORC_2
   receivingPacsaet    :(NSString*)ORC_3
   isrPlacerDT         :(NSString*)ORC_2_
   isrFillerScheduledDT:(NSString*)ORC_3_
   spsOrderStatus      :(NSString*)ORC_4
   spsDateTime         :(NSString*)ORC_7
   rpPriority          :(NSString*)ORC_7_
   EnteringDevice      :(NSString*)ORC_18
{
   NSString *DTnow=[DICMTypes DTStringFromDate:[NSDate date]];
   
   if (!ORC_1)ORC_1=@"NW";
   if (!ORC_2)ORC_2=@"HIS";
   if (!ORC_2_)ORC_2_=DTnow;
   if (!ORC_3)ORC_3=@"CUSTODIAN";
   if (!ORC_3_)ORC_3_=DTnow;
   if (!ORC_4)ORC_4=@"SC";//SCHEDULED
   if (!ORC_7)ORC_7=DTnow;
   if (!ORC_7_)ORC_7_=@"T";//T=Medium, S=STAT A,P,C=HIGH, R=ROUTINE
   if (!ORC_18)ORC_18=@"IP";

   return [NSString stringWithFormat:
           @"ORC|%@|%@^%@|%@^%@||%@||^^^%@^^%@|||||||||||%@",
           ORC_1,
           ORC_2,
           ORC_2_,
           ORC_3,
           ORC_3_,
           ORC_4,
           ORC_7,
           ORC_7_,
           ORC_18
           ];
}

@end
