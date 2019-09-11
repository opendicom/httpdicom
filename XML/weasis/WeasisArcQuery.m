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
                    session:(NSString*)session
                  custodian:(NSString*)baseUrl
             transferSyntax:(NSString*)transferSyntax
          seriesInstanceUID:(NSString*)seriesInstanceUIDRegexString
               seriesNumber:(NSString*)seriesNumberRegexString
          seriesDescription:(NSString*)seriesDescriptionRegexString
                   modality:(NSString*)modalityRegexString
                   SOPClass:(NSString*)SOPClassRegexString
                SOPClassOff:(NSString*)SOPClassOffRegexString
      overrideDicomTagsList:(NSString*)overrideDicomTagsList
{
   NSXMLElement *arcQuery=[NSXMLElement elementWithName:@"arcQuery"];
   
   //attributes
   [arcQuery addAttribute:[NSXMLNode attributeWithName:@"arcId" stringValue:arcId]];
   [arcQuery addAttribute:[NSXMLNode attributeWithName:@"baseUrl" stringValue:baseUrl]];
   [arcQuery addAttribute:[NSXMLNode attributeWithName:@"overrideDicomTagsList" stringValue:overrideDicomTagsList]];
   
   NSMutableString *additionalParameters=[NSMutableString stringWithFormat:@"&amp;session=%@&amp;custodianOID=%@",session,baseUrl];
//add restrictions?
   
   [arcQuery addAttribute:[NSXMLNode attributeWithName:@"additionnalParameters" stringValue:additionalParameters]];

   return arcQuery;
}

@end
