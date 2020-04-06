#import "NSArray+PCS.h"
#import "ODLog.h"

/*
 NSJSONReadingMutableContainers
 -> Specifies that arrays and dictionaries are created as mutable objects.
 
 NSJSONReadingMutableLeaves
 -> Specifies that leaf strings in the JSON object graph are created as instances of NSMutableString.
 
 NSJSONReadingAllowFragments
 -> Specifies that the parser should allow top-level objects that are not an instance of NSArray or NSDictionary.
 */
@implementation NSArray (PCS)

+(NSArray *)arrayWithJsonData:(NSData *)data
{
   if (!data) return nil;
   if (![data length]) return @[];
   NSError *error;
   NSArray *array=[NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
   if (error)
   {
      LOG_WARNING(@"json data not array:\r\n%@\r\n%@", [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding],[error description]);
      return nil;
   }
   return array;
}

-(NSUInteger)nextIndexOfE4P:(NSString*)P startingAtIndex:(NSUInteger)startingIndex
{
    NSUInteger i=startingIndex;
    while (i < self.count)
    {
        if ([(self[i])[19] isEqualToString:P]) return i;
    }
    return NSNotFound;
}
@end
