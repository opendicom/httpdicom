//
//  WeasisManifest.h
//  httpdicom
//
//  Created by jacquesfauquex on 2019-08-23.
//  Copyright © 2019 opendicom.com. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 [xmlweasismanifest appendString:@"<manifest xmlns=\"http://www.weasis.org/xsd/2.5\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">\r"];
 */

NS_ASSUME_NONNULL_BEGIN

@interface WeasisManifest : NSXMLElement

+(NSXMLElement*)manifest;

@end

NS_ASSUME_NONNULL_END
