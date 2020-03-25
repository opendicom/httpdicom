#import "NSURLSessionDataTask+DRS.h"
#import "RequestQido.h"

//NS_ASSUME_NONNULL_BEGIN

@interface ResponseQido : NSObject

/*
typedef NS_ENUM(NSUInteger, qidoAccept) {
   qidoDefault = 0,
   qidoJSON,
   qidoXML
};//qidoDefault is implicitly qidoJSON
*/

// [] no existe
// [{}] existe y es único
// [{},{}...] existen y no son únicos
+(NSArray*)foundInPacs:(NSDictionary*)pacs
             URLString:(NSMutableString*)URLString
         fuzzymatching:(BOOL)fuzzymatching
                 limit:(unsigned int)limit
                offset:(unsigned int)offset
                accept:(qidoAccept)accept
;

+(NSArray*)foundInPacs:(NSDictionary*)pacs
             URLString:(NSMutableString*)URLString
;

+(NSArray*)studiesFoundInPacs:(NSDictionary*)pacs
              accessionNumber:(NSString*)accessionNumber
              accessionIssuer:(NSString*)accessionIssuer
                accessionType:(NSString*)accessionType
;


+(NSArray*)objectsFoundInPacs:(NSDictionary*)pacs
                     studyUID:(NSString*)studyUID
                    seriesUID:(NSString*)seriesUID
                       sopUID:(NSString*)sopUID
;

@end

//NS_ASSUME_NONNULL_END
