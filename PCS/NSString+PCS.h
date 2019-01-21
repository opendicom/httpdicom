#import <Foundation/Foundation.h>

@interface NSString (PCS)
+(NSString*)regexDicomString:(NSString*)dicomString withFormat:(NSString*)formatString;
+(NSString*)mysqlEscapedFormat:(NSString*)format fieldString:(NSString*)field valueString:(NSString*)value;
+(NSString*)stringFromSockAddr:(const struct sockaddr*)addr includeService:(BOOL)includeService;
-(NSString*)sqlFilterWithStart:(NSString*)start end:(NSString*)end;
-(NSString*)MD5String;
-(NSString*)normalizeHeaderValue;
-(NSString*)valueForName:(NSString*)name;
-(NSString*)dcmDaFromDate;
-(NSString*)spaceNormalize;

@end
