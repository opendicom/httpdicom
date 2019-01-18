#import "DRSOperation.h"

/*
 URLRequests
 
 cachePolicy
 timeoutInterval
 
 return format

 {
 "querystring":"",
 "title":"",
 "RepositoryUniqueID":"",
 "timezone":"",
 "indexfield":i,
 "offset":o,
 "limit":s
 "level":l
 "format":f

 "X-Result-Count":x,
 "studydatetime":[ll],
 "StudyInstanceUID":[""],
 "SeriesNumber":[ll],
 "SeriesInstanceUID":[""],
 "InstanceNumber":[ll],
 "SOPInstanceUID":[""],

 "indexstrings":[],
 
 "items":[],
 
 "status":""
 }
 
 Nota: Series and Instanca arrays are included in the response (or not), depending on level
 */

@interface APathRestOperation : DRSOperation
{
    NSMutableArray *indexString;
    NSMutableArray *items;
}

- (instancetype)initWithURLstring:(NSString*)URLstring
                      cachePolicy:(NSURLRequestCachePolicy)cachePolicy
                  timeoutInterval:(NSTimeInterval)timeoutInterval
                            title:(NSString*)title
               RepositoryUniqueID:(NSString*)RepositoryUniqueID
                         timezone:(NSString*)timezone
                            level:(NSUInteger)level
                       indexfield:(NSUInteger)indexfield
                           offset:(NSUInteger)offset
                            limit:(NSUInteger)limit
;

- (NSDictionary*)results;
@end
