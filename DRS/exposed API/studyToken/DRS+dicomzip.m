#import "DRS+dicomzip.h"
#import "DRS+studyToken.h"

@implementation DRS (dicomzip)

+(void)dicomzipSql4dictionary:(NSDictionary*)d
{
   NSString *devOID=d[@"devOID"];
   NSString *path=[d[@"path"] stringByAppendingPathComponent:devOID];
   NSError  *error=nil;
}
@end
