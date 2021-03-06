#import <Foundation/Foundation.h>
#import "ODLog.h"
#import "K.h"
#import "DICMTypes.h"

#import "RS.h"
#import "RSDataResponse.h"
#import "RSErrorResponse.h"
#import "RSFileResponse.h"
#import "RSStreamedResponse.h"


enum dt {
   dt_,
   dtSurl,
   dtED,
   dtPurl,
   dtPN,
   dtEdatetime,
   dtEQAmods,
   dtEdesc,
   dtERN,
   dtEsoc,
   dtPII,
   dtPdate,
   dtPsex,
   dtEA,
   dtEAI,
   dtEI,
   dtEU,
   dtEtime,
   dtEinst,
   dtP,
   dtE,
   dtEpacs,
   dtQcache,
   dtPI,
   dtEdate,
   dtEQAseries,
   dtEQAobjects,
   dtEAU,
   dtEAT
};


//RSRequest

NSString *  parseRequestParams(RSRequest       *  request,
                               NSMutableArray  *  names,
                               NSMutableArray  *  values
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
int execUTF8Bash(NSDictionary *environment, NSString *writeString, NSMutableData *readData);
int execTask(NSDictionary *environment, NSString *launchPath, NSArray *launchArgs, NSData *writeData, NSMutableData *readData);

int bash(NSData *writeData, NSMutableData *readData);
int task(NSString *launchPath, NSArray *launchArgs, NSData *writeData, NSMutableData *readData);


//charset
NSMutableArray *jsonMutableArray(NSString *scriptString, NSStringEncoding encoding);

//proxy
id qidoUrlProxy(NSString *qidoString,NSString *queryString, NSString *httpdicomString);

id urlChunkedProxy(NSString *urlString,NSString *contentType);


@interface DRS : RS

@property (class, nonatomic, readonly) NSDictionary      *sqls;
@property (class, nonatomic, readonly, assign) long long  drsport;
@property (class, nonatomic, readonly) NSString          *defaultpacsoid;
@property (class, nonatomic, readonly) NSString          *tmpDir;
@property (class, nonatomic, readonly) NSString          *tokentmpDir;

@property (class, nonatomic, readonly) NSDictionary      *oids;
@property (class, nonatomic, readonly) NSDictionary      *titles;
@property (class, nonatomic, readonly) NSData            *oidsdata;
@property (class, nonatomic, readonly) NSData            *titlesdata;
@property (class, nonatomic, readonly) NSDictionary      *oidsaeis;
@property (class, nonatomic, readonly) NSDictionary      *titlesaets;
@property (class, nonatomic, readonly) NSDictionary      *titlestitlesaets;
@property (class, nonatomic, readonly) NSDictionary      *titlesaetsstrings;

//triple key oid, custodianAet.aet, index

@property (class, nonatomic, readonly) NSDictionary      *pacs;
@property (class, nonatomic, readonly) NSData            *pacskeysdata;

@property (class, nonatomic, readonly) NSArray           *wan;//proxying to pcs
@property (class, nonatomic, readonly) NSArray           *lan;//every local
@property (class, nonatomic, readonly) NSArray           *dev;//a specific local

@property (class, nonatomic, readonly) NSArray           *InstanceUniqueFrameSOPClass;
@property (class, nonatomic, readonly) NSArray           *InstanceMultiFrameSOPClass;

-(id)initWithSqls:(NSDictionary*)sqls
             pacs:(NSArray*)pacs
          drsport:(long long)drsport
   defaultpacsoid:(NSString*)defaultpacsoid
        tmpDir:(NSString*)tmpDir
;

@end
