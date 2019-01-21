#import <Foundation/Foundation.h>

@interface NSMutableURLRequest (instance)

+(id)GETwadorsinstancemetadataxml:(NSString*)URLString
                       studyUID:(NSString*)studyUID
                      seriesUID:(NSString*)seriesUID
                        SOPIUID:(NSString*)SOPIUID
                        timeout:(NSTimeInterval)timeout
;

@end
