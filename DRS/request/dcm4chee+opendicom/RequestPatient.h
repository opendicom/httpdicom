#import "NSMutableURLRequest+DRS.h"

NS_ASSUME_NONNULL_BEGIN

@interface RequestPatient : NSObject

+(NSMutableURLRequest*)existsInPacs:(NSDictionary*)pacs
                    pid:(NSString*)pid
                 issuer:(NSString*)issuer
       returnAttributes:(BOOL)returnAttributes
;


@end

NS_ASSUME_NONNULL_END
