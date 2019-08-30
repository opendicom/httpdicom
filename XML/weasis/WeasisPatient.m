//
//  WeasisPatient.m
//  httpdicom
//
//  Created by jacquesfauquex on 2019-08-23.
//  Copyright © 2019 opendicom.com. All rights reserved.
//

#import "WeasisPatient.h"

@implementation WeasisPatient

+(NSXMLElement*)pk:(NSString*)pk
               pid:(NSString*)pid
              name:(NSString*)name
            issuer:(NSString*)issuer
         birthdate:(NSString*)birthdate
               sex:(NSString*)sex
{
   NSXMLElement *Patient=[NSXMLElement elementWithName:@"Patient"];
   
   //attributes
   [Patient addAttribute:[NSXMLNode attributeWithName:@"pk" stringValue:pk]];
   [Patient addAttribute:[NSXMLNode attributeWithName:@"PatientID" stringValue:pid]];
   [Patient addAttribute:[NSXMLNode attributeWithName:@"PatientName" stringValue:name]];
   [Patient addAttribute:[NSXMLNode attributeWithName:@"IssuerOfPatientID" stringValue:issuer]];
   [Patient addAttribute:[NSXMLNode attributeWithName:@"PatientBirthDate" stringValue:birthdate]];
   [Patient addAttribute:[NSXMLNode attributeWithName:@"PatientSex" stringValue:sex]];

   return Patient;
}

@end
