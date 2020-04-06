#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface NSArray (PCS)

+(NSArray *)arrayWithJsonData:(NSData *)data;

-(NSUInteger)nextIndexOfE4P:(NSString*)P startingAtIndex:(NSUInteger)startingIndex;

@end

NS_ASSUME_NONNULL_END
