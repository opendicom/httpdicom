#import "DRS.h"

#import "DRS+wado.h"
#import "DRS+pacs.h"
//#import "DRS+qido.h"
#import "DRS+wadors.h"
#import "DRS+zipped.h"

#import "DRS+mwl.h"
#import "DRS+pdf.h"

#import "DICMTypes.h"

@implementation DRS

static NSDictionary        *_sqls=nil;
static NSDictionary        *_pacs=nil;
static long long           _drsport;
static NSString            *_defaultpacsoid;

static NSDictionary        *_oids=nil;
static NSDictionary        *_titles=nil;
static NSData              *_oidsdata=nil;
static NSData              *_titlesdata=nil;
static NSDictionary        *_oidsaeis=nil;
static NSDictionary        *_titlesaets=nil;
static NSDictionary        *_titlesaetsstrings=nil;
static NSDictionary        *_pacsaetDictionary=nil;
static NSArray             *_localoids=nil;
static NSDictionary        *_custodianDictionary=nil;


int task(NSString *launchPath, NSArray *launchArgs, NSData *writeData, NSMutableData *readData)
{
   NSTask *task=[[NSTask alloc]init];
   [task setLaunchPath:launchPath];
   [task setArguments:launchArgs];
   //LOG_INFO(@"%@",[task arguments]);
   NSPipe *writePipe = [NSPipe pipe];
   NSFileHandle *writeHandle = [writePipe fileHandleForWriting];
   [task setStandardInput:writePipe];
   
   NSPipe* readPipe = [NSPipe pipe];
   NSFileHandle *readingFileHandle=[readPipe fileHandleForReading];
   [task setStandardOutput:readPipe];
   [task setStandardError:readPipe];
   
   [task launch];
   [writeHandle writeData:writeData];
   [writeHandle closeFile];
   
   NSData *dataPiped = nil;
   while((dataPiped = [readingFileHandle availableData]) && [dataPiped length])
   {
      [readData appendData:dataPiped];
   }
   //while( [task isRunning]) [NSThread sleepForTimeInterval: 0.1];
   //[task waitUntilExit];      // <- This is VERY DANGEROUS : the main runloop is continuing...
   //[aTask interrupt];
   
   [task waitUntilExit];
   int terminationStatus = [task terminationStatus];
   if (terminationStatus!=0) LOG_INFO(@"ERROR task terminationStatus: %d",terminationStatus);
   return terminationStatus;
}


-(id)init{
    return nil;
}

-(id)initWithSqls:(NSDictionary*)sqls
             pacs:(NSDictionary*)pacs
          drsport:(long long)drsport
          defaultpacsoid:(NSString*)defaultpacsoid
{
    self = [super init];
    if(self) {
        _sqls=sqls;
        _pacs=pacs;
        _drsport=drsport;
        _defaultpacsoid=defaultpacsoid;

#pragma mark pacs

//TODO classify pacs (sql, dicomweb, dicom, custodian)
        
        NSMutableDictionary *oids=[NSMutableDictionary dictionary];
        NSMutableDictionary *titles=[NSMutableDictionary dictionary];
        for (NSDictionary *d in [pacs allValues])
        {
            NSString *newtitle=d[@"custodiantitle"];
            if (
                !newtitle
                || ![newtitle length]
                || ![DICMTypes.SHRegex numberOfMatchesInString:newtitle options:0 range:NSMakeRange(0,[newtitle length])]
                )
            {
                NSLog(@"bad custodiantitle");
                return nil;
            }
            
            NSString *newoid=d[@"custodianoid"];
            if (
                !newoid
                || ![newoid length]
                || ![DICMTypes.UIRegex numberOfMatchesInString:newoid options:0 range:NSMakeRange(0,[newoid length])]
                )
            {
                NSLog(@"bad custodianoid");
                return nil;
            }
            
            if ( oids[newoid] || titles[newtitle])
            {
                //verify if there is no incoherence
                if (
                    ![newtitle isEqualToString:oids[newoid]]
                    || ![newoid isEqualToString:titles[newtitle]]
                    )
                {
                    NSLog(@"pacs incoherence in custodian oid and title ");
                    return nil;
                }
                
            }
            else
            {
                //add custodian
                [oids setObject:newtitle forKey:newoid];
                [titles setObject:newoid forKey:newtitle];
            }
        }
        
        
        
        //response data for root queries custodians/titles and custodians/oids
        _oidsdata = [NSJSONSerialization dataWithJSONObject:[oids allKeys] options:0 error:nil];
        _titlesdata = [NSJSONSerialization dataWithJSONObject:[titles allKeys] options:0 error:nil];
        
        
        
        //pacs OID classified by custodian
        NSMutableDictionary *oidsaeis=[NSMutableDictionary dictionary];
        for (NSString *oid in [oids allKeys])
        {
            NSMutableArray *oidaeis=[NSMutableArray array];
            for (NSString *k in [pacs allKeys])
            {
                NSDictionary *d=[pacs objectForKey:k];
                if ([[d objectForKey:@"custodianoid"]isEqualToString:oid])[oidaeis addObject:k];
            }
            [oidsaeis setValue:oidaeis forKey:oid];
        }
        NSLog(@"\r\nknown pacs OID classified by corresponding custodian OID:\r\n%@",[oidsaeis description]);
        
        
        
        //pacs titles grouped on custodian
        NSMutableDictionary *titlesaets=[NSMutableDictionary dictionary];
        NSMutableDictionary *titlesaetsStrings=[NSMutableDictionary dictionary];
        for (NSString *title in [titles allKeys])
        {
            NSMutableArray *titleaets=[NSMutableArray array];
            NSMutableString *s=[NSMutableString stringWithString:@"("];
            
            for (NSString *k in [pacs allKeys])
            {
                NSDictionary *d=[pacs objectForKey:k];
                if ([[d objectForKey:@"custodiantitle"]isEqualToString:title])
                {
                    [titleaets addObject:[d objectForKey:@"pacsaet"]];
                    if ([s isEqualToString:@"("])
                        [s appendFormat:@"'%@'",[d objectForKey:@"pacsaet"]];
                    else [s appendFormat:@",'%@'",[d objectForKey:@"pacsaet"]];
                }
            }
            [titlesaets setObject:titleaets forKey:title];
            [s appendString:@")"];
            [titlesaetsStrings setObject:s forKey:title];
        }
        NSLog(@"\r\nknown pacs aet classified by corresponding custodian title:\r\n%@",[titlesaets description]);
        
        
        NSMutableDictionary *pacsaetDictionary=[NSMutableDictionary dictionary];
        NSMutableArray      *localOIDs=[NSMutableArray array];
        NSMutableDictionary *custodianDictionary=nil;
        for (NSString *key in [pacs allKeys])
        {
            [pacsaetDictionary setObject:key forKey:[(pacs[key])[@"custodiantitle"] stringByAppendingPathExtension:(pacs[key])[@"pacsaet"]]];
            
            if ([(pacs[key])[@"sqlprolog"] length]||[(pacs[key])[@"dcm4cheelocaluri"] length])
            {
                [localOIDs addObject:key];
                if ([(pacs[key])[@"custodianoid"] isEqualToString:key]) custodianDictionary=pacs[key];
            }
        }

        _oids=[NSDictionary dictionaryWithDictionary:oids];
        _titles=[NSDictionary dictionaryWithDictionary:titles];
        _oidsaeis=[NSDictionary dictionaryWithDictionary:oidsaeis];
        _titlesaets=[NSDictionary dictionaryWithDictionary:titlesaets];
        _titlesaetsstrings=[NSDictionary dictionaryWithDictionary:titlesaetsStrings];
        _pacsaetDictionary=[NSDictionary dictionaryWithDictionary:_pacsaetDictionary];
        _localoids=[NSArray arrayWithArray:localOIDs];
        _custodianDictionary=[NSDictionary dictionaryWithDictionary:custodianDictionary];

#pragma mark -
#pragma mark handlers
#pragma mark -
        
#pragma mark / =wado-uri
        [self addWadoHandler];//(default handler)
       LOG_DEBUG(@"added handler / (=wado-uri)");

#pragma mark /echo
        [self addHandler:@"GET" path:@"/echo" processBlock:
         ^(RSRequest* request, RSCompletionBlock completionBlock)
         {completionBlock(^RSResponse* (RSRequest* request){
            return [RSDataResponse responseWithText:@"echo"];
        }(request));}];
       //            return [RSDataResponse responseWithText:[NSString stringWithFormat:@"echo time:%@ to:%@", [DICMTypes DTStringFromDate:[NSDate date]], request.remoteAddressString]];

        LOG_DEBUG(@"added handler /echo");
       
#pragma mark /(custodians|pacs/titles|pacs/oids)
        [self addCustodiansHandler];//
        LOG_DEBUG(@"added handler /custodians");
       
#pragma mark /qido
       //[self addMWLHandler];
       //LOG_DEBUG(@"added handler /mwlitem");

#pragma mark /wado-rs
       [self addWadorsHandler];//
       LOG_DEBUG(@"added handler /custodians");

#pragma mark /mwlitem
        [self addMWLHandler];
        LOG_DEBUG(@"added handler /mwlitem");        

#pragma mark /pdf
        [self addPDFHandler];
        LOG_DEBUG(@"added handler /pdf /report /informe");
    }
    return self;
}


#pragma mark -
#pragma mark getters

+(NSDictionary*)sqls                 { return _sqls;}
+(NSDictionary*)pacs                 { return _pacs;}
+(long long)drsport                  { return _drsport;}
+(NSString*)defaultpacsoid                  { return _defaultpacsoid;}

+(NSDictionary*)oids                 { return _oids;}
+(NSDictionary*)titles               { return _titles;}
+(NSData*)oidsdata                   { return _oidsdata;}
+(NSData*)titlesdata                 { return _titlesdata;}
+(NSDictionary*)oidsaeis             { return _oidsaeis;}
+(NSDictionary*)titlesaets           { return _titlesaets;}
+(NSDictionary*)titlesaetsstrings    { return _titlesaetsstrings;}
+(NSDictionary*)pacsaetDictionary  { return _pacsaetDictionary;}
+(NSArray*)localoids                 { return _localoids;}
+(NSDictionary*)custodianDictionary  { return _custodianDictionary;}

@end
