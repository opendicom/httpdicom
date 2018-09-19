//
//  NSMutableData+SQL.h
//  httpdicom
//
//  Created by jacquesfauquex on 20171222.
//  Copyright © 2017 opendicom.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableData (SQL)

+(NSMutableData*)countTask:(NSString*)string;
+(NSMutableData*)jsonTask:(NSString*)string sqlCharset:(NSStringEncoding)encoding;

@end
