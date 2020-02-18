#import "WeasisSeries.h"

@implementation WeasisSeries

+(NSXMLElement*)key:(NSString*)key
weasisSeriesInstanceUID:(NSString*)weasisSeriesInstanceUID
weasisSeriesDescription:(NSString*)weasisSeriesDescription
weasisSeriesNumber:(NSString*)weasisSeriesNumber
weasisModality:(NSString*)weasisModality
weasisWadoTransferSyntaxUID:(NSString*)weasisWadoTransferSyntaxUID
weasisWadoCompressionRate:(NSString*)weasisWadoCompressionRate
weasisDirectDownloadThumbnail:(NSString*)weasisDirectDownloadThumbnail
sop:(NSString*)sop
institution:(NSString*)institution
department:(NSString*)department
stationName:(NSString*)stationName
performingPhysician:(NSString*)performingPhysician
laterality:(NSString*)laterality
images:(NSString*)images
{
   if (!key || !weasisSeriesInstanceUID) return nil;
   
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
   if (institution) [Series addAttribute:[NSXMLNode attributeWithName:@"Institution" stringValue:institution]];
   if (department) [Series addAttribute:[NSXMLNode attributeWithName:@"Department" stringValue:department]];
   if (stationName) [Series addAttribute:[NSXMLNode attributeWithName:@"StationName" stringValue:stationName]];
   if (performingPhysician) [Series addAttribute:[NSXMLNode attributeWithName:@"PerformingPhysicianName" stringValue:performingPhysician]];
   if (laterality) [Series addAttribute:[NSXMLNode attributeWithName:@"Laterality" stringValue:laterality]];
   if (images) [Series addAttribute:[NSXMLNode attributeWithName:@"Images​In​Study" stringValue:images]];

   [Series addAttribute:[NSXMLNode attributeWithName:@"key" stringValue:key]];
   
   return Series;
}

@end
