//
//  NSString+PCS.h
//  httpdicom
//
//  Created by jacquesfauquex on 2016-10-11.
//  Copyright © 2016 ridi.salud.uy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (PCS)
+(NSString*)regexDicomString:(NSString*)dicomString withFormat:(NSString*)formatString;
+(NSString*)mysqlEscapedFormat:(NSString*)format fieldString:(NSString*)field valueString:(NSString*)value;
@end
