//
//  RequestPOSTEncapsulated.h
//  httpdicom
//
//  Created by jacquesfauquex on 2019-02-17.
//  Copyright © 2019 ridi.salud.uy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RequestPOSTEncapsulated : NSObject

//multipart/related; type=application/dicom[dicomSubType]; boundary={messageBoundary}

// dicomSubType: @"", @"+xml", @"+json"
+(NSURLMutableRequest*)toPacs:(NSDictionary*)pacs
                 dicomSubtype:(NSString*)dicomSubType
               boundaryString:(NSString*)boundaryString
                     bodyData:(NSData*)bodyData
;

@end

NS_ASSUME_NONNULL_END
