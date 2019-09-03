//
//  WeasisArcQuery.h
//  httpdicom
//
//  Created by jacquesfauquex on 2019-08-23.
//  Copyright © 2019 opendicom.com. All rights reserved.
//

#import <Foundation/Foundation.h>

//NS_ASSUME_NONNULL_BEGIN

/*
 <xsd:sequence>
    <xsd:element name="httpTag" minOccurs="0" maxOccurs="unbounded">
       <xsd:complexType>
          <xsd:attribute name="key" type="xsd:string" use="required" />
          <xsd:attribute name="value" type="xsd:string" use="required" />
       </xsd:complexType>
    </xsd:element>
    <xsd:element name="Message" minOccurs="0" maxOccurs="1">
       <xsd:complexType>
          <xsd:attribute name="title" type="xsd:string" use="required" />
          <xsd:attribute name="description" type="xsd:string"
             use="required" />
          <xsd:attribute name="severity" type="errorSeverity" />
       </xsd:complexType>
    </xsd:element>
    <xsd:element name="Patient" type="Patient" minOccurs="0"
       maxOccurs="unbounded" />
 </xsd:sequence>
 <xsd:attribute name="arcId" type="xsd:string" use="required" />
 <xsd:attribute name="baseUrl" type="xsd:anyURI" use="required" />
 <xsd:attribute name="webLogin" type="xsd:string" />
 <xsd:attribute name="requireOnlySOPInstanceUID" type="xsd:boolean" />
 <xsd:attribute name="additionnalParameters" type="xsd:string" />
 <xsd:attribute name="overrideDicomTagsList" type="dicomTagsList" />
*/

@interface WeasisArcQuery : NSXMLElement

+(NSXMLElement*)arcQueryOID:(NSString*)arcId
                  custodian:(NSString*)baseUrl
                    session:(NSString*)session
              seriesNumbers:(NSArray*)seriesNumberArray
         seriesDescriptions:(NSArray*)seriesDescriptionArray
                 modalities:(NSArray*)modalityArray
                 SOPClasses:(NSArray*)SOPClassArray
      overrideDicomTagsList:(NSString*)overrideDicomTagsList
;

@end

//NS_ASSUME_NONNULL_END
