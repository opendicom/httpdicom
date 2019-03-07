#import "RequestPOSTEncapsulated.h"

#import "NSMutableURLRequest+DRS.h"

@implementation RequestPOSTEncapsulated



+(NSMutableURLRequest*)toPacs:(NSDictionary*)pacs
                 dicomSubtype:(NSString*)dicomSubType
               boundaryString:(NSString*)boundaryString
                     bodyData:(NSData*)bodyData
{
   return [NSMutableURLRequest
           DRSRequestPacs:pacs
           URLString:[NSMutableString stringWithString:[pacs[@"wadors"] stringByAppendingPathComponent:@"studies"]]
           method:@"POST"
           contentType:[NSString stringWithFormat:@"multipart/related; type=application/dicom%@; boundary=%@",dicomSubType,boundaryString]
           bodyData:bodyData
           accept:@""
           ];
}

@end
