#import "DRS+cornerstone.h"
#import "DRS+studyToken.h"

@implementation DRS (cornerstone)

+(void)cornerstoneSql4dictionary:(NSDictionary*)d
{
   NSString *devOID=d[@"devOID"];
   NSString *path=[d[@"path"] stringByAppendingPathComponent:devOID];
   NSError  *error=nil;
}
@end
