#import "NSMutableDictionary+PCS.h"
#import "ODLog.h"

@implementation NSMutableDictionary (PCS)

/*
 NSJSONReadingMutableContainers
 -> Specifies that arrays and dictionaries are created as mutable objects.
 
 NSJSONReadingMutableLeaves
 -> Specifies that leaf strings in the JSON object graph are created as instances of NSMutableString.
 
 NSJSONReadingAllowFragments
 -> Specifies that the parser should allow top-level objects that are not an instance of NSArray or NSDictionary.
 */

+(NSMutableDictionary *)dictionaryWithJsonData:(NSData *)data
{
   if (!data) return nil;
   if (![data length]) return [NSMutableDictionary dictionary];
   NSError *error;
   NSMutableDictionary *dictionary=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
   if (error)
   {
      LOG_WARNING(@"json data not dictionary:\r\n%@\r\n%@", [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding],[error description]);
      return nil;
   }
   return dictionary;
}

@end
