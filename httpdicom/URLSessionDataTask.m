//
//  URLSessionDataTask.m
//  httpdicom
//
//  Created by jacquesfauquex on 2016-11-01.
//  Copyright © 2016 ridi.salud.uy. All rights reserved.
//

#import "URLSessionDataTask.h"
#import "GCDWebServerStreamedResponse.h"

@implementation URLSessionDataTask

-(id)proxySession:(NSURLSession*)session URI:(NSString*)urlString contentType:(NSString*)contentType
{
    dataPile=[NSMutableArray array];
    uuid_t uuid;
    [[NSUUID UUID]getUUIDBytes:uuid];
    dataEnd=[NSData dataWithBytes:uuid length:16];
    __block NSURLSessionDataTask * const __URLSessionDataTask = [session dataTaskWithURL:[NSURL URLWithString:urlString]];
    //__block bool __shouldExit = false;
    [__URLSessionDataTask resume];
    GCDWebServerStreamedResponse* response = [GCDWebServerStreamedResponse responseWithContentType:contentType asyncStreamBlock:^(GCDWebServerBodyReaderCompletionBlock completionBlock){
        //while (!__shouldExit && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]])
        
        if ([dataPile count]>0)
        {
            if([dataPile[0] isEqualToData:dataEnd]) completionBlock([NSData data], nil);
            else completionBlock(dataPile[0], nil);
            [dataPile removeObjectAtIndex:0];
        }
        else completionBlock(nil,nil);
      }];
    return response;
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    if (data.length) [dataPile addObject:data];
    else [dataPile addObject:dataEnd];
}
/*
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler
{
    
}
*/

/*
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
     location
     A file URL for the temporary file. Because the file is temporary, you must either open the file for reading or move it to a permanent location in your app’s sandbox container directory before returning from this delegate method.
     
     If you choose to open the file for reading, you should do the actual reading in another thread to avoid blocking the delegate queue.
 
}
*/
@end
