#import <Foundation/Foundation.h>
#import "ODLog.h"
#import "K.h"
#import "DICMTypes.h"

#import "RS.h"
#import "RSDataResponse.h"
#import "RSErrorResponse.h"
#import "RSFileResponse.h"
#import "RSStreamedResponse.h"

static uint32 zipLocalFileHeader=0x04034B50;
static uint16 zipVersion=0x0A;
static uint32 zipNameLength=0x28;
static uint32 zipFileHeader=0x02014B50;
static uint32 zipEndOfCentralDirectory=0x06054B50;


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

//for /custodina and /pacs service
@property (class, nonatomic, readonly) NSDictionary      *oids;
@property (class, nonatomic, readonly) NSDictionary      *titles;
@property (class, nonatomic, readonly) NSData            *oidsdata;
@property (class, nonatomic, readonly) NSData            *titlesdata;
@property (class, nonatomic, readonly) NSDictionary      *oidsaeis;
@property (class, nonatomic, readonly) NSDictionary      *titlesaets;//aets 4 title
//triple key oid, custodianAet.aet, index
@property (class, nonatomic, readonly) NSDictionary      *pacs;
@property (class, nonatomic, readonly) NSData            *pacskeysdata;


@property (class, nonatomic, readonly) NSSet           *wan;//proxying to pcs
@property (class, nonatomic, readonly) NSSet           *lan;//custodian or pacs local (if needsaccesscontrol is false)
@property (class, nonatomic, readonly) NSSet           *lanDeduplicated;//when custodinatitle=aet in the first item of the list, this pacs sums up all the other local pacs which start with the same url

//multiframe sop classes
@property (class, nonatomic, readonly) NSArray           *InstanceUniqueFrameSOPClass;
@property (class, nonatomic, readonly) NSArray           *InstanceMultiFrameSOPClass;

-(id)initWithSqls:(NSDictionary*)sqls
             pacs:(NSArray*)pacs
          drsport:(long long)drsport
   defaultpacsoid:(NSString*)defaultpacsoid
        tmpDir:(NSString*)tmpDir
;

@end
