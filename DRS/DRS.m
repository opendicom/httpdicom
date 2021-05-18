#import "DRS.h"
#import "NSData+PCS.h"
#import "NSString+PCS.h"

#import "DRS+wadouri.h"
#import "DRS+pacs.h"
#import "DRS+studyToken.h"
#import "DRS+datatables.h"
#import "DRS+report.h"


//RSRequest properties:      NSMutableURLRequest
//- NSString* method          -> HTTPMethod
//- NSURL* URL                -> URL
//- NSDictionary* headers     -> allHTTPHeaderFields
//- NSString* path            -> URL.path (NSArray *URL.pathComponents
//- NSDictionary* query       -> URL -> NSURLComponents.queryItems
//- NSString* contentType     -> allHTTPHeaderFields[@"Content-Type"]
//- NSData* data              -> HTTPBody (HTTPBodyStream)




NSString * parseRequestParams(RSRequest       *  request,
                              NSMutableArray  *  names,
                              NSMutableArray  *  values
                              )
{
   //Content-Type
   NSString * contentType=request.contentType;
   if (!contentType) contentType=@"application/x-www-form-urlencoded";
   if ([request.contentType hasPrefix:@"application/json"])
   {
      //json
      NSData *requestData=request.data;
      if (!requestData) return @"ERROR Content-Type:\"application/json\" with no body";
      
      if (![requestData length])return @"ERROR Content-Type:\"application/json\" with empty body";
      
      NSString *string=[[NSString alloc]initWithData:requestData encoding:NSUTF8StringEncoding];
      if (!string) return @"ERROR Content-Type:\"application/json\" with json not readable UTF-8";
      
      NSError *requestJsonError=nil;
      id requestJson=[NSJSONSerialization JSONObjectWithData:requestData options:0 error:&requestJsonError];
      if (requestJsonError)return [NSString stringWithFormat:@"ERROR %@\r\n%@",string,[requestJsonError description]];
      
      if (![requestJson isKindOfClass:[NSDictionary class]]) return [NSString stringWithFormat:@"ERROR json dictionary expected, but got\r\n%@",string];
      
      [names addObjectsFromArray:[requestJson allKeys]];
      [values addObjectsFromArray:[requestJson allValues]];
   }
   else if ([contentType hasPrefix:@"multipart/form-data"])
   {
     //html5 form
     NSString *boundaryString=[request.contentType valueForName:@"boundary"];
     if (!boundaryString || ![boundaryString length]) return [NSString stringWithFormat:@"ERROR multipart/form-data with no boundary"];
     
     NSDictionary *components=[request.data parseNamesValuesTypesInBodySeparatedBy:[boundaryString dataUsingEncoding:NSASCIIStringEncoding]];
     
     names=components[@"names"];
     values=components[@"values"];
   }
   else if ([contentType hasPrefix:@"application/x-www-form-urlencoded"])
   {
      //x-www-form-urlencoded
      NSArray *queryItems=[[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO]queryItems];
      for (NSURLQueryItem *queryItem in queryItems)
      {
         [names addObject:queryItem.name];
         [values addObject:queryItem.value];
      }
   }
   else return [NSString stringWithFormat:@"ERROR Content-Type:\"%@\" not accepted",request.contentType];
   
   
   NSLog(@"%@ %@ content-type: %@ %@",
            request.method,
            [request.URL absoluteString],
            request.contentType,
            [request.headers description]
            );//info
   
   for (NSString * key in [request.headers allKeys])
   {
      [names addObject:key];
      [values addObject:request.headers[key]];
   }
   return nil;
}


NSDictionary * pacsParam(NSMutableArray  *  names,
                         NSMutableArray  *  values,
                         NSMutableString *  pacsOID,
                         NSString        ** errorString
                         )
{
   NSUInteger pacsIndex=[names indexOfObject:@"pacs"];
   if (pacsIndex!=NSNotFound)
   {
      
      [pacsOID appendString:values[pacsIndex]];
      if (![DICMTypes.UIRegex numberOfMatchesInString:pacsOID options:0 range:NSMakeRange(0,[pacsOID length])]){
         NSLog(@"<-404:  pacsUID '%@' should be an OID",pacsOID);//warning
         *errorString=[NSString stringWithFormat:@" pacsUID '%@' should be an OID",pacsOID];
         return nil;
      }
      
      
      if (!DRS.pacs[pacsOID]){
         NSLog(@"<-404:  pacs '%@' not known",pacsOID);//warning
         *errorString=[NSString stringWithFormat:@" pacsUID '%@' not known",pacsOID];
         return nil;
      }
   }
   else [pacsOID appendString:DRS.defaultpacsoid];
   
   
   return DRS.pacs[pacsOID];
}





NSMutableArray *jsonMutableArray(NSString *scriptString, NSStringEncoding encoding)
{
   if      (encoding==4) NSLog(@"utf8\r\n%@",scriptString);//DEBUG
   else if (encoding==5) NSLog(@"latin1\r\n%@",scriptString);//debug
   else                  NSLog(@"encoding:%lu\r\n%@",(unsigned long)encoding,scriptString);//debug
   
   NSMutableData *mutableData=[NSMutableData data];
   if (!task(@"/bin/bash",@[@"-s"],[scriptString dataUsingEncoding:NSUTF8StringEncoding],mutableData))
      [RSErrorResponse responseWithClientError:404 message:@"%@",@"can not execute the script"];//NotFound
   NSString *string=[[NSString alloc]initWithData:mutableData encoding:encoding];//5=latinISO1 4=UTF8
   NSData *utf8Data=[string dataUsingEncoding:NSUTF8StringEncoding];
   
   NSError *e;
   NSMutableArray *mutableArray=[NSJSONSerialization JSONObjectWithData:utf8Data options:NSJSONReadingMutableContainers error:&e];
   if (e)
   {
      NSLog(@"%@",[e description]);//debug
      return nil;
   }
   return mutableArray;
}


@implementation DRS

static NSDictionary *_sqls=nil;
static long long     _drsport;
static NSString     *_defaultpacsoid;
static NSString     *_tmpDir;
static NSString     *_tokentmpDir;

static NSDictionary *_oids=nil;
static NSDictionary *_titles=nil;
static NSData       *_oidsdata=nil;
static NSData       *_titlesdata=nil;
static NSDictionary *_oidsaeis=nil;
static NSDictionary *_titlesaets=nil;

static NSDictionary *_pacs=nil;//pacsDictionary
static NSData       *_pacskeysdata=nil;

static NSSet        *_wan=nil;
static NSSet        *_lan=nil;
static NSSet        *_lanDeduplicated=nil;

static NSArray      *_InstanceUniqueFrameSOPClass=nil;
static NSArray      *_InstanceMultiFrameSOPClass=nil;

static NSArray      *_accessType=nil;
static NSArray      *_accessTypeStarter=nil;
static NSArray      *_accessTypeSeparator=nil;
static NSArray      *_accessTypeFinisher=nil;

int execUTF8Bash(NSDictionary *environment, NSString *writeString, NSMutableData *readData)
{
   NSLog(@"%@",writeString);//debug
   
   return execTask(environment, @"/bin/bash",@[@"-s"], [writeString dataUsingEncoding:NSUTF8StringEncoding], readData);
}

int execTask(NSDictionary *environment, NSString *launchPath, NSArray *launchArgs, NSData *writeData, NSMutableData *readData)
{
   NSTask *task=[[NSTask alloc]init];
   
   task.environment=environment;
   
   [task setLaunchPath:launchPath];
   [task setArguments:launchArgs];
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
   if (terminationStatus!=0) NSLog(@"ERROR task terminationStatus: %d",terminationStatus);//warning
   return terminationStatus;
}


int bash(NSData *writeData, NSMutableData *readData)
{
   return task(@"/bin/bash",@[@"-s"], writeData, readData);
}

int task(NSString *launchPath, NSArray *launchArgs, NSData *writeData, NSMutableData *readData)
{
   NSTask *task=[[NSTask alloc]init];
   [task setLaunchPath:launchPath];
   [task setArguments:launchArgs];
   //NSLog(@"%@",[task arguments]);
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
   if (terminationStatus!=0) NSLog(@"ERROR task terminationStatus: %d",terminationStatus);//info
   return terminationStatus;
}


-(id)init{
    return nil;
}


#pragma mark statics of dicomzip
static NSFileManager *fileManager=nil;
static NSData *ctad=nil;

-(id)initWithSqls:(NSDictionary*)sqls
             pacs:(NSArray*)pacsArray
          drsport:(long long)drsport
   defaultpacsoid:(NSString*)defaultpacsoid
        tmpDir:(NSString*)tmpDir
{
   //statics of dicomzip
   fileManager=[NSFileManager defaultManager];
   ctad=[@"Content-Type: application/dicom\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
   
   _InstanceUniqueFrameSOPClass=
   @[
      @"1.2.840.10008.5.1.4.1.1.1",
      @"1.2.840.10008.5.1.4.1.1.1.1",
      @"1.2.840.10008.5.1.4.1.1.1.1.1",
      @"1.2.840.10008.5.1.4.1.1.1.2",
      @"1.2.840.10008.5.1.4.1.1.1.2.1",
      @"1.2.840.10008.5.1.4.1.1.1.3",
      @"1.2.840.10008.5.1.4.1.1.1.3.1",
      @"1.2.840.10008.5.1.4.1.1.2",
      @"1.2.840.10008.5.1.4.1.1.4",
      @"1.2.840.10008.5.1.4.1.1.6.1",
      @"1.2.840.10008.5.1.4.1.1.7",
      @"1.2.840.10008.5.1.4.1.1.20",
      @"1.2.840.10008.5.1.4.1.1.128"
   ];
   _InstanceMultiFrameSOPClass=
   @[
      @"1.2.840.10008.5.1.4.1.1.2.1",
      @"1.2.840.10008.5.1.4.1.1.2.2",
      @"1.2.840.10008.5.1.4.1.1.3.1",
      @"1.2.840.10008.5.1.4.1.1.4.1",
      @"1.2.840.10008.5.1.4.1.1.4.2",
      @"1.2.840.10008.5.1.4.1.1.4.3",
      @"1.2.840.10008.5.1.4.1.1.4.4",
      @"1.2.840.10008.5.1.4.1.1.6.2",
      @"1.2.840.10008.5.1.4.1.1.7.1",
      @"1.2.840.10008.5.1.4.1.1.7.2",
      @"1.2.840.10008.5.1.4.1.1.7.3",
      @"1.2.840.10008.5.1.4.1.1.7.4",
      @"1.2.840.10008.5.1.4.1.1.12.1",
      @"1.2.840.10008.5.1.4.1.1.12.1.1",
      @"1.2.840.10008.5.1.4.1.1.12.2",
      @"1.2.840.10008.5.1.4.1.1.12.2.1",
      @"1.2.840.10008.5.1.4.1.1.13.1.1",
      @"1.2.840.10008.5.1.4.1.1.13.1.2",
      @"1.2.840.10008.5.1.4.1.1.13.1.3",
      @"1.2.840.10008.5.1.4.1.1.13.1.4",
      @"1.2.840.10008.5.1.4.1.1.13.1.5",
      @"1.2.840.10008.5.1.4.1.1.14.1",
      @"1.2.840.10008.5.1.4.1.1.14.2",
      @"1.2.840.10008.5.1.4.1.1.30",
      @"1.2.840.10008.5.1.4.1.1.130",
      @"1.2.840.10008.5.1.4.1.1.128.1"
   ];
   [NSData initPCS];
    self = [super init];
    if(self) {
        _sqls=sqls;
        _drsport=drsport;
        _defaultpacsoid=defaultpacsoid;
        _tmpDir=tmpDir;
        _tokentmpDir=[tmpDir stringByAppendingPathComponent:@"token"];

#pragma mark custodians

//TODO classify pacs (sql, dicomweb, dicom, custodian)
        
        NSMutableDictionary *oids=[NSMutableDictionary dictionary];
        NSMutableDictionary *titles=[NSMutableDictionary dictionary];
       
              
#pragma mark loop pacsArray (oids and titles)
        for (NSDictionary *p in pacsArray)
        {
            NSString *newtitle=p[@"custodiantitle"];
            if (
                !newtitle
                || ![newtitle length]
                || ![DICMTypes.SHRegex numberOfMatchesInString:newtitle options:0 range:NSMakeRange(0,[newtitle length])]
                )
            {
                NSLog(@"bad custodiantitle");
                return nil;
            }
            
            NSString *newoid=p[@"custodianoid"];
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
       
#pragma mark loop oids
        for (NSString *oid in [oids allKeys])
        {
            NSMutableArray *oidaeis=[NSMutableArray array];
            for (NSDictionary *d in pacsArray)
            {
                if ([d[@"custodianoid"] isEqualToString:oid])
                   [oidaeis addObject:d[@"pacsoid"]];
            }
            [oidsaeis setValue:oidaeis forKey:oid];
        }
       NSLog(@"\r\nknown pacs OID classified by corresponding custodian OID:\r\n%@",[oidsaeis description]);//debug
        
        
        
        //pacs titles grouped on custodian
        NSMutableDictionary *titlesaets=[NSMutableDictionary dictionary];

#pragma mark loop titles
       for (NSString *title in [titles allKeys])
        {
            NSMutableArray *titleaets=[NSMutableArray array];
            NSMutableArray *titletitleaets=[NSMutableArray array];
            NSMutableString *s=[NSMutableString stringWithString:@"("];
            
            for (NSDictionary *d in pacsArray)
            {
                if ([d[@"custodiantitle"] isEqualToString:title])
                {
                   [titleaets addObject:d[@"pacsaet"]];
                   [titletitleaets addObject:[title stringByAppendingPathExtension:d[@"pacsaet"]]];

                    if ([s isEqualToString:@"("])
                        [s appendFormat:@"'%@'",d[@"pacsaet"]];
                    else [s appendFormat:@",'%@'",d[@"pacsaet"]];
                }
            }
            [titlesaets setObject:titleaets forKey:title];
            [s appendString:@")"];
        }
       NSLog(@"\r\nknown pacs aet classified by corresponding custodian title:\r\n%@",[titlesaets description]);//debug
       
       _oids=[NSDictionary dictionaryWithDictionary:oids];
       _titles=[NSDictionary dictionaryWithDictionary:titles];
       _oidsaeis=[NSDictionary dictionaryWithDictionary:oidsaeis];
       _titlesaets=[NSDictionary dictionaryWithDictionary:titlesaets];

       
//_pacs receives two entries for each dev:
//- oid (get access direct)
//- custodianaet.pacsaet (get access proxied by pcs)
       NSMutableDictionary *pacsDictionary=[NSMutableDictionary dictionary];
       NSUInteger pacsIndex=NSNotFound;
       NSMutableString *pacsKeys=[NSMutableString stringWithString:@"["];
 
       
       NSMutableSet *lan=[NSMutableSet set];
       NSMutableSet *lanDeduplicated=[NSMutableSet set];
       NSMutableSet *wan=[NSMutableSet set];
       NSString *p0wadouriComplete=(pacsArray[0])[@"wadouri"];
       NSString *withoutProtocol=[p0wadouriComplete componentsSeparatedByString:@"//"].lastObject;
       NSString *p0wadouriIpPort=[withoutProtocol componentsSeparatedByString:@"/"].firstObject;

        
        
#pragma mark loop pacsArray
       for (pacsIndex=0; pacsIndex<[pacsArray count];pacsIndex++)
       {
          NSMutableDictionary *p=[NSMutableDictionary dictionaryWithDictionary:pacsArray[pacsIndex]];

 
#pragma mark ·needssqlaccesscontrol
          if ([p[@"needssqlaccesscontrol"]boolValue])
          {
             NSDictionary *s=DRS.sqls[p[@"sqlmap"]];
             [p setObject:
                          [NSString
                           stringWithFormat:s[@"Eaccesscontrol"],
                           p[@"custodiantitle"],
                           p[@"pacsaet"]
                           ]
                   forKey:@"Eaccesscontrol"
              ];
          }
          else
          {
             [p setObject:@"" forKey:@"Eaccesscontrol"];
          }
          
#pragma mark ·pacsKeys
          if (pacsIndex!=0)[pacsKeys appendString:@","];
          [pacsKeys appendFormat:
           @"{\"direct\":\"%@\",\"proxied\":\"%@\"}",
           p[@"pacsoid"],
           [p[@"custodiantitle"] stringByAppendingPathExtension:p[@"pacsaet"]]
           ];

#pragma mark ·p[org] lan wan
          if (
                [p[@"custodianoid"] isEqualToString:(pacsArray[0])[@"custodianoid"]]
              ||[p[@"custodiantitle"] isEqualToString:(pacsArray[0])[@"custodiantitle"]]
              )
          {
             //pacsArray[0])[@"custodianoid"]
             //the first pacs is always of local custodian
             
             if ([p[@"wadouriproxy"]boolValue])
             {
                //lan aet
                [lan addObject:p[@"pacsaet"]];
                [p setObject:p[@"pacsaet"] forKey:@"org"];
                if (
                      (pacsIndex==0)
                    ||([p[@"wadouri"] componentsSeparatedByString:p0wadouriIpPort].count==1)
                    )
                   [lanDeduplicated addObject:p[@"pacsaet"]];
                [pacsDictionary setObject:p forKey:p[@"pacsaet"]];

             }
             else
             {
                //lan oid
                [lan addObject:p[@"pacsoid"]];//direct wado
                [p setObject:p[@"pacsoid"] forKey:@"org"];
                if (
                      (pacsIndex==0)
                    ||([p[@"wadouri"] componentsSeparatedByString:p0wadouriIpPort].count==1)
                    )
                   [lanDeduplicated addObject:p[@"pacsoid"]];
             }
          }
          else
          {
             //wan custodian.aet
             [wan addObject:[p[@"custodiantitle"] stringByAppendingPathExtension:p[@"pacsaet"]]];
             [p setObject:[p[@"custodiantitle"] stringByAppendingPathExtension:p[@"pacsaet"]] forKey:@"org"];

          }
          
#pragma mark ·2 entries for each pacs (for lan there is one more entry aet)
          [pacsDictionary setObject:p forKey:p[@"pacsoid"]];
          [pacsDictionary
           setObject:p
           forKey:[p[@"custodiantitle"] stringByAppendingPathExtension:p[@"pacsaet"]]
             ];
          //[pacsDictionary setObject:p forKey:[NSString stringWithFormat:@"%ld",(long)pacsIndex]];
          
        }
#pragma mark end loop
       [pacsKeys appendString:@"]"];
       _pacs=[NSDictionary dictionaryWithDictionary:pacsDictionary];
       _pacskeysdata=[pacsKeys dataUsingEncoding:NSUTF8StringEncoding];

       _wan=[NSSet setWithSet:wan];
       _lan=[NSSet setWithSet:lan];
       _lanDeduplicated=[NSSet setWithSet:lanDeduplicated];
       NSLog(@"\r\nwan:\r\n%@",[_wan description]);//debug
       NSLog(@"\r\nlan:\r\n%@",[_lan description]);//debug
       NSLog(@"\r\nlanDeduplicated:\r\n%@",[_lanDeduplicated description]);//debug

#pragma mark _accessType, _accessTypeStarter, _accessTypeSeparator, _accessTypeFinisher
       _accessType=@[
                     @"datatables/studies",
                     @"datatables/patient",
                     @"weasis.xml",
                     @"cornerstone.json",
                     @"dicom.zip",
                     @"multipart.dicom"
       ];
       NSData *starterWeasis=[@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><manifest xmlns=\"http://www.weasis.org/xsd/2.5\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">" dataUsingEncoding:NSUTF8StringEncoding];
       NSData *starterCornerstone=[@"[" dataUsingEncoding:NSUTF8StringEncoding];
       NSData *starterSeriesPlist=[@"" dataUsingEncoding:NSUTF8StringEncoding];
       NSData *starterMultipart=[@"" dataUsingEncoding:NSUTF8StringEncoding];
       _accessTypeStarter=@[
          [NSData data],
          [NSData data],
          starterWeasis,
          starterCornerstone,
          starterSeriesPlist,
          starterMultipart
       ];
       
       NSData *separatorCornerstone=[@"," dataUsingEncoding:NSUTF8StringEncoding];
       NSData *separatorMultipart=[@"" dataUsingEncoding:NSUTF8StringEncoding];
       _accessTypeSeparator=@[
          [NSData data],
          [NSData data],
          [NSData data],
          separatorCornerstone,
          [NSData data],
          separatorMultipart
       ];
       
       NSData *finisherWeasis=[@"</manifest>" dataUsingEncoding:NSUTF8StringEncoding];
       NSData *finisherCornerstone=[@"]" dataUsingEncoding:NSUTF8StringEncoding];
       NSData *finisherSeriesPlist=[@"" dataUsingEncoding:NSUTF8StringEncoding];
       NSData *finisherMultipart=[@"" dataUsingEncoding:NSUTF8StringEncoding];
       _accessTypeFinisher=@[
          [NSData data],
          [NSData data],
          finisherWeasis,
          finisherCornerstone,
          finisherSeriesPlist,
          finisherMultipart
       ];

#pragma mark -
#pragma mark handlers
#pragma mark -
        
#pragma mark / =wado-uri
        [self addWadoHandler];//(default handler)
       NSLog(@"added handler GET / (=wado-uri)");//debug

#pragma mark /echo
        [self addHandler:@"GET" path:@"/echo" processBlock:
         ^(RSRequest* request, RSCompletionBlock completionBlock)
         {completionBlock(^RSResponse* (RSRequest* request){
            return [RSDataResponse responseWithText:@"echo"];
        }(request));}];
       //            return [RSDataResponse responseWithText:[NSString stringWithFormat:@"echo time:%@ to:%@", [DICMTypes DTStringFromDate:[NSDate date]], request.remoteAddressString]];

       NSLog(@"added handler GET /echo");//debug
       
#pragma mark /custodians /pacs /sqls
        [self addGETCustodiansHandler];//
        [self addGETPacsHandler];//
        [self addGETSqlsHandler];//
       NSLog(@"added handler GET /custodians and /pacs /sqls");//debug


#pragma mark /studyToken
        [self addPostAndGetStudyTokenHandler];
       NSLog(@"added handler POST+GET /studyToken");//debug

#pragma mark /datatables
        [self addDatatablesStudiesHandler];
       NSLog(@"added handler GET /datatables/studies");//debug

        [self addDatatablesSeriesHandler];
       NSLog(@"added handler GET /datatables/series");//debug

       [self addDatatablesPatientHandler];
       NSLog(@"added handler GET /datatables/patient");//debug

#pragma mark report
       [self addXMLReportHandler];
       NSLog(@"added handler GET ^/(OT|DOC)/(DSCD|SCD|CDA|PDF)$");//debug

    }
      

    return self;
}


#pragma mark -
#pragma mark getters

+(NSDictionary*)sqls                 { return _sqls;}

+(long long)drsport                  { return _drsport;}
+(NSString*)defaultpacsoid           { return _defaultpacsoid;}
+(NSString*)tmpDir          { return _tmpDir;}
+(NSString*)tokentmpDir     { return _tokentmpDir;}

+(NSDictionary*)oids                 { return _oids;}
+(NSDictionary*)titles               { return _titles;}
+(NSData*)oidsdata                   { return _oidsdata;}
+(NSData*)titlesdata                 { return _titlesdata;}
+(NSDictionary*)oidsaeis             { return _oidsaeis;}
+(NSDictionary*)titlesaets           { return _titlesaets;}

+(NSDictionary*)pacs                 { return _pacs;}
+(NSData*)pacskeysdata               { return _pacskeysdata;}

+(NSSet*)wan                       { return _wan;}
+(NSSet*)lan                       { return _lan;}
+(NSSet*)lanDeduplicated             { return _lanDeduplicated;}

+(NSArray*)InstanceUniqueFrameSOPClass { return _InstanceUniqueFrameSOPClass;}
+(NSArray*)InstanceMultiFrameSOPClass { return _InstanceMultiFrameSOPClass;}
+(NSArray*)accessType { return _accessType;}
+(NSArray*)accessTypeStarter { return _accessTypeStarter;}
+(NSArray*)accessTypeSeparator { return _accessTypeSeparator;}
+(NSArray*)accessTypeFinisher { return _accessTypeFinisher;}


@end
