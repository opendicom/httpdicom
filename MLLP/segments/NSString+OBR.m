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
   spsProtocolCode                :(NSString*)OBR_4
   isrDangerCode                  :(NSString*)OBR_12
   isrRelevantClinicalInfo        :(NSString*)OBR_13
   isrReferringPhysician          :(NSString*)OBR_16
   isrAccessionNumber             :(NSString*)OBR_18
   rpID                           :(NSString*)OBR_19
   spsID                          :(NSString*)OBR_20
   spsStationAETitle              :(NSString*)OBR_21
   spsModality                    :(NSString*)OBR_24
   rpTransportationMode           :(NSString*)OBR_30
   rpReasonForStudy               :(NSString*)OBR_31
   isrNameOfPhysiciansReadingStudy:(NSString*)OBR_32
   spsTechnician                  :(NSString*)OBR_34
   rpUniversalStudyCode           :(NSString*)OBR_44
{
   if (!OBR_21)
   {
      NSLog(@"WARN OBR_21 modality requested");
      return nil;
   }

   if (!OBR_4)  OBR_4 =@"";
   if (!OBR_12) OBR_12=@"";
   if (!OBR_13) OBR_13=@"";
   if (!OBR_16) OBR_16=@"";
   if (!OBR_18) OBR_18=@"";
   if (!OBR_19) OBR_19=[NSString stringWithFormat:@"%lu",uniqueRpID++];
   if (!OBR_20) OBR_20=[NSString stringWithFormat:@"%lu",uniqueSpsID++];
   
   if (!OBR_24)OBR_24=@"";
   if (!OBR_30)OBR_30=@"";
   if (!OBR_31)OBR_31=@"";
   if (!OBR_32)OBR_32=@"";
   if (!OBR_34)OBR_34=@"";
   if (!OBR_44)OBR_44=@"";

   return [NSString stringWithFormat:@"OBR||||%@||||||||%@|%@|||%@||%@|%@|%@|%@|||%@||||||%@|%@|%@||%@||||||||||%@",
           OBR_4,
           OBR_12,
           OBR_13,
           OBR_16,
           OBR_18,
           OBR_19,
           OBR_20,
           OBR_21,
           OBR_24,
           OBR_30,
           OBR_31,
           OBR_32,
           OBR_34,
           OBR_44
           ];

}

@end
