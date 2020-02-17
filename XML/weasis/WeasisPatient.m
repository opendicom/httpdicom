//
//  WeasisPatient.m
//  httpdicom
//
//  Created by jacquesfauquex on 2019-08-23.
//  Copyright © 2019 opendicom.com. All rights reserved.
//

#import "WeasisPatient.h"

@implementation WeasisPatient

+(NSXMLElement*)key:(NSString*)key
weasisPatientID:(NSString*)weasisPatientID
weasisPatientName:(NSString*)weasisPatientName
weasisIssuerOfPatientID:(NSString*)weasisIssuerOfPatientID
weasisPatientBirthDate:(NSString*)weasisPatientBirthDate
weasisPatientBirthTime:(NSString*)weasisPatientBirthTime
weasisPatientSex:(NSString*)weasisPatientSex
{
   if (!key || !weasisPatientID || !weasisPatientName) return nil;

   NSXMLElement *Patient=[NSXMLElement elementWithName:@"Patient"];
      
   //required attributes
   [Patient addAttribute:[NSXMLNode attributeWithName:@"PatientID" stringValue:weasisPatientID]];
   [Patient addAttribute:[NSXMLNode attributeWithName:@"PatientName" stringValue:weasisPatientName]];
   
   //optional attributes
   if (weasisIssuerOfPatientID) [Patient addAttribute:[NSXMLNode attributeWithName:@"IssuerOfPatientID" stringValue:weasisIssuerOfPatientID]];
   if (weasisPatientBirthDate) [Patient addAttribute:[NSXMLNode attributeWithName:@"PatientBirthDate" stringValue:weasisPatientBirthDate]];
   if (weasisPatientBirthTime) [Patient addAttribute:[NSXMLNode attributeWithName:@"PatientBirthTime" stringValue:weasisPatientBirthTime]];
   if (weasisPatientSex) [Patient addAttribute:[NSXMLNode attributeWithName:@"PatientSex" stringValue:weasisPatientSex]];
   
   [Patient addAttribute:[NSXMLNode attributeWithName:@"key" stringValue:key]];

   return Patient;
}

@end
