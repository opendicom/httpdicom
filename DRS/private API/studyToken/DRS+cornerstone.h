#import "DRS.h"

NS_ASSUME_NONNULL_BEGIN

@interface DRS (cornerstone)

+(NSString*)cornerstoneForRefinedRequest:(NSDictionary*)refinedRequest;

+(RSResponse*)cornerstoneManifest:(NSMutableString*)manifest session:(NSString*)session proxyURI:(NSString*)proxyURI acceptsGzip:(BOOL)acceptsGzip;

+(void)cornerstoneSql4dictionary:(NSDictionary*)d;

@end

NS_ASSUME_NONNULL_END
