#import "NSMutableArray+JSON.h"
#import "ODLog.h"

/*
 NSJSONReadingMutableContainers
 -> Specifies that arrays and dictionaries are created as mutable objects.
 
 NSJSONReadingMutableLeaves
 -> Specifies that leaf strings in the JSON object graph are created as instances of NSMutableString.
 
 NSJSONReadingAllowFragments
 -> Specifies that the parser should allow top-level objects that are not an instance of NSArray or NSDictionary.
 */

@implementation NSMutableArray (PCS)

+(NSMutableArray *)mutableArrayWithJsonData:(NSData *)data
{
   if (!data) return nil;
   if (![data length]) return [NSMutableArray array];
   NSError *error;
   NSMutableArray *array=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
   if (error)
   {
      LOG_WARNING(@"json data not array:\r\n%@\r\n%@", [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding],[error description]);
      return nil;
   }
   return array;
   
}

#pragma mark - array of dicts

- (NSMutableDictionary *)firstMutableDictionaryWithKey:(NSString*)key isEqualToNumber:(NSNumber*)number;
{
    for (NSMutableDictionary *dict in self)
    {
       if ([dict[key] isEqualToNumber:number]) return dict;
    }
    return nil;
}

- (NSMutableDictionary *)firstMutableDictionaryWithKey:(NSString*)key isEqualToString:(NSString*)string
{
    for (NSMutableDictionary *dict in self)
    {
       if ([dict[key] isEqualToString:string]) return dict;
    }
    return nil;
}

#pragma mark - array of arrays

- (NSMutableArray *)firstMutableArrayWithObjectAtIndex:(NSUInteger)index isEqualToNumber:(NSNumber*)number
{
    for (NSMutableArray *array in self)
    {
       if ([array[index] isEqualToNumber:number]) return array;
    }
    return nil;
}


- (NSMutableArray *)firstMutableArrayWithObjectAtIndex:(NSUInteger)index isEqualToString:(NSString*)string
{
    for (NSMutableArray *array in self)
    {
       if ([array[index] isEqualToString:string]) return array;
    }
    return nil;
}


@end
