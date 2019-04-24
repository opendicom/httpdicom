#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RequestQidoStudy : NSObject

+(NSMutableURLRequest*)toPacs:(NSDictionary*)pacs
                     studyUID:(NSString*)studyUID;

@end

NS_ASSUME_NONNULL_END
