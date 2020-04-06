#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableArray (JSON)

+(NSMutableArray *)mutableArrayWithJsonData:(NSData *)data;

#pragma mark - array of dicts
- (NSMutableDictionary *)firstMutableDictionaryWithKey:(NSString*)key isEqualToNumber:(NSNumber*)number;

- (NSMutableDictionary *)firstMutableDictionaryWithKey:(NSString*)key isEqualToString:(NSString*)string;

#pragma mark - array of arrays

- (NSMutableArray *)firstMutableArrayWithObjectAtIndex:(NSUInteger)index isEqualToNumber:(NSNumber*)number;

- (NSMutableArray *)firstMutableArrayWithObjectAtIndex:(NSUInteger)index isEqualToString:(NSString*)string;

@end

NS_ASSUME_NONNULL_END
