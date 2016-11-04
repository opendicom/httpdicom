//
//  URLSessionDataTask.h
//  httpdicom
//
//  Created by jacquesfauquex on 2016-11-01.
//  Copyright © 2016 ridi.salud.uy. All rights reserved.
//
@import Foundation;

NS_ASSUME_NONNULL_BEGIN
typedef void (^CompletionHandler)();

@interface URLSessionDataTask : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>
{
    NSMutableArray *dataPile;
    NSData *dataEnd;
}

//, NSURLSessionDownloadDelegate, NSURLSessionStreamDelegate
@property NSMutableDictionary <NSString *, CompletionHandler>*completionHandlers;


-(id)proxySession:(NSURLSession*)session URI:(NSString*)urlString contentType:(NSString*)contentType;

@end
NS_ASSUME_NONNULL_END
