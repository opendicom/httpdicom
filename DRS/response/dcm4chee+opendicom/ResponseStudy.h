#import "NSURLSessionDataTask+DRS.h"

NS_ASSUME_NONNULL_BEGIN

@interface ResponseStudy : NSObject

+(NSDictionary*)existsInPacs:(NSDictionary*)pacs
             accessionNumber:(NSString*)an
                 issuerLocal:(NSString*)issuerLocal
             issuerUniversal:(NSString*)issuerUniversal
                  issuerType:(NSString*)issuerType
            returnAttributes:(BOOL)returnAttributes;


+(NSArray*)existsInPacs:(NSDictionary*)pacs
               studyUID:(NSString*)studyUID
              seriesUID:(NSString*)seriesUID
                 sopUID:(NSString*)sopUID
       returnAttributes:(BOOL)returnAttributes;


@end

NS_ASSUME_NONNULL_END
