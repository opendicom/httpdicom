//when accessionType is empty (@""), accessionIssuer is local, else is universal

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RequestStudy : NSObject


+(NSMutableURLRequest*)existsInPacs:(NSDictionary*)pacs
                    accessionNumber:(NSString*)accessionNumber
                    accessionIssuer:(NSString*)accessionIssuer
                      accessionType:(NSString*)accessionType
                   returnAttributes:(BOOL)returnAttributes
;


+(NSMutableURLRequest*)existsInPacs:(NSDictionary*)pacs
                           studyUID:(NSString*)studyUID
                          seriesUID:(NSString*)seriesUID
                             sopUID:(NSString*)sopUID
                   returnAttributes:(BOOL)returnAttributes
;

@end

NS_ASSUME_NONNULL_END
