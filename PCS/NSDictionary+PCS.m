#import "NSDictionary+PCS.h"
#import "ODLog.h"

@implementation NSDictionary (PCS)

+(NSDictionary * )da4dd:(NSDictionary * )dd
{
    if (![dd count]) return nil;
    NSArray *dkeys=[dd allKeys];
    NSArray *ddkeys=[dd[dkeys[0]] allKeys];
    NSArray *keys=[@[@"key"] arrayByAddingObjectsFromArray:ddkeys];

 
    //create mutabledictionary of mutablearrays
    NSMutableDictionary *mdma=[NSMutableDictionary dictionary];
    for (NSString *k in keys)
    {
        [mdma setObject:[NSMutableArray array] forKey:k];
    }
    
    //fill up mutablearrays
    for (NSString *dk in dkeys)
    {
        [mdma[@"key"] addObject:dk];
        NSDictionary *kd=dd[dk];
        for (NSString *ddk in ddkeys)
        {
            [mdma[ddk] addObject:kd[ddk]];
        }
    }
    
    //create mutabledictionary of arrays
    NSMutableDictionary *mda=[NSMutableDictionary dictionary];
    for (NSString *k in keys)
    {
        [mda setObject:[NSArray arrayWithArray:mdma[k]] forKey:k];
    }

    //create return dictionary of arrays
    return [NSDictionary dictionaryWithDictionary:mda];
}

+(NSDictionary * )da4ad:(NSArray * )ad
{
   if (![ad count]) return nil;
   NSArray *keys=[ad[0] allKeys];
   
   //create mutabledictionary of mutablearrays
   NSMutableDictionary *mdma=[NSMutableDictionary dictionary];
   for (NSString *k in keys)
   {
      [mdma setObject:[NSMutableArray array] forKey:k];
   }
   
   //fill up mutablearrays
   for (NSDictionary *d in ad)
   {
      for (NSString *k in keys)
      {
         [mdma[k] addObject:d[k]];
      }
   }
   
   //create mutabledictionary of arrays
   NSMutableDictionary *mda=[NSMutableDictionary dictionary];
   for (NSString *k in keys)
   {
      [mda setObject:[NSArray arrayWithArray:mdma[k]] forKey:k];
   }
   
   //create return dictionary of arrays
   return [NSDictionary dictionaryWithDictionary:mda];
}

/*
 NSJSONReadingMutableContainers
 -> Specifies that arrays and dictionaries are created as mutable objects.
 
 NSJSONReadingMutableLeaves
 -> Specifies that leaf strings in the JSON object graph are created as instances of NSMutableString.
 
 NSJSONReadingAllowFragments
 -> Specifies that the parser should allow top-level objects that are not an instance of NSArray or NSDictionary.
 */

+(NSDictionary * )dictionaryWithJsonData:(NSData * )data
{
   if (!data) return nil;
   if (![data length]) return @{};
   NSError *error;
   NSDictionary *dictionary=[NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
   if (error)
   {
      LOG_WARNING(@"json data not dictionary:\r\n%@\r\n%@", [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding],[error description]);
      return nil;
   }
   return dictionary;
}

@end
