//
//  NSMutableURLRequest+studies.m
//  httpdicom
//
//  Created by jacquesfauquex on 2017129.
//  Copyright © 2017 opendicom.com. All rights reserved.
//

#import "NSMutableURLRequest+studies.h"

@implementation NSMutableURLRequest (studies)


+(id)GETqidostudies:(NSString*)URLString
           studyUID:(NSString*)studyUID
            timeout:(NSTimeInterval)timeout
{
    if (!URLString || ![URLString length]) return nil;
    if (!studyUID  || ![studyUID length]) return nil;
    id request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?StudyInstanceUID=%@",URLString,studyUID]]
                                      cachePolicy:NSURLRequestReloadIgnoringCacheData
                                     timeoutInterval:timeout];
    // https://developer.apple.com/reference/foundation/nsurlrequestcachepolicy?language=objc;
    //NSURLRequestReturnCacheDataElseLoad
    //NSURLRequestReloadIgnoringCacheData
    [request setHTTPMethod:@"GET"];
    return request;
}

@end
