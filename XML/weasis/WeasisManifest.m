//
//  WeasisManifest.m
//  httpdicom
//
//  Created by jacquesfauquex on 2019-08-23.
//  Copyright © 2019 opendicom.com. All rights reserved.
//

#import "WeasisManifest.h"


@implementation WeasisManifest

+(NSXMLElement*)manifest
{
   NSXMLElement *manifest=[NSXMLElement elementWithName:@"manifest"];
   
   //namespace
   [manifest addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://www.weasis.org/xsd/2.5"]];
   [manifest addNamespace:[NSXMLNode namespaceWithName:@"xsi" stringValue:@"http://www.w3.org/2001/XMLSchema-instance"]];
   return manifest;
}
@end
