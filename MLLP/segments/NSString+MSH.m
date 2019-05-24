#import "NSString+MSH.h"
#import "DICMTypes.h"

@implementation NSString(MSH)

+(NSString*)
   sendingApplication  :(NSString*)MSH_3
   sendingFacility     :(NSString*)MSH_4
   receivingApplication:(NSString*)MSH_5
   receivingFacility   :(NSString*)MSH_6
   messageType         :(NSString*)MSH_9
   messageControlID    :(NSString*)MSH_10
   versionID           :(NSString*)MSH_12
   countryCode         :(NSString*)MSH_17
   stringEncoding      :(NSStringEncoding)stringEncoding
   principalLanguage   :(NSString*)MSH_19
{
   //message type needs to be specified
   if (!MSH_9) return nil;
      

   if (!MSH_3)MSH_3=@"HIS";
   if (!MSH_4)MSH_4=@"IP";
   if (!MSH_5)MSH_5=@"CUSTODIAN";
   if (!MSH_6)MSH_6=@"PACS";

   if (!MSH_10)MSH_10=[[NSUUID UUID] UUIDString];
   
   if (!MSH_12)MSH_12=@"2.3.1";
      
   if (!MSH_17)MSH_17=@"cl";
   
   //https://dcm4chee-arc-cs.readthedocs.io/en/latest/charsets.html
   //http://www.healthintersections.com.au/?p=350
   NSString *MSH_18=nil;
   switch (stringEncoding) {
      case 1://ascii
         MSH_18=@"ASCII";
         break;
      case 4://utf-8
         MSH_18=@"UNICODE UTF-8";
         break;
      case 5:
      default:
         MSH_18=@"8859/1";
         break;
   }
   
   if (!MSH_19)MSH_19=@"es";
   
   return [NSString stringWithFormat:
           @"MSH|^~\\&|%@|%@|%@|%@|%@||%@|%@|P|%@|||||%@|%@|%@",
           MSH_3,
           MSH_4,
           MSH_5,
           MSH_6,
           [DICMTypes DAStringFromDate:[NSDate date]],
           MSH_9,
           MSH_10,
           MSH_12,
           MSH_17,
           MSH_18,
           MSH_19
           ];
}

@end
