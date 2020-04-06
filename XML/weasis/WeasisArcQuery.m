//
//  WeasisArcQuery.m
//  httpdicom
//
//  Created by jacquesfauquex on 2019-08-23.
//  Copyright © 2019 opendicom.com. All rights reserved.
//

#import "WeasisArcQuery.h"

/*
 + elementWithName:children:attributes:
 + elementWithName:stringValue:
 + elementWithName:URI:
 + attributeWithName:stringValue:
 + attributeWithName:URI:stringValue:
 + textWithStringValue:
 + commentWithStringValue:

 */
@implementation WeasisArcQuery

+(NSXMLElement*)weasisarcId:(NSString*)weasisarcId
weasiswebLogin:(NSString*)weasiswebLogin
weasisrequireOnlySOPInstanceUID:(NSString*)weasisrequireOnlySOPInstanceUID
weasisadditionnalParameters:(NSString*)weasisadditionnalParameters
weasisoverrideDicomTagsList:(NSString*)weasisoverrideDicomTagsList
seriesFilterInstanceUID:(NSString*)seriesInstanceUIDRegexString
seriesFilterNumber:(NSString*)seriesNumberRegexString
seriesFilterDescription:(NSString*)seriesDescriptionRegexString
seriesFilterModality:(NSString*)modalityRegexString
seriesFilterSOPClass:(NSString*)SOPClassRegexString
seriesFilterSOPClassOff:(NSString*)SOPClassOffRegexString
{
   if (!weasisarcId || !weasisadditionnalParameters) return nil;
   
   NSXMLElement *arcQuery=[NSXMLElement elementWithName:@"arcQuery"];
   
   // required attributes
   
   [arcQuery addAttribute:[NSXMLNode attributeWithName:@"arcQueryId" stringValue:@"_sessionString_"]];
   //arcQueryId injected with session number just before sending the response
   
   
   [arcQuery addAttribute:[NSXMLNode attributeWithName:@"arcId" stringValue:weasisarcId]];
   [arcQuery addAttribute:[NSXMLNode attributeWithName:@"additionnalParameters" stringValue:[NSString stringWithFormat:@"&session=_sessionString_&arcId=%@",weasisarcId]]];//arcQueryId injected with session number just before sending the response
   [arcQuery addAttribute:[NSXMLNode attributeWithName:@"baseUrl" stringValue:@"_proxyURIString_"]];

   // optional attributes
   if (weasiswebLogin) [arcQuery addAttribute:[NSXMLNode attributeWithName:@"webLogin" stringValue:weasiswebLogin]];
   if (weasisrequireOnlySOPInstanceUID) [arcQuery addAttribute:[NSXMLNode attributeWithName:@"requireOnlySOPInstanceUID" stringValue:weasisrequireOnlySOPInstanceUID]];
   if (weasisoverrideDicomTagsList) [arcQuery addAttribute:[NSXMLNode attributeWithName:@"overrideDicomTagsList" stringValue:weasisoverrideDicomTagsList]];
   

   if (seriesInstanceUIDRegexString) [arcQuery addAttribute:[NSXMLNode attributeWithName:@"seriesFilterInstanceUID" stringValue:seriesInstanceUIDRegexString]];
   if (seriesNumberRegexString) [arcQuery addAttribute:[NSXMLNode attributeWithName:@"seriesFilterNumber" stringValue:seriesNumberRegexString]];
   if (seriesDescriptionRegexString) [arcQuery addAttribute:[NSXMLNode attributeWithName:@"seriesFilterDescription" stringValue:seriesDescriptionRegexString]];
   if (modalityRegexString) [arcQuery addAttribute:[NSXMLNode attributeWithName:@"seriesFilterModality" stringValue:modalityRegexString]];
   if (SOPClassRegexString) [arcQuery addAttribute:[NSXMLNode attributeWithName:@"seriesFilterSOPClass" stringValue:SOPClassRegexString]];
   if (SOPClassOffRegexString) [arcQuery addAttribute:[NSXMLNode attributeWithName:@"seriesFilterSOPClassOff" stringValue:SOPClassOffRegexString]];

   return arcQuery;
}

@end
