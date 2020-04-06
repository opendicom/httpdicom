#import <Foundation/Foundation.h>

@interface NSURLSessionDataTask (DRS)

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error;

@end
