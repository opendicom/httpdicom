//
//  WeasisInstance.h
//  httpdicom
//
//  Created by jacquesfauquex on 2019-08-23.
//  Copyright © 2019 opendicom.com. All rights reserved.
//

#import <Foundation/Foundation.h>

//NS_ASSUME_NONNULL_BEGIN

/*
 <xsd:attribute name="SOPInstanceUID" type="dicomVrUI"
    use="required" />
 <xsd:attribute name="InstanceNumber" type="dicomVrIS" />
 <xsd:attribute name="DirectDownloadFile" type="xsd:string" />
 */

@interface WeasisInstance : NSXMLElement

+(NSXMLElement*)key:(NSString*)key
weasisSOPInstanceUID:(NSString*)weasisSOPInstanceUID
weasisInstanceNumber:(NSString*)weasisInstanceNumber
weasisDirectDownloadFile:(NSString*)weasisDirectDownloadFile
NumberOfFrames:(NSString*)NumberOfFrames;

@end

//NS_ASSUME_NONNULL_END
