#import "DRS.h"
#import "NSData+PCS.h"
#import "NSString+PCS.h"

#import "DRS+wadouri.h"
#import "DRS+pacs.h"
//#import "DRS+qido.h"
#import "DRS+wadors.h"
#import "DRS+zipped.h"

#import "DRS+mwlitem.h"
//#import "DRS+pdf.h"
//#import "DRS+encapsulated.h"
#import "DRS+studyToken.h"

//RSRequest properties:      NSMutableURLRequest
//- NSString* method          -> HTTPMethod
//- NSURL* URL                -> URL
//- NSDictionary* headers     -> allHTTPHeaderFields
//- NSString* path            -> URL.path (NSArray *URL.pathComponents
//- NSDictionary* query       -> URL -> NSURLComponents.queryItems
//- NSString* contentType     -> allHTTPHeaderFields[@"Content-Type"]
//- NSData* data              -> HTTPBody (HTTPBodyStream)




BOOL parseRequestParams(RSRequest       *  request,
                        NSMutableArray  *  names,
                        NSMutableArray  *  values,
                        NSMutableArray  *  types,
                        NSString        ** jsonString,
                        NSString        ** errorString
                        )
{
   //method
   [names addObject:@"HTTPMethod"];
   [values addObject:request.method];
   
   //headers
   for (NSString * key in [request.headers allKeys])
   {
      [names addObject:key];
      [values addObject:request.headers[key]];
   }
   
   //Content-Type
   NSString * contentType=request.contentType;
   if (contentType) {
      
      
      //json
      if ([request.contentType hasPrefix:@"application/json"]) {
         
         NSData *requestData=request.data;
         if (!requestData){
            *errorString=@"Content-Type:\"application/json\" with no body";
            return false;
         }
         
         
         if (![requestData length]) return true;
         
         
         NSString *string=[[NSString alloc]initWithData:requestData encoding:NSUTF8StringEncoding];
         if (!string){
            *errorString=@"json not readable UTF-8";
            return false;
         }
         *jsonString=string;
         
         
         NSError *requestJsonError=nil;
         id requestJson=[NSJSONSerialization JSONObjectWithData:requestData options:0 error:&requestJsonError];
         if (requestJsonError){
            *errorString=[NSString stringWithFormat:@"%@\r\n%@",string,[requestJsonError description]];
            return false;
         }
         
         if (![requestJson isKindOfClass:[NSDictionary class]]){
            *errorString=[NSString stringWithFormat:@"json dictionary expected, but got\r\n%@",string];
            return false;
         }
         
         [names addObjectsFromArray:[requestJson allKeys]];
         [values addObjectsFromArray:[requestJson allValues]];
         return true;
      }
      
      
      //form html5
      if ([request.contentType hasPrefix:@"multipart/form-data"])
      {
         NSString *boundaryString=[request.contentType valueForName:@"boundary"];
         if (!boundaryString || ![boundaryString length]){
            *errorString=[NSString stringWithFormat:@"multipart/form-data with no boundary"];
            return false;
         }
         
         NSDictionary *components=[request.data parseNamesValuesTypesInBodySeparatedBy:[boundaryString dataUsingEncoding:NSASCIIStringEncoding]];
         
         names=components[@"names"];
         values=components[@"values"];
         types=components[@"types"];
         return true;
      }
      
      
      //x-www-form-urlencoded
      if ([request.contentType hasPrefix:@"application/x-www-form-urlencoded"])
      {
         NSArray *queryItems=[[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO]queryItems];
         for (NSURLQueryItem *queryItem in queryItems)
         {
            [names addObject:queryItem.name];
            [values addObject:queryItem.value];
         }
         return true;
      }
      
      
      *errorString=[NSString stringWithFormat:@"Content-Type:\"%@\" not accepted",request.contentType];
      return false;
   }
   
   
   //no Content-Type
   NSArray *queryItems=[[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO]queryItems];
   for (NSURLQueryItem *queryItem in queryItems)
   {
      [names addObject:queryItem.name];
      [values addObject:queryItem.value];
   }
   return true;
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
         LOG_WARNING(@"<-404:  pacsUID '%@' should be an OID",pacsOID);
         *errorString=[NSString stringWithFormat:@" pacsUID '%@' should be an OID",pacsOID];
         return nil;
      }
      
      
      if (!DRS.pacs[pacsOID]){
         LOG_WARNING(@"<-404:  pacs '%@' not known",pacsOID);
         *errorString=[NSString stringWithFormat:@" pacsUID '%@' not known",pacsOID];
         return nil;
      }
   }
   else [pacsOID appendString:DRS.defaultpacsoid];
   
   
   return DRS.pacs[pacsOID];
}





NSMutableArray *jsonMutableArray(NSString *scriptString, NSStringEncoding encoding)
{
   if      (encoding==4) LOG_DEBUG(@"utf8\r\n%@",scriptString);
   else if (encoding==5) LOG_DEBUG(@"latin1\r\n%@",scriptString);
   else                  LOG_DEBUG(@"encoding:%lu\r\n%@",(unsigned long)encoding,scriptString);
   
   NSMutableData *mutableData=[NSMutableData data];
   if (!task(@"/bin/bash",@[@"-s"],[scriptString dataUsingEncoding:NSUTF8StringEncoding],mutableData))
      [RSErrorResponse responseWithClientError:404 message:@"%@",@"can not execute the script"];//NotFound
   NSString *string=[[NSString alloc]initWithData:mutableData encoding:encoding];//5=latinISO1 4=UTF8
   NSData *utf8Data=[string dataUsingEncoding:NSUTF8StringEncoding];
   
   NSError *e;
   NSMutableArray *mutableArray=[NSJSONSerialization JSONObjectWithData:utf8Data options:NSJSONReadingMutableContainers error:&e];
   if (e)
   {
      LOG_DEBUG(@"%@",[e description]);
      return nil;
   }
   return mutableArray;
}


id qidoUrlProxy(NSString *qidoString,NSString *queryString, NSString *httpdicomString)
{
   __block dispatch_semaphore_t __urlProxySemaphore = dispatch_semaphore_create(0);
   __block NSMutableData *__data;
   __block NSURLResponse *__response;
   __block NSError *__error;
   __block NSDate *__date;
   __block unsigned long __chunks=0;
   
   NSString *urlString;
   if (queryString) urlString=[NSString stringWithFormat:@"%@?%@",qidoString,queryString];
   else urlString=qidoString;
   
   NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
   [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];//application/dicom+json not accepted !!!!!
   
   NSURLSessionDataTask * const dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                            {
                                               __data=[NSMutableData dataWithData:data];
                                               __response=response;
                                               __error=error;
                                               dispatch_semaphore_signal(__urlProxySemaphore);
                                            }];
   __date=[NSDate date];
   [dataTask resume];
   dispatch_semaphore_wait(__urlProxySemaphore, DISPATCH_TIME_FOREVER);
   //completionHandler of dataTask executed only once and before returning
   return [RSStreamedResponse responseWithContentType:@"application/json" asyncStreamBlock:^(RSBodyReaderCompletionBlock completionBlock)
           {
              if (__error) completionBlock(nil,__error);
              if (__chunks)
              {
                 completionBlock([NSData data], nil);
                 LOG_DEBUG(@"urlProxy: %lu chunk in %fs for:\r\n%@",__chunks,[[NSDate date] timeIntervalSinceDate:__date],[__response description]);
              }
              else
              {
                 NSData *pacsUri=[qidoString dataUsingEncoding:NSUTF8StringEncoding];
                 NSData *httpdicomUri=[httpdicomString dataUsingEncoding:NSUTF8StringEncoding];
                 NSUInteger httpdicomLength=[httpdicomUri length];
                 NSRange dataLeft=NSMakeRange(0,[__data length]);
                 NSRange occurrence=[__data rangeOfData:pacsUri options:0 range:dataLeft];
                 while (occurrence.length)
                 {
                    [__data replaceBytesInRange:occurrence
                                      withBytes:[httpdicomUri bytes]
                                         length:httpdicomLength];
                    dataLeft.location=occurrence.location+httpdicomLength;
                    dataLeft.length=[__data length]-dataLeft.location;
                    occurrence=[__data rangeOfData:pacsUri options:0 range:dataLeft];
                 }
                 completionBlock(__data, nil);
                 __chunks++;
              }
           }];
}


id urlChunkedProxy(NSString *urlString,NSString *contentType)
{
   __block dispatch_semaphore_t __urlProxySemaphore = dispatch_semaphore_create(0);
   __block NSData *__data;
   __block NSURLResponse *__response;
   __block NSError *__error;
   __block NSDate *__date;
   __block unsigned long __chunks=0;
   
   NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
   [request setValue:contentType forHTTPHeaderField:@"Accept"];//application/dicom+json not accepted !!!!!
   [request setValue:@"chunked" forHTTPHeaderField:@"Transfer-Encoding"];
   
   NSURLSessionDataTask * const dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                            {
                                               __data=data;
                                               __response=response;
                                               __error=error;
                                               dispatch_semaphore_signal(__urlProxySemaphore);
                                            }];
   __date=[NSDate date];
   [dataTask resume];
   dispatch_semaphore_wait(__urlProxySemaphore, DISPATCH_TIME_FOREVER);
   //completionHandler of dataTask executed only once and before returning
   
   
   return [RSStreamedResponse responseWithContentType:contentType asyncStreamBlock:^(RSBodyReaderCompletionBlock completionBlock)
           {
              if (__error) completionBlock(nil,__error);
              if (__chunks)
              {
                 completionBlock([NSData data], nil);
                 LOG_DEBUG(@"urlProxy: %lu chunk in %fs for:\r\n%@",__chunks,[[NSDate date] timeIntervalSinceDate:__date],[__response description]);
              }
              else completionBlock(__data, nil);
              __chunks++;
           }];
}




@implementation DRS

static NSDictionary        *_sqls=nil;
static long long           _drsport;
static NSString            *_defaultpacsoid;

static NSDictionary        *_oids=nil;
static NSDictionary        *_titles=nil;
static NSData              *_oidsdata=nil;
static NSData              *_titlesdata=nil;
static NSDictionary        *_oidsaeis=nil;
static NSDictionary        *_titlesaets=nil;
static NSDictionary        *_titlesaetsstrings=nil;

static NSDictionary        *_pacs=nil;//pacsDictionary
static NSArray             *_pacskeys=nil;
static NSData              *_pacskeysdata=nil;


int execUTF8Bash(NSDictionary *environment, NSString *writeString, NSMutableData *readData)
{
   LOG_DEBUG(@"%@",writeString);
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
   if (terminationStatus!=0) LOG_INFO(@"ERROR task terminationStatus: %d",terminationStatus);
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
             pacs:(NSArray*)pacsArray
          drsport:(long long)drsport
          defaultpacsoid:(NSString*)defaultpacsoid
{
   [NSData initPCS];
    self = [super init];
    if(self) {
        _sqls=sqls;
        _drsport=drsport;
        _defaultpacsoid=defaultpacsoid;

#pragma mark custodians

//TODO classify pacs (sql, dicomweb, dicom, custodian)
        
        NSMutableDictionary *oids=[NSMutableDictionary dictionary];
        NSMutableDictionary *titles=[NSMutableDictionary dictionary];
        for (NSDictionary *d in pacsArray)
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
            for (NSDictionary *d in pacsArray)
            {
                if ([d[@"custodianoid"] isEqualToString:oid])
                   [oidaeis addObject:d[@"pacsoid"]];
            }
            [oidsaeis setValue:oidaeis forKey:oid];
        }
        LOG_DEBUG(@"\r\nknown pacs OID classified by corresponding custodian OID:\r\n%@",[oidsaeis description]);
        
        
        
        //pacs titles grouped on custodian
        NSMutableDictionary *titlesaets=[NSMutableDictionary dictionary];
        NSMutableDictionary *titlesaetsStrings=[NSMutableDictionary dictionary];
        for (NSString *title in [titles allKeys])
        {
            NSMutableArray *titleaets=[NSMutableArray array];
            NSMutableString *s=[NSMutableString stringWithString:@"("];
            
            for (NSDictionary *d in pacsArray)
            {
                if ([d[@"custodiantitle"] isEqualToString:title])
                {
                    [titleaets addObject:d[@"pacsaet"]];
                    if ([s isEqualToString:@"("])
                        [s appendFormat:@"'%@'",d[@"pacsaet"]];
                    else [s appendFormat:@",'%@'",d[@"pacsaet"]];
                }
            }
            [titlesaets setObject:titleaets forKey:title];
            [s appendString:@")"];
            [titlesaetsStrings setObject:s forKey:title];
        }
        LOG_DEBUG(@"\r\nknown pacs aet classified by corresponding custodian title:\r\n%@",[titlesaets description]);
       
       _oids=[NSDictionary dictionaryWithDictionary:oids];
       _titles=[NSDictionary dictionaryWithDictionary:titles];
       _oidsaeis=[NSDictionary dictionaryWithDictionary:oidsaeis];
       _titlesaets=[NSDictionary dictionaryWithDictionary:titlesaets];
       _titlesaetsstrings=[NSDictionary dictionaryWithDictionary:titlesaetsStrings];

       
//_pacs (pacsoidDictionary) and pacsaetDictionary (custodianaet.pacsaet)
       NSMutableDictionary *pacsDictionary=[NSMutableDictionary dictionary];
       NSUInteger pacsIndex=NSNotFound;
       for (pacsIndex=0; pacsIndex<[pacsArray count];pacsIndex++)
       {
          NSDictionary *d=pacsArray[pacsIndex];
          [pacsDictionary setObject:d forKey:d[@"pacsoid"]];
          [pacsDictionary
           setObject:d
           forKey:[d[@"custodiantitle"] stringByAppendingPathExtension:d[@"pacsaet"]]
             ];
          [pacsDictionary setObject:d forKey:[NSString stringWithFormat:@"%ld",(long)pacsIndex]];
        }
       _pacs=[NSDictionary dictionaryWithDictionary:pacsDictionary];
       _pacskeys=[pacsDictionary allKeys];
       LOG_DEBUG(@"\r\npacs dictionary entries:\r\n%@",_pacskeys);
       _pacskeysdata=[NSJSONSerialization dataWithJSONObject:_pacskeys options:0 error:nil];


#pragma mark -
#pragma mark handlers
#pragma mark -
        
#pragma mark / =wado-uri
        [self addWadoHandler];//(default handler)
       LOG_DEBUG(@"added handler GET / (=wado-uri)");

#pragma mark /echo
        [self addHandler:@"GET" path:@"/echo" processBlock:
         ^(RSRequest* request, RSCompletionBlock completionBlock)
         {completionBlock(^RSResponse* (RSRequest* request){
            return [RSDataResponse responseWithText:@"echo"];
        }(request));}];
       //            return [RSDataResponse responseWithText:[NSString stringWithFormat:@"echo time:%@ to:%@", [DICMTypes DTStringFromDate:[NSDate date]], request.remoteAddressString]];

        LOG_DEBUG(@"added handler GET /echo");
       
#pragma mark /(custodians|pacs/titles|pacs/oids)
        [self addGETCustodiansHandler];//
        [self addGETPacsHandler];//
       [self addGETSqlsHandler];//
        LOG_DEBUG(@"added handler GET /custodians and /pacs /sqls");
       
#pragma mark /qido
       //[self addMWLHandler];
       //LOG_DEBUG(@"added handler /mwlitem");

#pragma mark /wado-rs
       [self addWadorsHandler];//
       LOG_DEBUG(@"added handler GET wadors");

#pragma mark /mwlitem
        [self addMwlitemHandler];
        LOG_DEBUG(@"added handler POST /mwlitem");

#pragma mark /encapsulated
//        [self GETencapsulated];
//        [self POSTencapsulated];
//        LOG_DEBUG(@"added handlers GETencapsulated and POSTencapsulated");

#pragma mark /studyToken
        [self addPostAndGetStudyTokenHandler];
        LOG_DEBUG(@"added handler POST+GET /studyToken");

    }
    return self;
}


#pragma mark -
#pragma mark getters

+(NSDictionary*)sqls                 { return _sqls;}

+(long long)drsport                  { return _drsport;}
+(NSString*)defaultpacsoid           { return _defaultpacsoid;}

+(NSDictionary*)oids                 { return _oids;}
+(NSDictionary*)titles               { return _titles;}
+(NSData*)oidsdata                   { return _oidsdata;}
+(NSData*)titlesdata                 { return _titlesdata;}
+(NSDictionary*)oidsaeis             { return _oidsaeis;}
+(NSDictionary*)titlesaets           { return _titlesaets;}
+(NSDictionary*)titlesaetsstrings    { return _titlesaetsstrings;}

+(NSDictionary*)pacs                 { return _pacs;}
+(NSArray*)pacskeys                  { return _pacskeys;}
+(NSData*)pacskeysdata               { return _pacskeysdata;}

@end
