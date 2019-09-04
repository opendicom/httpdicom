//
//  WeasisStudy.m
//  httpdicom
//
//  Created by jacquesfauquex on 2019-08-23.
//  Copyright © 2019 opendicom.com. All rights reserved.
//

#import "WeasisStudy.h"

@implementation WeasisStudy

+(NSXMLElement*)pk:(NSString*)pk
               uid:(NSString*)uid
              desc:(NSString*)desc
              date:(NSString*)date
              time:(NSString*)time
                an:(NSString*)an
            issuer:(NSString*)issuer
              type:(NSString*)type
               eid:(NSString*)eid
               ref:(NSString*)ref
               img:(NSString*)img
               mod:(NSString*)mod
{
   //required fields
   if (!pk || !uid) return nil;
   
   NSXMLElement *Study=[NSXMLElement elementWithName:@"Study"];
   
   //required attributes
   //[Study addAttribute:[NSXMLNode attributeWithName:@"pk" stringValue:pk]];
   [Study addAttribute:[NSXMLNode attributeWithName:@"StudyInstanceUID" stringValue:uid]];
   
   //optional attributes
   if (desc) [Study addAttribute:[NSXMLNode attributeWithName:@"StudyDescription" stringValue:desc]];
   if (date) [Study addAttribute:[NSXMLNode attributeWithName:@"StudyDate" stringValue:date]];
   if (time) [Study addAttribute:[NSXMLNode attributeWithName:@"StudyTime" stringValue:time]];
   if (an) [Study addAttribute:[NSXMLNode attributeWithName:@"AccessionNumber" stringValue:an]];
   if (issuer) [Study addAttribute:[NSXMLNode attributeWithName:@"issuer" stringValue:issuer]];
   if (type) [Study addAttribute:[NSXMLNode attributeWithName:@"issuerType" stringValue:type]];
   if (eid) [Study addAttribute:[NSXMLNode attributeWithName:@"StudyID" stringValue:eid]];
   if (ref) [Study addAttribute:[NSXMLNode attributeWithName:@"ReferringPhysicianName" stringValue:ref]];
   //if (img) [Study addAttribute:[NSXMLNode attributeWithName:@"Images​In​Study" stringValue:img]];
   //if (mod) [Study addAttribute:[NSXMLNode attributeWithName:@"Modalities​In​Study" stringValue:mod]];

   return Study;
}

@end
