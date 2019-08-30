//
//  WeasisStudy.h
//  httpdicom
//
//  Created by jacquesfauquex on 2019-08-23.
//  Copyright © 2019 opendicom.com. All rights reserved.
//

#import <Foundation/Foundation.h>

//NS_ASSUME_NONNULL_BEGIN

/*
 <xsd:sequence>
    <xsd:element name="Series" type="Series" minOccurs="1"
       maxOccurs="unbounded" />
 </xsd:sequence>
 <xsd:attribute name="StudyInstanceUID" type="dicomVrUI"
    use="required" />
 <xsd:attribute name="StudyDescription" type="dicomVrLO" />
 <xsd:attribute name="StudyDate" type="dicomVrDA" />
 <xsd:attribute name="StudyTime" type="dicomVrTM" />
 <xsd:attribute name="AccessionNumber" type="dicomVrSH" />
 <xsd:attribute name="StudyID" type="dicomVrSH" />
 <xsd:attribute name="ReferringPhysicianName" type="dicomVrPN" />
 */

@interface WeasisStudy : NSXMLElement

+(NSXMLElement*)pk:(NSString*)pk
               uid:(NSString*)uid
              desc:(NSString*)desc
              date:(NSString*)date
              time:(NSString*)time
                an:(NSString*)an
            issuer:(NSString*)issuer
              type:(NSString*)type
               eid:(NSString*)eid
               ref:(NSString*)ref
               img:(NSString*)img
               mod:(NSString*)mod
;

@end

//NS_ASSUME_NONNULL_END
