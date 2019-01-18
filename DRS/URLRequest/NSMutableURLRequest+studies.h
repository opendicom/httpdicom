//
//  NSMutableURLRequest+studies.h
//  httpdicom
//
//  Created by jacquesfauquex on 2017129.
//  Copyright © 2017 opendicom.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableURLRequest (studies)

+(id)GETqidostudies:(NSString*)URLString
           studyUID:(NSString*)studyUID
            timeout:(NSTimeInterval)timeout;

@end
