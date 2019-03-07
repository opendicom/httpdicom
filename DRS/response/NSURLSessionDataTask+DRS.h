#import <Foundation/Foundation.h>

@interface NSURLSessionDataTask (PCS)

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error;

@end
