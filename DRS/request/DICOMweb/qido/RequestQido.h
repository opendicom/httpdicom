#import <Foundation/Foundation.h>

//NS_ASSUME_NONNULL_BEGIN

@interface RequestQido : NSObject

typedef NS_ENUM(NSUInteger, qidoAccept) {
   qidoDefault = 0,
   qidoJSON,
   qidoXML
};//qidoDefault is implicitly qidoJSON 

+(NSMutableURLRequest*)foundInPacs:(NSDictionary*)pacs
                         URLString:(NSMutableString*)URLString
                     fuzzymatching:(BOOL)fuzzymatching
                             limit:(unsigned int)limit
                            offset:(unsigned int)offset
                            accept:(qidoAccept)accept
;

+(NSMutableURLRequest*)foundInPacs:(NSDictionary*)pacs
                         URLString:(NSMutableString*)URLString
;

+(NSMutableURLRequest*)studiesFoundInPacs:(NSDictionary*)pacs
                          accessionNumber:(NSString*)accessionNumber
                          accessionIssuer:(NSString*)accessionIssuer
                            accessionType:(NSString*)accessionType
;


+(NSMutableURLRequest*)objectsFoundInPacs:(NSDictionary*)pacs
                                 studyUID:(NSString*)studyUID
                                seriesUID:(NSString*)seriesUID
                                   sopUID:(NSString*)sopUID
;

@end

//NS_ASSUME_NONNULL_END
