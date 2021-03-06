#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RequestJSONMetadata : NSObject


+(NSMutableURLRequest*)requestFromPacs:(NSDictionary*)pacs
                      StudyInstanceUID:(NSString*)euid
;


+(NSMutableURLRequest*)requestFromPacs:(NSDictionary*)pacs
                      StudyInstanceUID:(NSString*)euid
                     SeriesInstanceUID:(NSString*)suid
;


+(NSMutableURLRequest*)requestFromPacs:(NSDictionary*)pacs
                      StudyInstanceUID:(NSString*)euid
                     SeriesInstanceUID:(NSString*)suid
                        SOPInstanceUID:(NSString*)iuid
;



@end

NS_ASSUME_NONNULL_END
