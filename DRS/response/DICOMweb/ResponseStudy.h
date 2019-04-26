#import "NSURLSessionDataTask+DRS.h"

NS_ASSUME_NONNULL_BEGIN

@interface ResponseStudy : NSObject

//return an array of zero or more objects
//return nil in case of error

+(NSArray*)existsInPacs:(NSDictionary*)pacs
             accessionNumber:(NSString*)accessionNumber
             accessionIssuer:(NSString*)accessionIssuer
               accessionType:(NSString*)accessionType
            returnAttributes:(BOOL)returnAttributes
;

+(NSArray*)existsInPacs:(NSDictionary*)pacs
               studyUID:(NSString*)studyUID
              seriesUID:(NSString*)seriesUID
                 sopUID:(NSString*)sopUID
       returnAttributes:(BOOL)returnAttributes;

@end

NS_ASSUME_NONNULL_END
