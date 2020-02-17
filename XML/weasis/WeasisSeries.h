//
//  WeasisSeries.h
//  httpdicom
//
//  Created by jacquesfauquex on 2019-08-23.
//  Copyright © 2019 opendicom.com. All rights reserved.
//

#import <Foundation/Foundation.h>

//NS_ASSUME_NONNULL_BEGIN

/*
 <xsd:sequence>
    <xsd:element name="Instance" type="Instance" minOccurs="1"
       maxOccurs="unbounded" />
 </xsd:sequence>
 <xsd:attribute name="SeriesInstanceUID" type="dicomVrUI"
    use="required" />
 <xsd:attribute name="SeriesDescription" type="dicomVrLO" />
 <xsd:attribute name="SeriesNumber" type="dicomVrIS" />
 <xsd:attribute name="Modality" type="dicomVrCS" />
 <xsd:attribute name="WadoTransferSyntaxUID" type="xsd:string" />
 <xsd:attribute name="WadoCompressionRate" type="xsd:integer" />
 <xsd:attribute name="DirectDownloadThumbnail" type="xsd:string" />
 */

@interface WeasisSeries : NSXMLElement

+(NSXMLElement*)key:(NSString*)key
weasisSeriesInstanceUID:(NSString*)weasisSeriesInstanceUID
weasisSeriesDescription:(NSString*)weasisSeriesDescription
weasisSeriesNumber:(NSString*)weasisSeriesNumber
weasisModality:(NSString*)weasisModality
weasisWadoTransferSyntaxUID:(NSString*)weasisWadoTransferSyntaxUID
weasisWadoCompressionRate:(NSString*)weasisWadoCompressionRate
weasisDirectDownloadThumbnail:(NSString*)weasisDirectDownloadThumbnail
sop:(NSString*)sop
images:(NSString*)images
;
//wts wado transfer syntax uid
//wcr wado compression rate
//ddt dicrect download thumbnail

@end

//NS_ASSUME_NONNULL_END
