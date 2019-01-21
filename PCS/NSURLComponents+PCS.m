#import "NSURLComponents+PCS.h"

@implementation NSURLComponents (PCS)


-(NSMutableArray*)valuesForParameter:(NSString*)parameter belongingTo:(NSDictionary*)knownPacs
{
    NSMutableArray *values=[NSMutableArray array];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K=%@",@"name",parameter];
    for (NSURLQueryItem *item in self.queryItems)
    {
        if ([predicate evaluateWithObject:item] && knownPacs[item.value]) [values addObject:item.value];
    }
    return values;
}

/*
-(NSInteger)nextQueryItemsIndexForPredicateString:(NSString*)predicateString key:(NSString*)key value:(NSString*)value startIndex:(NSInteger)startIndex
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString,key,value];
    if (startIndex < 0) return NSNotFound;
    while (startIndex < [self.queryItems count]) {
        if ([predicate evaluateWithObject:self.queryItems[startIndex]]) return startIndex;
        startIndex++;
    }
    return NSNotFound;
}
*/
-(NSString*)firstQueryItemNamed:(NSString*)name
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K=%@",@"name",name];
    for (NSURLQueryItem *item in self.queryItems)
    {
        if ([predicate evaluateWithObject:item]) return item.value;
    }
    return nil;
}

-(NSString*)queryWithoutItemNamed:(NSString*)name
{
    NSMutableString *q=[NSMutableString string];
    NSUInteger c=[self.queryItems count];
    if (c==0)return @"";
    for (int i=0; i<[self.queryItems count];i++)
    {
        if (![self.queryItems[i].name isEqualToString:name])[q appendFormat:@"%@=%@&",self.queryItems[i].name,self.queryItems[i].value];
    }
    [q deleteCharactersInRange:NSMakeRange([q length]-1,1)];
    return [NSString stringWithString:q];
}


@end
