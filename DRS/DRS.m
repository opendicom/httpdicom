#import "DRS.h"
#import "NSData+PCS.h"
#import "NSString+PCS.h"

#import "DRS+wadouri.h"
#import "DRS+pacs.h"
//#import "DRS+qido.h"
//#import "DRS+wadors.h"

#import "DRS+mwlitem.h"
//#import "DRS+pdf.h"
//#import "DRS+encapsulated.h"
#import "DRS+studyToken.h"
//#import "DRS+store.h"

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
   
   
   LOG_INFO(@"%@ %@ content-type: %@ %@",
            request.method,
            [request.URL absoluteString],
            request.contentType,
            [request.headers description]
            );
   
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
static NSString            *_tmpDir;
static NSString            *_tokentmpDir;

static NSDictionary        *_oids=nil;
static NSDictionary        *_titles=nil;
static NSData              *_oidsdata=nil;
static NSData              *_titlesdata=nil;
static NSDictionary        *_oidsaeis=nil;
static NSDictionary        *_titlesaets=nil;
static NSDictionary        *_titlestitlesaets=nil;
static NSDictionary        *_titlesaetsstrings=nil;

static NSDictionary        *_pacs=nil;//pacsDictionary
static NSData              *_pacskeysdata=nil;

static NSArray             *_wan=nil;
static NSArray             *_lan=nil;
static NSArray             *_dev=nil;

static NSArray             *_InstanceUniqueFrameSOPClass=nil;
static NSArray             *_InstanceMultiFrameSOPClass=nil;



int execUTF8Bash(NSDictionary *environment, NSString *writeString, NSMutableData *readData)
{
   /*NSArray *whereSeparated=[writeString componentsSeparatedByString:@"WHERE"];
    
   if  (whereSeparated.count==2)
   {
       NSString *sqlOnly=[whereSeparated [1] componentsSeparatedByString:@"\"|"][0];
       NSRange firstBackSlashOffset=[sqlOnly rangeOfString:@"\\"];
       LOG_VERBOSE(@"%@",[sqlOnly substringFromIndex:firstBackSlashOffset.location + 2]);
   }
   else*/ LOG_DEBUG(@"%@",writeString);
   
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
   if (terminationStatus!=0) LOG_WARNING(@"ERROR task terminationStatus: %d",terminationStatus);
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
        tmpDir:(NSString*)tmpDir
{
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
        NSMutableDictionary *titlestitlesaets=[NSMutableDictionary dictionary];
        NSMutableDictionary *titlesaetsStrings=[NSMutableDictionary dictionary];
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
            [titlestitlesaets setObject:titletitleaets forKey:title];
            [s appendString:@")"];
            [titlesaetsStrings setObject:s forKey:title];
        }
        LOG_DEBUG(@"\r\nknown pacs aet classified by corresponding custodian title:\r\n%@",[titlesaets description]);
       
       _oids=[NSDictionary dictionaryWithDictionary:oids];
       _titles=[NSDictionary dictionaryWithDictionary:titles];
       _oidsaeis=[NSDictionary dictionaryWithDictionary:oidsaeis];
       _titlesaets=[NSDictionary dictionaryWithDictionary:titlesaets];
       _titlestitlesaets=[NSDictionary dictionaryWithDictionary:titlestitlesaets];
       _titlesaetsstrings=[NSDictionary dictionaryWithDictionary:titlesaetsStrings];

       
//_pacs receives two entries for each dev:
//- oid (get access direct)
//- custodianaet.pacsaet (get access proxied by pcs)
       NSMutableDictionary *pacsDictionary=[NSMutableDictionary dictionary];
       NSUInteger pacsIndex=NSNotFound;
       NSMutableString *pacsKeys=[NSMutableString stringWithString:@"["];
 
       
       _lan=@[(pacsArray[0])[@"custodianoid"],(pacsArray[0])[@"custodiantitle"]];
       NSMutableArray *wan=[NSMutableArray array];
       NSMutableArray *dev=[NSMutableArray array];
       
       for (pacsIndex=0; pacsIndex<[pacsArray count];pacsIndex++)
       {
          NSDictionary *d=pacsArray[pacsIndex];

          if (pacsIndex!=0)[pacsKeys appendString:@","];
             
          if (
                [d[@"custodianoid"] isEqualToString:(pacsArray[0])[@"custodianoid"]]
              ||[d[@"custodiantitle"] isEqualToString:(pacsArray[0])[@"custodiantitle"]]
              )
          {
             //dev (pacs local)
             [dev addObject:d[@"pacsoid"]];
             [dev addObject:[d[@"custodiantitle"] stringByAppendingPathExtension:d[@"pacsaet"]]];
          }
          else
          {
             //wan (pacs proxied by another pcs)
             [wan addObject:d[@"pacsoid"]];
             if ([d[@"pacsaet"] isEqualToString:d[@"custodiantitle"]])
             {
                //another pcs
                [wan addObject:d[@"custodiantitle"]];
             }
             else
             {
                //dev of another pcs
                [wan addObject:[d[@"custodiantitle"] stringByAppendingPathExtension:d[@"pacsaet"]]];
             }

          }
          
          
          [pacsDictionary setObject:d forKey:d[@"pacsoid"]];
          [pacsDictionary
           setObject:d
           forKey:[d[@"custodiantitle"] stringByAppendingPathExtension:d[@"pacsaet"]]
             ];
          [pacsDictionary setObject:d forKey:[NSString stringWithFormat:@"%ld",(long)pacsIndex]];
          [pacsKeys appendFormat:
           @"{\"direct\":\"%@\",\"proxied\":\"%@\"}",
           d[@"pacsoid"],
           [d[@"custodiantitle"] stringByAppendingPathExtension:d[@"pacsaet"]]
           ];
        }
       [pacsKeys appendString:@"]"];
       LOG_DEBUG(@"\r\nlan:\r\n%@",[_lan description]);
       _pacs=[NSDictionary dictionaryWithDictionary:pacsDictionary];
       _pacskeysdata=[pacsKeys dataUsingEncoding:NSUTF8StringEncoding];

       _wan=[NSArray arrayWithArray:wan];
       _dev=[NSArray arrayWithArray:dev];
       LOG_DEBUG(@"\r\nwan:\r\n%@",[_wan description]);
       LOG_DEBUG(@"\r\nlan:\r\n%@",[_lan description]);
       LOG_DEBUG(@"\r\ndev:\r\n%@",[_dev description]);

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

#pragma mark /store
        //[self addPOSTstudiesHandler];
        //LOG_DEBUG(@"added handler POST /stowstore");

#pragma mark /qido
       //[self addMWLHandler];
       //LOG_DEBUG(@"added handler /mwlitem");

#pragma mark /wado-rs
       //[self addWadorsHandler];//
       //LOG_DEBUG(@"added handler GET wadors");

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

#pragma mark /datatables
        [self addDatatablesStudiesHandler];
        LOG_DEBUG(@"added handler GET /datatables/studies");

        [self addDatatablesSeriesHandler];
        LOG_DEBUG(@"added handler GET /datatables/series");

       [self addDatatablesPatientHandler];
       LOG_DEBUG(@"added handler GET /datatables/patient");

#pragma mark report
       [self addXMLReportHandler];
       LOG_DEBUG(@"added handler GET ^/(OT|DOC)/(DSCD|SCD|CDA|PDF)$");

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
+(NSDictionary*)titlestitlesaets     { return _titlestitlesaets;}
+(NSDictionary*)titlesaetsstrings    { return _titlesaetsstrings;}

+(NSDictionary*)pacs                 { return _pacs;}
+(NSData*)pacskeysdata               { return _pacskeysdata;}

+(NSArray*)wan                       { return _wan;}
+(NSArray*)lan                       { return _lan;}
+(NSArray*)dev                       { return _dev;}

+(NSArray*)InstanceUniqueFrameSOPClass { return _InstanceUniqueFrameSOPClass;}
+(NSArray*)InstanceMultiFrameSOPClass { return _InstanceMultiFrameSOPClass;}

@end
