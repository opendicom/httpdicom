#import "WeasisInstance.h"

@implementation WeasisInstance

+(NSXMLElement*)key:(NSString*)key
weasisInstanceNumber:(NSString*)weasisInstanceNumber
NumberOfFrames:(NSString*)NumberOfFrames
weasisSOPClassUID:(NSString*)weasisSOPClassUID
weasisSOPInstanceUID:(NSString*)weasisSOPInstanceUID
weasisDirectDownloadFile:(NSString*)weasisDirectDownloadFile
{
   if (!key || !weasisSOPInstanceUID) return nil;
   
   NSXMLElement *Instance=[NSXMLElement elementWithName:@"Instance"];
   
   //required attributes
   [Instance addAttribute:[NSXMLNode attributeWithName:@"SOPInstanceUID" stringValue:weasisSOPInstanceUID]];

   //optional attributes
   if (weasisInstanceNumber) [Instance addAttribute:[NSXMLNode attributeWithName:@"InstanceNumber" stringValue:weasisInstanceNumber]];
   if (NumberOfFrames) [Instance addAttribute:[NSXMLNode attributeWithName:@"NumberOfFrames" stringValue:NumberOfFrames]];
   if (weasisSOPClassUID) [Instance addAttribute:[NSXMLNode attributeWithName:@"SOPClassUID" stringValue:weasisSOPClassUID]];
   if (weasisDirectDownloadFile) [Instance addAttribute:[NSXMLNode attributeWithName:@"DirectDownloadFile" stringValue:weasisDirectDownloadFile]];

   [Instance addAttribute:[NSXMLNode attributeWithName:@"key" stringValue:key]];
   
   return Instance;
}
@end
