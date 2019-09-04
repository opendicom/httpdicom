//
//  WeasisSeries.m
//  httpdicom
//
//  Created by jacquesfauquex on 2019-08-23.
//  Copyright © 2019 opendicom.com. All rights reserved.
//

#import "WeasisSeries.h"

@implementation WeasisSeries

+(NSXMLElement*)pk:(NSString*)pk
               uid:(NSString*)uid
              desc:(NSString*)desc
               num:(NSString*)num
               mod:(NSString*)mod
               wts:(NSString*)wts
               sop:(NSString*)sop
{
   if (!pk || !uid) return nil;
   
   NSXMLElement *Series=[NSXMLElement elementWithName:@"Series"];

   //required attributes
   //[Series addAttribute:[NSXMLNode attributeWithName:@"pk" stringValue:pk]];
   [Series addAttribute:[NSXMLNode attributeWithName:@"SeriesInstanceUID" stringValue:uid]];

   //optional attributes
   if (desc) [Series addAttribute:[NSXMLNode attributeWithName:@"SeriesDescription" stringValue:desc]];
   if (num) [Series addAttribute:[NSXMLNode attributeWithName:@"SeriesNumber" stringValue:num]];
   if (mod) [Series addAttribute:[NSXMLNode attributeWithName:@"Modality" stringValue:mod]];
   if (wts) [Series addAttribute:[NSXMLNode attributeWithName:@"WadoTransferSyntaxUID" stringValue:wts]];
   if (sop) [Series addAttribute:[NSXMLNode attributeWithName:@"SOPClass" stringValue:sop]];

   return Series;
}

@end
