#import <Foundation/Foundation.h>
#import "ODLog.h"
#import "K.h"
#import "DICMTypes.h"

#import "RS.h"
#import "RSDataResponse.h"
#import "RSErrorResponse.h"
#import "RSFileResponse.h"
#import "RSStreamedResponse.h"

//RSRequest

BOOL parseRequestParams(RSRequest       *  request,
                        NSMutableArray  *  names,
                        NSMutableArray  *  values,
                        NSMutableArray  *  types,
                        NSString        ** jsonString,
                        NSString        ** errorString
                        )
;

//pacs
NSDictionary * pacsParam(NSMutableArray  *  names,
                         NSMutableArray  *  values,
                         NSMutableString *  pacsOID,
                         NSString        ** errorString
                         )
;


//task
int bash(NSData *writeData, NSMutableData *readData);
int task(NSString *launchPath, NSArray *launchArgs, NSData *writeData, NSMutableData *readData);


//charset
NSMutableArray *jsonMutableArray(NSString *scriptString, NSStringEncoding encoding);

//proxy
id qidoUrlProxy(NSString *qidoString,NSString *queryString, NSString *httpdicomString);

id urlChunkedProxy(NSString *urlString,NSString *contentType);


@interface DRS : RS

@property (class, nonatomic, readonly) NSDictionary          *sqls;
@property (class, nonatomic, readonly) NSDictionary          *pacs;
@property (class, nonatomic, readonly, assign) long long      drsport;
@property (class, nonatomic, readonly) NSString              *defaultpacsoid;
@property (class, nonatomic, readonly) NSDictionary          *oids;
@property (class, nonatomic, readonly) NSDictionary          *titles;
@property (class, nonatomic, readonly) NSData                *oidsdata;
@property (class, nonatomic, readonly) NSData                *titlesdata;
@property (class, nonatomic, readonly) NSDictionary          *oidsaeis;
@property (class, nonatomic, readonly) NSDictionary          *titlesaets;
@property (class, nonatomic, readonly) NSDictionary          *titlesaetsstrings;
@property (class, nonatomic, readonly) NSDictionary          *pacsaetDictionary;
@property (class, nonatomic, readonly) NSArray               *localoids;
@property (class, nonatomic, readonly) NSDictionary          *custodianDictionary;

int task(NSString *launchPath, NSArray *launchArgs, NSData *writeData, NSMutableData *readData);

-(id)initWithSqls:(NSDictionary*)sqls
             pacs:(NSDictionary*)pacs
          drsport:(long long)drsport
          defaultpacsoid:(NSString*)defaultpacsoid;

@end
