#import <Foundation/Foundation.h>

@interface NSMutableURLRequest (studies)

+(id)GETqidostudies:(NSString*)URLString
           studyUID:(NSString*)studyUID
            timeout:(NSTimeInterval)timeout;

@end
