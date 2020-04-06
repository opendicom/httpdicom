#import "NSURLSessionDataTask+DRS.h"

NS_ASSUME_NONNULL_BEGIN

@interface ResponseMwlitems : NSObject

// [] no existe
// [{}] existe y es único
// [{},{}...] existen y no son únicos
+(NSArray*)getFromPacs:(NSDictionary*)pacs
       accessionNumber:(NSString*)an
;

@end

NS_ASSUME_NONNULL_END
