#import "DRS.h"

NS_ASSUME_NONNULL_BEGIN

@interface DRS (weasis)

+(NSString*)weasisArcQueryForRefinedRequest:(NSDictionary*)d;
+(RSResponse*)weasisManifest:(NSMutableString*)manifest session:(NSString*)session proxyURI:(NSString*)proxyURI acceptsGzip:(BOOL)acceptsGzip;

+(void)weasisSql4dictionary:(NSDictionary*)d;

@end

NS_ASSUME_NONNULL_END
