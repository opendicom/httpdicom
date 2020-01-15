#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableArray (JSON)

+(NSMutableArray *)mutableArrayWithJsonData:(NSData *)data;

- (NSMutableDictionary *)firstMutableDictionaryWithKey:(NSString*)key isEqualToNumber:(NSNumber*)number;

- (NSMutableDictionary *)firstMutableDictionaryWithKey:(NSString*)key isEqualToString:(NSString*)string;

@end

NS_ASSUME_NONNULL_END
