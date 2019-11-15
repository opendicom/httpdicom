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
weasisStudyInstanceUID:(NSString*)weasisStudyInstanceUID
weasisStudyDescription:(NSString*)weasisStudyDescription
weasisStudyDate:(NSString*)weasisStudyDate
weasisStudyTime:(NSString*)weasisStudyTime
weasisAccessionNumber:(NSString*)weasisAccessionNumber
weasisStudyId:(NSString*)weasisStudyId
weasisReferringPhysicianName:(NSString*)weasisReferringPhysicianName
issuer:(NSString*)issuer
issuerType:(NSString*)issuerType
series:(NSString*)series
modalities:(NSString*)modalities
{
   //required fields
   if (!pk || !weasisStudyInstanceUID) return nil;
   
   NSXMLElement *Study=[NSXMLElement elementWithName:@"Study"];
   
   //required attributes
   [Study addAttribute:[NSXMLNode attributeWithName:@"StudyInstanceUID" stringValue:weasisStudyInstanceUID]];
   
   //optional attributes
   if (weasisStudyDescription) [Study addAttribute:[NSXMLNode attributeWithName:@"StudyDescription" stringValue:weasisStudyDescription]];
   if (weasisStudyDate) [Study addAttribute:[NSXMLNode attributeWithName:@"StudyDate" stringValue:weasisStudyDate]];
   if (weasisStudyTime) [Study addAttribute:[NSXMLNode attributeWithName:@"StudyTime" stringValue:weasisStudyTime]];
   if (weasisAccessionNumber) [Study addAttribute:[NSXMLNode attributeWithName:@"AccessionNumber" stringValue:weasisAccessionNumber]];
   if (weasisStudyId) [Study addAttribute:[NSXMLNode attributeWithName:@"StudyID" stringValue:weasisStudyId]];
   if (weasisReferringPhysicianName) [Study addAttribute:[NSXMLNode attributeWithName:@"ReferringPhysicianName" stringValue:weasisReferringPhysicianName]];
   
   if (issuer) [Study addAttribute:[NSXMLNode attributeWithName:@"issuer" stringValue:issuer]];
   if (issuerType) [Study addAttribute:[NSXMLNode attributeWithName:@"issuerType" stringValue:issuerType]];
   if (series) [Study addAttribute:[NSXMLNode attributeWithName:@"Series​In​Study" stringValue:series]];
   if (modalities) [Study addAttribute:[NSXMLNode attributeWithName:@"Modalities​In​Study" stringValue:modalities]];

   [Study addAttribute:[NSXMLNode attributeWithName:@"pk" stringValue:pk]];

   return Study;
}

@end
