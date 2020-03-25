#import "DRS.h"

NS_ASSUME_NONNULL_BEGIN

@interface DRS (dicomzip)

+(void)dicomzipSql4d:(NSDictionary*)d;
//+(RSResponse*)dicomzipChunks4dictionary:(NSDictionary*)d;

@end

NS_ASSUME_NONNULL_END
