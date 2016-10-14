//
//  NSData+PCS.h
//  httpdicom
//
//  Created by jacquesfauquex on 2016-10-12.
//  Copyright © 2016 ridi.salud.uy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (PCS)
+(NSData*)jsonpCallback:(NSString*)callback withDictionary:(NSDictionary*)dictionary;
+(NSData*)jsonpCallback:(NSString*)callback forDraw:(NSString*)draw withErrorString:(NSString*)error;
@end
