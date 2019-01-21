#import "DRS.h"

@interface DRS (functions)

//request type
int requestParams(RSRequest* request, NSMutableArray *names, NSMutableArray *values, NSMutableArray *types, NSString **errorString);

int parseRequestParams(RSRequest* request, NSMutableString *jsonString, NSMutableArray *names, NSMutableArray *values, NSMutableArray *types, NSString **errorString);

//task
int bash(NSData *writeData, NSMutableData *readData);
int task(NSString *launchPath, NSArray *launchArgs, NSData *writeData, NSMutableData *readData);


//charset
NSMutableArray *jsonMutableArray(NSString *scriptString, NSStringEncoding encoding);

//proxy
id qidoUrlProxy(NSString *qidoString,NSString *queryString, NSString *httpdicomString);

id urlChunkedProxy(NSString *urlString,NSString *contentType);

@end
