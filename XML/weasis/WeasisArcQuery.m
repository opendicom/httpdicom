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

+(NSXMLElement*)arcQueryOID:(NSString*)arcId
                  custodian:(NSString*)baseUrl
                    session:(NSString*)session
              seriesNumbers:(NSArray*)seriesNumberArray
         seriesDescriptions:(NSArray*)seriesDescriptionArray
                 modalities:(NSArray*)modalityArray
                 SOPClasses:(NSArray*)SOPClassArray
      overrideDicomTagsList:(NSString*)overrideDicomTagsList
{
   NSXMLElement *arcQuery=[NSXMLElement elementWithName:@"arcQuery"];
   
   //attributes
   [arcQuery addAttribute:[NSXMLNode attributeWithName:@"arcId" stringValue:arcId]];
   [arcQuery addAttribute:[NSXMLNode attributeWithName:@"baseUrl" stringValue:baseUrl]];
   [arcQuery addAttribute:[NSXMLNode attributeWithName:@"overrideDicomTagsList" stringValue:overrideDicomTagsList]];
   
   NSMutableString *additionalParameters=[NSMutableString stringWithFormat:@"&amp;session=%@&amp;custodianOID=%@",session,baseUrl];
   if (seriesNumberArray) [additionalParameters appendFormat:@"&amp;SeriesNumber=%@",[seriesNumberArray componentsJoinedByString:@"\\"]];
   if (seriesDescriptionArray) [additionalParameters appendFormat:@"&amp;seriesDescription=%@",[seriesDescriptionArray componentsJoinedByString:@"\\"]];
   if (modalityArray) [additionalParameters appendFormat:@"&amp;modality=%@",[modalityArray componentsJoinedByString:@"\\"]];
   if (SOPClassArray) [additionalParameters appendFormat:@"&amp;SOPClass=%@",[SOPClassArray componentsJoinedByString:@"\\"]];

   
   [arcQuery addAttribute:[NSXMLNode attributeWithName:@"additionnalParameters" stringValue:additionalParameters]];

   return arcQuery;
}

@end
