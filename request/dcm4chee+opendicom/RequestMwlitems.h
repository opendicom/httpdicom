#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RequestMwlitems : NSObject

+(NSMutableURLRequest*)getFromPacs:(NSDictionary*)pacs
                   accessionNumber:(NSString*)an
;

@end

NS_ASSUME_NONNULL_END
