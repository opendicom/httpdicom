//
//  WeasisPatient.h
//  httpdicom
//
//  Created by jacquesfauquex on 2019-08-23.
//  Copyright © 2019 opendicom.com. All rights reserved.
//

#import <Foundation/Foundation.h>

//NS_ASSUME_NONNULL_BEGIN

/*
 <xsd:sequence>
    <xsd:element name="Study" type="Study" minOccurs="1"
       maxOccurs="unbounded" />
 </xsd:sequence>
 <xsd:attribute name="PatientID" type="dicomVrLO" use="required" />
 <xsd:attribute name="PatientName" type="dicomVrPN" use="required" />
 <xsd:attribute name="IssuerOfPatientID" type="dicomVrLO" />
 <xsd:attribute name="PatientBirthDate" type="dicomVrDA" />
 <xsd:attribute name="PatientBirthTime" type="dicomVrTM" />
 <xsd:attribute name="PatientSex" type="dicomPatientSex" />
 */

@interface WeasisPatient : NSXMLElement

+(NSXMLElement*)key:(NSString*)key
weasisPatientID:(NSString*)weasisPatientID
weasisPatientName:(NSString*)weasisPatientName
weasisIssuerOfPatientID:(NSString*)weasisIssuerOfPatientID
weasisPatientBirthDate:(NSString*)weasisPatientBirthDate
weasisPatientBirthTime:(NSString*)weasisPatientBirthTime
weasisPatientSex:(NSString*)weasisPatientSex
;

@end

//NS_ASSUME_NONNULL_END
