//
//  WeasisInstance.m
//  httpdicom
//
//  Created by jacquesfauquex on 2019-08-23.
//  Copyright © 2019 opendicom.com. All rights reserved.
//

#import "WeasisInstance.h"

@implementation WeasisInstance

+(NSXMLElement*)key:(NSString*)key
weasisSOPInstanceUID:(NSString*)weasisSOPInstanceUID
weasisInstanceNumber:(NSString*)weasisInstanceNumber
weasisDirectDownloadFile:(NSString*)weasisDirectDownloadFile 
NumberOfFrames:(NSString*)NumberOfFrames
{
   if (!key || !weasisSOPInstanceUID) return nil;
   
   NSXMLElement *Instance=[NSXMLElement elementWithName:@"Instance"];
   
   //required attributes
   [Instance addAttribute:[NSXMLNode attributeWithName:@"SOPInstanceUID" stringValue:weasisSOPInstanceUID]];

   //optional attributes
   if (weasisInstanceNumber) [Instance addAttribute:[NSXMLNode attributeWithName:@"InstanceNumber" stringValue:weasisInstanceNumber]];
   if (weasisDirectDownloadFile) [Instance addAttribute:[NSXMLNode attributeWithName:@"DirectDownloadFile" stringValue:weasisDirectDownloadFile]];
   if (NumberOfFrames) [Instance addAttribute:[NSXMLNode attributeWithName:@"NumberOfFrames" stringValue:NumberOfFrames]];

   [Instance addAttribute:[NSXMLNode attributeWithName:@"key" stringValue:key]];
   
   return Instance;
}
@end
