//
//  WeasisInstance.m
//  httpdicom
//
//  Created by jacquesfauquex on 2019-08-23.
//  Copyright © 2019 opendicom.com. All rights reserved.
//

#import "WeasisInstance.h"

@implementation WeasisInstance

+(NSXMLElement*)pk:(NSString*)pk
               uid:(NSString*)uid
               num:(NSString*)num
{
   if (!pk || !uid) return nil;
   
   NSXMLElement *Instance=[NSXMLElement elementWithName:@"Instance"];
   
   //attributes
   //[Instance addAttribute:[NSXMLNode attributeWithName:@"pk" stringValue:pk]];
   [Instance addAttribute:[NSXMLNode attributeWithName:@"SOPInstanceUID" stringValue:uid]];
   
   if (num) [Instance addAttribute:[NSXMLNode attributeWithName:@"InstanceNumber" stringValue:num]];

   return Instance;
}
@end
