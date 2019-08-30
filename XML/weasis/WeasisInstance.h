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

+(NSXMLElement*)pk:(NSString*)pk
               uid:(NSString*)uid
               num:(NSString*)num
;

@end

//NS_ASSUME_NONNULL_END
