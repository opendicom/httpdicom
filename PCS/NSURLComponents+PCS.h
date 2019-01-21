#import <Foundation/Foundation.h>

@interface NSURLComponents (PCS)

-(NSMutableArray*)valuesForParameter:(NSString*)parameter belongingTo:(NSDictionary*)knownPacs;

//-(NSInteger)nextQueryItemsIndexForPredicateString:(NSString*)predicateString key:(NSString*)key value:(NSString*)value startIndex:(NSInteger)startIndex;

-(NSString*)firstQueryItemNamed:(NSString*)name;

-(NSString*)queryWithoutItemNamed:(NSString*)name;

@end
