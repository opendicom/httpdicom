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

-(NSArray*)componentsSlashOrBackSlashSeparated;

//pacsUID required por requestProcudure, nil for spsxProtocol
/*
 verifies if this is a valid codified reqProcedure or spsxProtocol
 - returns an array of three elements if a code was discovered
 - returns un array of one element equal to the description it there is no clear correspondence with a code
 - returns nil if the description contains |
 */
-(NSArray*)procedureCodeArrayForContextPacs:(NSString*)pacsUID;
-(NSArray*)protocolCodeArray;

@end
