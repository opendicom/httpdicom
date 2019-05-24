#import "NSString+OBR.h"

@implementation NSString(OBR)

static unsigned long uniqueRpID;
static unsigned long uniqueSpsID;
+(void)initialize
{
    uniqueRpID=[[NSDate date]timeIntervalSinceReferenceDate];
    uniqueSpsID=uniqueRpID;
}

+(NSString*)
   isrReferring :(NSString*)OBR_16
   isrAN        :(NSString*)OBR_18
   isrReading   :(NSString*)OBR_32
   reqID        :(NSString*)OBR_19
   reqProcedure :(NSString*)OBR_44
   spsPerforming:(NSString*)OBR_34
   spsID        :(NSString*)OBR_20
   spsModality  :(NSString*)OBR_24
   spsAET       :(NSString*)OBR_21
   spsProtocol  :(NSString*)OBR_4
{
   if (!OBR_24)
   {
      NSLog(@"WARN OBR_24 modality requested");
      return nil;
   }

   if (!OBR_4)  OBR_4 =@"";
   if (!OBR_16) OBR_16=@"";
   if (!OBR_18) OBR_18=@"";
   if (!OBR_19) OBR_19=[NSString stringWithFormat:@"%lu",uniqueRpID++];
   if (!OBR_20) OBR_20=[NSString stringWithFormat:@"%lu",uniqueSpsID++];
   
   if (!OBR_24)OBR_24=@"";
   if (!OBR_32)OBR_32=@"";
   if (!OBR_34)OBR_34=@"";
   if (!OBR_44)OBR_44=@"";

   return [NSString stringWithFormat:@"OBR||||%@||||||||||||%@||%@|%@|%@|%@|||%@||||||||%@||%@||||||||||%@",
           OBR_4,
           OBR_16,
           OBR_18,
           OBR_19,
           OBR_20,
           OBR_21,
           OBR_24,
           OBR_32,
           OBR_34,
           OBR_44
           ];

}

@end
