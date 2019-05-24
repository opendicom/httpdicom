#import "NSString+ZDS.h"

#import "NSUUID+DICM.h"

@implementation NSString(ZDS)

+(NSString*)isrStudyIUID:(NSString*)ZDS_1
{
   if (!ZDS_1)ZDS_1=[[NSUUID UUID]ITUTX667UIDString];
   return [NSString stringWithFormat:@"ZDS|%@",ZDS_1];
}

@end
