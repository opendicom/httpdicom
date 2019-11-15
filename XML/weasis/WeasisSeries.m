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
weasisSeriesInstanceUID:(NSString*)weasisSeriesInstanceUID
weasisSeriesDescription:(NSString*)weasisSeriesDescription
weasisSeriesNumber:(NSString*)weasisSeriesNumber
weasisModality:(NSString*)weasisModality
weasisWadoTransferSyntaxUID:(NSString*)weasisWadoTransferSyntaxUID
weasisWadoCompressionRate:(NSString*)weasisWadoCompressionRate
weasisDirectDownloadThumbnail:(NSString*)weasisDirectDownloadThumbnail
sop:(NSString*)sop
images:(NSString*)images

{
   if (!pk || !weasisSeriesInstanceUID) return nil;
   
   NSXMLElement *Series=[NSXMLElement elementWithName:@"Series"];

   //required attributes
   [Series addAttribute:[NSXMLNode attributeWithName:@"SeriesInstanceUID" stringValue:weasisSeriesInstanceUID]];

   //optional attributes
   if (weasisSeriesDescription) [Series addAttribute:[NSXMLNode attributeWithName:@"SeriesDescription" stringValue:weasisSeriesDescription]];
   if (weasisSeriesNumber) [Series addAttribute:[NSXMLNode attributeWithName:@"SeriesNumber" stringValue:weasisSeriesNumber]];
   if (weasisModality) [Series addAttribute:[NSXMLNode attributeWithName:@"Modality" stringValue:weasisModality]];
   if (weasisWadoTransferSyntaxUID) [Series addAttribute:[NSXMLNode attributeWithName:@"WadoTransferSyntaxUID" stringValue:weasisWadoTransferSyntaxUID]];
   if (weasisWadoCompressionRate) [Series addAttribute:[NSXMLNode attributeWithName:@"WadoCompressionRate" stringValue:weasisWadoCompressionRate]];
   if (weasisDirectDownloadThumbnail) [Series addAttribute:[NSXMLNode attributeWithName:@"DirectDownloadThumbnail" stringValue:weasisDirectDownloadThumbnail]];
   
   if (sop) [Series addAttribute:[NSXMLNode attributeWithName:@"SOPClass" stringValue:sop]];
   if (images) [Series addAttribute:[NSXMLNode attributeWithName:@"Images​In​Study" stringValue:images]];

   [Series addAttribute:[NSXMLNode attributeWithName:@"pk" stringValue:pk]];
   
   return Series;
}

@end
