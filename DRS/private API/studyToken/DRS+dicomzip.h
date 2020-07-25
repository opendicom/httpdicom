#import "DRS.h"

NS_ASSUME_NONNULL_BEGIN

@interface DRS (dicomzip)

+(void)addSeriesPathFor:(NSDictionary*)d toArray:(NSMutableArray*)mutableArray;

+(RSResponse*)dicomzipStreamForSeriesPaths:(NSArray*)array;

@end

NS_ASSUME_NONNULL_END
