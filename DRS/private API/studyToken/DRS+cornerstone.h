#import "DRS.h"

NS_ASSUME_NONNULL_BEGIN

@interface DRS (cornerstone)

+(NSData*)cornerstoneForRefinedRequest:(NSDictionary*)refinedRequest;

+(void)cornerstoneSql4dictionary:(NSDictionary*)d;

@end

NS_ASSUME_NONNULL_END
