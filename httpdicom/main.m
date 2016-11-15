//
//  main.m
//  httpdicom
//
//  Created by saluduy on 20160302.
//  Copyright (c) 2016 ridi.salud.uy. All rights reserved.
//
/*
 Copyright:  Copyright (c) jacques.fauquex@opendicom.com All Rights Reserved.
 
 This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
 If a copy of the MPL was not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/
 
 Covered Software is provided under this License on an “as is” basis, without warranty of
 any kind, either expressed, implied, or statutory, including, without limitation,
 warranties that the Covered Software is free of defects, merchantable, fit for a particular
 purpose or non-infringing. The entire risk as to the quality and performance of the Covered
 Software is with You. Should any Covered Software prove defective in any respect, You (not
 any Contributor) assume the cost of any necessary servicing, repair, or correction. This
 disclaimer of warranty constitutes an essential part of this License. No use of any Covered
 Software is authorized under this License except under this disclaimer.
 
 Under no circumstances and under no legal theory, whether tort (including negligence),
 contract, or otherwise, shall any Contributor, or anyone who distributes Covered Software
 as permitted above, be liable to You for any direct, indirect, special, incidental, or
 consequential damages of any character including, without limitation, damages for lost
 profits, loss of goodwill, work stoppage, computer failure or malfunction, or any and all
 other commercial damages or losses, even if such party shall have been informed of the
 possibility of such damages. This limitation of liability shall not apply to liability for
 death or personal injury resulting from such party’s negligence to the extent applicable
 law prohibits such limitation. Some jurisdictions do not allow the exclusion or limitation
 of incidental or consequential damages, so this exclusion and limitation may not apply to
 You.
 */

#import <Foundation/Foundation.h>

#import "GCDWebServerResponse.h"
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerPrivate.h"
#import "LFCGzipUtility.h"

#import "NSString+PCS.h"
#import "NSData+PCS.h"

#import "URLSessionDataTask.h"

//static immutable write
static uint32 zipLocalFileHeader=0x04034B50;
static uint16 zipVersion=0x0A;
static uint32 zipNameLength=0x28;
static uint32 zipFileHeader=0x02014B50;
static uint32 zipEndOfCentralDirectory=0x06054B50;
static NSTimeInterval timeout=300;

//static immutable find within NSData
static NSData *rn;
static NSData *rnrn;
static NSData *rnhh;
static NSData *contentType;
static NSData *CDAOpeningTag;
static NSData *CDAClosingTag;
static NSData *ctad;

//datatables caché [session]
static NSMutableDictionary *Date;
static NSMutableDictionary *Req;
static NSMutableDictionary *Total;
static NSMutableDictionary *Filtered;
static NSMutableDictionary *sPatientID;
static NSMutableDictionary *sPatientName;
static NSMutableDictionary *sDate_start;
static NSMutableDictionary *sDate_end;
static NSMutableDictionary *sModalitiesInStudy;
static NSMutableDictionary *sStudyDescription;

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
    //[task waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
    //[aTask interrupt];
    
    [task waitUntilExit];
    int terminationStatus = [task terminationStatus];
    if (terminationStatus!=0) NSLog(@"ERROR task terminationStatus: %d",terminationStatus);
    return terminationStatus;
}

NSMutableArray *jsonMutableArray(NSString *scriptString, NSStringEncoding encoding)
{
    if      (encoding==4) GWS_LOG_DEBUG(@"utf8\r\n%@",scriptString);
    else if (encoding==5) GWS_LOG_DEBUG(@"latin1\r\n%@",scriptString);
    else                  GWS_LOG_DEBUG(@"encoding:%lu\r\n%@",(unsigned long)encoding,scriptString);

    NSMutableData *mutableData=[NSMutableData data];
    if (!task(@"/bin/bash",@[@"-s"],[scriptString dataUsingEncoding:NSUTF8StringEncoding],mutableData))
    [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"%@",@"can not execute the script"];
    NSString *string=[[NSString alloc]initWithData:mutableData encoding:encoding];//5=latinISO1 4=UTF8
    NSData *utf8Data=[string dataUsingEncoding:NSUTF8StringEncoding];

    NSError *e;
    NSMutableArray *mutableArray=[NSJSONSerialization JSONObjectWithData:utf8Data options:NSJSONReadingMutableContainers error:&e];
    if (e)
    {
        GWS_LOG_DEBUG(@"%@",[e description]);
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
    return [GCDWebServerStreamedResponse responseWithContentType:@"application/json" asyncStreamBlock:^(GCDWebServerBodyReaderCompletionBlock completionBlock)
            {
                if (__error) completionBlock(nil,__error);
                if (__chunks)
                {
                    completionBlock([NSData data], nil);
                    GWS_LOG_DEBUG(@"urlProxy: %lu chunk in %fs for:\r\n%@",__chunks,[[NSDate date] timeIntervalSinceDate:__date],[__response description]);
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


id urlProxy(NSString *urlString,NSString *contentType)
{
    __block dispatch_semaphore_t __urlProxySemaphore = dispatch_semaphore_create(0);
    __block NSData *__data;
    __block NSURLResponse *__response;
    __block NSError *__error;
    __block NSDate *__date;
    __block unsigned long __chunks=0;
    
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    if (contentType) [request setValue:contentType forHTTPHeaderField:@"Accept"];//application/dicom+json not accepted !!!!!

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

    
    return [GCDWebServerStreamedResponse responseWithContentType:contentType asyncStreamBlock:^(GCDWebServerBodyReaderCompletionBlock completionBlock)
            {
                if (__error) completionBlock(nil,__error);
                if (__chunks)
                {
                    completionBlock([NSData data], nil);
                    GWS_LOG_DEBUG(@"urlProxy: %lu chunk in %fs for:\r\n%@",__chunks,[[NSDate date] timeIntervalSinceDate:__date],[__response description]);
                }
                else completionBlock(__data, nil);
                __chunks++;
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
    
    
    return [GCDWebServerStreamedResponse responseWithContentType:contentType asyncStreamBlock:^(GCDWebServerBodyReaderCompletionBlock completionBlock)
            {
                if (__error) completionBlock(nil,__error);
                if (__chunks)
                {
                    completionBlock([NSData data], nil);
                    GWS_LOG_DEBUG(@"urlProxy: %lu chunk in %fs for:\r\n%@",__chunks,[[NSDate date] timeIntervalSinceDate:__date],[__response description]);
                }
                else completionBlock(__data, nil);
                __chunks++;
            }];
}

int main(int argc, const char* argv[]) {
    BOOL success = NO;
    /*
     syntax: 
     [0] httpdicom
     [1] [ DEBUG | VERBOSE | INFO | WARNING | ERROR | EXCEPTION]
     [2] puerto
     [3] path to pacs.plist
     */
    
    @autoreleasepool {

        NSArray *args=[[NSProcessInfo processInfo] arguments];
        if ([args count]!=4)
        {
            NSLog(@"syntax: httpdicom port path2pacs.plist");
            return 1;
        }
        
        
        //[1]
        NSArray *logLevel=@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"];
        if ([logLevel indexOfObject:args[1]]==NSNotFound)
        {
            NSLog(@"logLevel (arg 1) should be one of [ DEBUG | VERBOSE | INFO | WARNING | ERROR | EXCEPTION]");
            return 1;
        }
        [GCDWebServer setLogLevel:(int)[logLevel indexOfObject:args[1]]];
        
        //[2]
        long long port=[args[2]longLongValue];
        
        if (port <1 || port>65535)
        {
            NSLog(@"port should be between 0 and 65535");
            return 1;
        }
        
        //[3]
        NSDictionary *pacsArray=[NSDictionary dictionaryWithContentsOfFile:[args[3]stringByExpandingTildeInPath]];
        if (!pacsArray)
        {
            NSLog(@"could not get contents of pacs.plist");
            return 1;
        }
        
        NSDateFormatter *dicomDTFormatter = [[NSDateFormatter alloc] init];
        [dicomDTFormatter setDateFormat:@"yyyyMMddHHmmss"];
        NSRegularExpression *UIRegex = [NSRegularExpression regularExpressionWithPattern:@"^[1-2](\\d)*(\\.0|\\.[1-9](\\d)*)*$" options:0 error:NULL];
        NSRegularExpression *SHRegex = [NSRegularExpression regularExpressionWithPattern:@"^(?:\\s*)([^\\r\\n\\f\\t]*[^\\r\\n\\f\\t\\s])(?:\\s*)$" options:0 error:NULL];
        
        //static immutable
        rn=[@"/r/n" dataUsingEncoding:NSASCIIStringEncoding];//0x0A0D;
        rnrn=[@"/r/n/r/n" dataUsingEncoding:NSASCIIStringEncoding];//0x0A0D0A0D;
        rnhh=[@"/r/n--" dataUsingEncoding:NSASCIIStringEncoding];//0x2D2D0A0D;
        contentType=[@"Content-Type: " dataUsingEncoding:NSASCIIStringEncoding];
        CDAOpeningTag=[@"<ClinicalDocument" dataUsingEncoding:NSASCIIStringEncoding];
        CDAClosingTag=[@"</ClinicalDocument>" dataUsingEncoding:NSASCIIStringEncoding];
        ctad=[@"Content-Type: application/dicom\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
        
        //datatables caché [session]
        Req=[NSMutableDictionary dictionary];
        Total=[NSMutableDictionary dictionary];
        Filtered=[NSMutableDictionary dictionary];
        Date=[NSMutableDictionary dictionary];
        sPatientID=[NSMutableDictionary dictionary];
        sPatientName=[NSMutableDictionary dictionary];
        sDate_start=[NSMutableDictionary dictionary];
        sDate_end=[NSMutableDictionary dictionary];
        sModalitiesInStudy=[NSMutableDictionary dictionary];
        sStudyDescription=[NSMutableDictionary dictionary];
        

        //custodians y aets
        NSMutableSet *custodianOIDs=[NSMutableSet set];
        NSMutableSet *custodianTitles=[NSMutableSet set];
        NSMutableSet *sqlset=[NSMutableSet set];
        
        for (NSDictionary *dictionary in [pacsArray allValues])
        {
            [custodianOIDs addObject:[dictionary objectForKey:@"custodianoid"]];
            [custodianTitles addObject:[dictionary objectForKey:@"custodiantitle"]];
            NSString *s=[dictionary objectForKey:@"sql"];
            if (s) [sqlset addObject:s];
        }
        NSArray *custodianOIDsArray=[custodianOIDs allObjects];
        NSData *custodianOIDsData = [NSJSONSerialization dataWithJSONObject:custodianOIDsArray options:0 error:nil];
        NSArray *custodianTitlesArray=[custodianTitles allObjects];
        NSData *custodianTitlesData = [NSJSONSerialization dataWithJSONObject:custodianTitlesArray options:0 error:nil];

        //crear un dictionario con índice custodianOID y custodianTitle y objeto el json corresondiente de lista de aet o de lista de aei
        NSMutableDictionary *custodianOIDsaeis=[NSMutableDictionary dictionary];
        for (NSString *custodianOID in custodianOIDsArray)
        {
            NSMutableArray *custodianOIDaeis=[NSMutableArray array];
            for (NSString *k in [pacsArray allKeys])
            {
                NSDictionary *d=[pacsArray objectForKey:k];
                if ([[d objectForKey:@"custodianoid"]isEqualToString:custodianOID])[custodianOIDaeis addObject:k];
            }
            [custodianOIDsaeis setValue:custodianOIDaeis forKey:custodianOID];
        }

        NSMutableDictionary *custodianTitlesaets=[NSMutableDictionary dictionary];
        for (NSString *custodianTitle in custodianTitlesArray)
        {
            NSMutableArray *custodianTitleaets=[NSMutableArray array];
            for (NSString *k in [pacsArray allKeys])
            {
                NSDictionary *d=[pacsArray objectForKey:k];
                if ([[d objectForKey:@"custodiantitle"]isEqualToString:custodianTitle])
                    [custodianTitleaets addObject:[d objectForKey:@"dicomaet"]];
            }
            [custodianTitlesaets setObject:custodianTitleaets forKey:custodianTitle];
        }

        
        GCDWebServer* httpdicomServer = [[GCDWebServer alloc] init];
        
        //sql configurations
        NSMutableDictionary *sql=[NSMutableDictionary dictionary];
        for (NSString *s in sqlset)
        {
            [sql setObject:[NSDictionary dictionaryWithContentsOfFile:[s stringByExpandingTildeInPath]] forKey:s];
        }

#pragma mark no handler for GET
        [httpdicomServer addDefaultHandlerForMethod:@"GET"
         requestClass:[GCDWebServerRequest class]
         processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
             //request parts logging
             NSURL *requestURL=request.URL;
             NSString *bSlash=requestURL.baseURL.absoluteString;
             NSString *b=[bSlash substringToIndex:[bSlash length]-1];
             NSString *p=requestURL.path;
             //NSString *q=requestURL.query;
             NSDictionary *q=request.query;
             GWS_LOG_WARNING(@"%@%@?%@ [no handler]",b,p,q);
             return [GCDWebServerErrorResponse
                     responseWithClientError:400
                     message:@"%@ [no handler]",request.path];
         }];
        

#pragma mark custodians
        
        [httpdicomServer
         addHandlerForMethod:@"GET"
         pathRegularExpression:[NSRegularExpression regularExpressionWithPattern:@"^/custodians/.*$" options:0 error:NULL]
         requestClass:[GCDWebServerRequest class]
         processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
             NSArray *pComponents=[request.path componentsSeparatedByString:@"/"];
             NSUInteger pCount=[pComponents count];
             
             if (pCount<3) return [GCDWebServerErrorResponse responseWithClientError:400 message:@"%@ [no handler]",request.path];
             
             if ([pComponents[2]isEqualToString:@"titles"])
             {
                 //custodian/titles
                 if (pCount==3) return [GCDWebServerDataResponse responseWithData:custodianTitlesData contentType:@"application/json"];
                 
                 NSUInteger p3Length = [pComponents[3] length];
                 if (  (p3Length>16)
                     ||![SHRegex numberOfMatchesInString:pComponents[3] options:0 range:NSMakeRange(0,p3Length)])
                     return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [{title} datatype should be DICOM SH]",request.path];
                 
                 NSUInteger custodianTitleIndex=[custodianTitlesArray indexOfObject:pComponents[3]];
                 if (custodianTitleIndex==NSNotFound)
                     return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [{title} not found]",request.path];
                 
                 //custodian/titles/{TITLE}
                 if (pCount==4) return [GCDWebServerDataResponse responseWithData:[NSJSONSerialization dataWithJSONObject:[NSArray arrayWithObject:[custodianOIDsArray objectAtIndex:custodianTitleIndex]] options:0 error:nil] contentType:@"application/json"];
                 
                 if (![pComponents[4]isEqualToString:@"aets"])
                     return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [{title} unique resource is 'aets']",request.path];
                 
                 //custodian/titles/{title}/aets
                 if (pCount==5)
                     return [GCDWebServerDataResponse responseWithData:[NSJSONSerialization dataWithJSONObject:[custodianTitlesaets objectForKey:pComponents[3]] options:0 error:nil] contentType:@"application/json"];

                 NSUInteger p5Length = [pComponents[5]length];
                 if (  (p5Length>16)
                     ||![SHRegex numberOfMatchesInString:pComponents[5] options:0 range:NSMakeRange(0,p5Length)])
                     return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [{aet}datatype should be DICOM SH]",request.path];
                 
                 NSUInteger aetIndex=[[custodianTitlesaets objectForKey:pComponents[3]] indexOfObject:pComponents[5]];
                 if (aetIndex==NSNotFound)
                     return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [{aet} not found]",request.path];

                 if (pCount>6) return [GCDWebServerErrorResponse responseWithClientError:400 message:@"%@ [no handler]",request.path];

                 //custodian/titles/{title}/aets/{aet}
                     return [GCDWebServerDataResponse responseWithData:
                             [NSJSONSerialization dataWithJSONObject:
                              [NSArray arrayWithObject:(custodianOIDsaeis[custodianOIDsArray[custodianTitleIndex]])[aetIndex]]
                              options:0
                              error:nil
                             ]
                             contentType:@"application/json"
                            ];
             }
             
             
             if ([pComponents[2]isEqualToString:@"oids"])
             {
                 //custodian/oids
                 if (pCount==3) return [GCDWebServerDataResponse responseWithData:custodianOIDsData contentType:@"application/json"];
                 
                 NSUInteger p3Length = [pComponents[3] length];
                 if (  (p3Length>64)
                     ||![UIRegex numberOfMatchesInString:pComponents[3] options:0 range:NSMakeRange(0,p3Length)]
                     )
                     return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [{OID} datatype should be DICOM UI]",request.path];
                 
                 NSUInteger custodianOIDIndex=[custodianOIDsArray indexOfObject:pComponents[3]];
                 if (custodianOIDIndex==NSNotFound)
                     return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [{OID} not found]",request.path];
                 
                 //custodian/oids/{OID}
                 if (pCount==4) return [GCDWebServerDataResponse responseWithData:[NSJSONSerialization dataWithJSONObject:[NSArray arrayWithObject:[custodianTitlesArray objectAtIndex:custodianOIDIndex]] options:0 error:nil] contentType:@"application/json"];
                 
                 if (![pComponents[4]isEqualToString:@"aeis"])
                     return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [{OID} unique resource is 'aeis']",request.path];
                 
                 //custodian/oids/{OID}/aeis
                 if (pCount==5)
                     return [GCDWebServerDataResponse responseWithData:[NSJSONSerialization dataWithJSONObject:[custodianOIDsaeis objectForKey:pComponents[3]] options:0 error:nil] contentType:@"application/json"];
                 
                 NSUInteger p5Length = [pComponents[5]length];
                 if (  (p5Length>64)
                     ||![UIRegex numberOfMatchesInString:pComponents[5] options:0 range:NSMakeRange(0,p5Length)]
                     )
                     return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [{aei}datatype should be DICOM UI]",request.path];
                 
                 NSUInteger aeiIndex=[[custodianOIDsaeis objectForKey:pComponents[3]] indexOfObject:pComponents[5]];
                 if (aeiIndex==NSNotFound)
                     return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [{aei} not found]",request.path];
                 
                 if (pCount>6) return [GCDWebServerErrorResponse responseWithClientError:400 message:@"%@ [no handler]",request.path];
                 
                 //custodian/oids/{OID}/aeis/{aei}
                 return [GCDWebServerDataResponse responseWithData:
                         [NSJSONSerialization dataWithJSONObject:
                          [NSArray arrayWithObject:(custodianTitlesaets[custodianTitlesArray[custodianOIDIndex]])[aeiIndex]]
                                                         options:0
                                                           error:nil
                          ]
                                                       contentType:@"application/json"
                         ];
             }
             return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [no handler]",request.path];
         }
         ];
        

#pragma mark -
        
#pragma mark QIDO
        // /pacs/{oid}/rs/( studies | series | instances )?
        NSRegularExpression *qidoregex = [NSRegularExpression regularExpressionWithPattern:@"^\\/pacs\\/[1-2](\\d)*(\\.0|\\.[1-9](\\d)*)*\\/rs\\/(studies|series|instances)$" options:NSRegularExpressionCaseInsensitive error:NULL];
        
        [httpdicomServer addHandlerForMethod:@"GET"
                       pathRegularExpression:qidoregex
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
             NSArray *pComponents=[request.path componentsSeparatedByString:@"/"];
             NSDictionary *pacsaei=pacsArray[pComponents[2]];
             if (!pacsaei) return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [{pacs} not found]",request.path];

             NSString *pcsuri=pacsaei[@"pcsuri"];

             NSString *q=request.URL.query;//a same param may repeat
             
             NSString *qidoBaseString=pacsaei[@"qido"];
             if (![qidoBaseString isEqualToString:@""])
             {
                 return qidoUrlProxy(
                                 [NSString stringWithFormat:@"%@/%@",qidoBaseString,pComponents.lastObject],
                                 q,
                                     [pcsuri stringByAppendingString:request.path]
                                 );//application/dicom+json not accepted
             }
             
             NSString *sql=pacsaei[@"sql"];
             if (sql)
             {
                 //local ... simulation qido through database access
#pragma mark TODO QIDO SQL
             }
             
             if (pcsuri)
             {
                 //remote... access through another PCS
                 NSString *urlString;
                 if (q) urlString=[NSString stringWithFormat:@"%@/%@?%@",
                                    pcsuri,
                                    request.path,
                                    q];
                 else    urlString=[NSString stringWithFormat:@"%@/%@?",
                                     pcsuri,
                                     request.path];
                 GWS_LOG_INFO(@"[QIDO] %@",urlString);
                 return urlProxy(urlString,@"application/dicom+json");
             }
             
             
             return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [QIDO not available]",request.path];
         }];
        
        
#pragma mark WADO-URI
        NSRegularExpression *wadouriregex = [NSRegularExpression regularExpressionWithPattern:@"^\\/$" options:NSRegularExpressionCaseInsensitive error:NULL];
        
        [httpdicomServer addHandlerForMethod:@"GET"
                       pathRegularExpression:wadouriregex
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
             NSArray *pComponents=[request.path componentsSeparatedByString:@"/"];
             //NSDictionary *pacsaei=pacsArray[pComponents[2]];
             NSDictionary *pacsaei=pacsArray[(request.query)[@"custodianOID"]];
             if (!pacsaei) return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [{pacs} not found]",request.path];
             
             NSString *q=request.URL.query;//a same param may repeat

             NSString *wadouriBaseString=pacsaei[@"wadouri"];
             if (![wadouriBaseString isEqualToString:@""])
             {
                 //local ... there exists an URL
                 NSString *wadouriString;
                 if (q) wadouriString=[NSMutableString stringWithFormat:@"%@?%@",
                                    wadouriBaseString,
                                    q];
                 [wadouriString stringByReplacingOccurrencesOfString:@"%22" withString:@""];

                 GWS_LOG_INFO(@"[WADO-URI] %@",wadouriString);
                 //no se agrega ningún control para no enlentecer
                 //podría optimizarse con creación asíncrona de la data
                 //paquetes entran y salen sin esperar el fin de la entrada...
                 NSData *responseData=[NSData dataWithContentsOfURL:[NSURL URLWithString:wadouriString]];
                 if (!responseData) return
                     [GCDWebServerErrorResponse
                      responseWithClientError:kGCDWebServerHTTPStatusCode_FailedDependency
                      message:@"no reply"];
                 
                 if (![responseData length]) return
                     [GCDWebServerErrorResponse
                      responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound
                      message:@"empty reply"];
                 return [GCDWebServerDataResponse
                         responseWithData:responseData
                         contentType:@"application/dicom"
                         ];
             }
             
             NSString *pcsuri=pacsaei[@"pcsuri"];
             if (pcsuri)
             {
                 //remote... access through another PCS
                 NSString *urlString;
                 if (q) urlString=[NSString stringWithFormat:@"%@/%@",
                                   pcsuri,
                                   request.path];
                 else    urlString=[NSString stringWithFormat:@"%@/%@",
                                    pcsuri,
                                    request.path];
                 GWS_LOG_INFO(@"[QIDO] %@",urlString);
                 return urlProxy(urlString,@"application/dicom+json");
             }

             return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [WADO-URI not available]",request.path];
         }];
        
        
#pragma mark WADO-RS
        // /pacs/{OID}/studies/{StudyInstanceUID}
        // /pacs/{OID}/studies/{StudyInstanceUID}/series/{SeriesInstanceUID}
        // /pacs/{OID}/studies/{StudyInstanceUID}/series/{SeriesInstanceUID}/instances/{SOPInstanceUID}
        //Accept: multipart/related;type="application/dicom"
        NSRegularExpression *wadorsregex = [NSRegularExpression regularExpressionWithPattern:@"^\\/pacs\\/[1-2](\\d)*(\\.0|\\.[1-9](\\d)*)*\\/rs\\/studies\\/" options:NSRegularExpressionCaseInsensitive error:NULL];
        
        [httpdicomServer addHandlerForMethod:@"GET"
                       pathRegularExpression:wadorsregex
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
             NSArray *pComponents=[request.path componentsSeparatedByString:@"/"];
             NSDictionary *pacsaei=pacsArray[pComponents[2]];
             if (!pacsaei) return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [{pacs} not found]",request.path];

             NSString *wadorsBaseString=pacsaei[@"wadors"];
             if (![wadorsBaseString isEqualToString:@""])
             {
                 //local ... there exists an URI that uses the PACS implementation
                 NSString *urlString;
                 if (pComponents.count==6) urlString=[NSString stringWithFormat:@"%@/studies/%@",wadorsBaseString,pComponents[5]];
                 else if (pComponents.count==8) urlString=[NSString stringWithFormat:@"%@/studies/%@/series/%@", wadorsBaseString,pComponents[5],pComponents[7]];
                 else if (pComponents.count==10) urlString=[NSString stringWithFormat:@"%@/studies/%@/series/%@/instances/%@", wadorsBaseString,pComponents[5],pComponents[7],pComponents[9]];
                 else return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [WADO-RS studies and studies/series only]",request.path];
                 GWS_LOG_INFO(@"[WADO-RS] %@",urlString);
                 return urlProxy(urlString,@"multipart/related;type=application/dicom");
             }
             
             NSString *sql=pacsaei[@"sql"];
             if (sql)
             {
                 //local ... the PCS simulates wadors thanks to a combination of
                 //database access and wado-url
#pragma mark TODO WADO-RS SQL
             }
             
             NSString *pcsuri=pacsaei[@"pcsuri"];
             if (pcsuri)
             {
                 //when there is neither direct access to pacs implementation nor sql access in order to simulate the function, then we use the proxying services of another PCS accessed through pcsuri
                 NSString *urlString=[NSString stringWithFormat:@"%@/%@",pcsuri,request.path];
                 GWS_LOG_INFO(@"[WADO-RS] %@",urlString);
                 return urlProxy(urlString,@"multipart/related;type=application/dicom");
             }
             return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [WADO-RS not available]",request.path];
         }];

        
#pragma mark dcm.zip
        //servicio de segundo nivel que llama a WADO-RS para su realización
        NSRegularExpression *dcmzipregex = [NSRegularExpression regularExpressionWithPattern:@"^\\/pacs\\/[1-2](\\d)*(\\.0|\\.[1-9](\\d)*)*\\/dcm.zip$" options:NSRegularExpressionCaseInsensitive error:NULL];
        
        [httpdicomServer addHandlerForMethod:@"GET"
                       pathRegularExpression:dcmzipregex
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
        {
            NSLog(@"osirix");
            NSArray *pComponents=[request.path componentsSeparatedByString:@"/"];
            NSDictionary *destPacs=pacsArray[pComponents[2]];
            if (!destPacs) return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [{pacs} not found]",request.path];

            //buscar SERIES wadors URIs
            if (!destPacs[@"qido"]) return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [qido not available]",request.path];
            NSArray *seriesArray=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/series?%@",destPacs[@"qido"],request.URL.query]]] options:0 error:nil];

            
            __block NSMutableArray *wados=[NSMutableArray array];
            for (NSDictionary *dictionary in seriesArray)
            {
                //download series
                //00081190 UR RetrieveURL
                [wados addObject:((dictionary[@"00081190"])[@"Value"])[0]];
#pragma mark TODO correct proxy wadors...
            }
            GWS_LOG_DEBUG(@"%@",[wados description]);

            
            __block NSMutableData *wadors=[NSMutableData data];
            __block NSMutableData *boundary=[NSMutableData data];
            __block NSMutableData *directory=[NSMutableData data];
            __block NSRange wadorsRange=NSMakeRange(0,0);
            __block uint32 entryPointer=0;
            __block uint16 entriesCount=0;
            __block NSRange ctadRange=NSMakeRange(0,0);
            __block NSRange boundaryRange=NSMakeRange(0,0);

            /**
             *  The GCDWebServerAsyncStreamBlock works like the GCDWebServerStreamBlock
             *  except the streamed data can be returned at a later time allowing for
             *  truly asynchronous generation of the data.
             *
             *  The block must call "completionBlock" passing the new chunk of data when ready,
             *  an empty NSData when done, or nil on error and pass a NSError.
             *
             *  The block cannot call "completionBlock" more than once per invocation.
             */
            
            GCDWebServerStreamedResponse* response = [GCDWebServerStreamedResponse responseWithContentType:@"application/octet-stream" asyncStreamBlock:^(GCDWebServerBodyReaderCompletionBlock completionBlock)
            {
                if (wadorsRange.length<1000)
                {
                    NSLog(@"need data. Remaining wadors:%lu",(unsigned long)wados.count);
                    if (wados.count>0)
                    {
                        //request, response and error
                        NSMutableURLRequest *wadorsRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:wados[0]] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:timeout];
                        //https://developer.apple.com/reference/foundation/nsurlrequestcachepolicy?language=objc
                        //NSURLRequestReloadIgnoringCacheData
                        [wadorsRequest setHTTPMethod:@"GET"];
                        [wadorsRequest setValue:@"multipart/related;type=application/dicom" forHTTPHeaderField:@"Accept"];
                        NSHTTPURLResponse *response=nil;
                        //URL properties: expectedContentLength, MIMEType, textEncodingName
                        //HTTP properties: statusCode, allHeaderFields
                        
                        NSError *error=nil;
                        [wadors setData:[NSURLConnection sendSynchronousRequest:wadorsRequest returningResponse:&response error:&error]];
                        if (response.statusCode==200)
                        {
                            wadorsRange.location=0;
                            wadorsRange.length=[wadors length];
                            NSString *ctString=response.allHeaderFields[@"Content-Type"];
                            NSString *boundaryString=[@"\r\n--" stringByAppendingString:[ctString substringFromIndex:ctString.length-36]];
                            [boundary setData:[boundaryString dataUsingEncoding:NSUTF8StringEncoding]];
                            NSLog(@"%@\r\n(%lu,%lu) boundary:%@",wados[0],(unsigned long)wadorsRange.location,(unsigned long)wadorsRange.length,boundaryString);
                        }
                        [wados removeObjectAtIndex:0];
                    }
                }
                ctadRange=[wadors rangeOfData:ctad options:0 range:wadorsRange];
                boundaryRange=[wadors rangeOfData:boundary options:0 range:wadorsRange];
                if ((ctadRange.length>0) && (boundaryRange.length>0)) //chunk with new entry
                {
                    //dcm
                    unsigned long dcmLocation=ctadRange.location+ctadRange.length;
                    unsigned long dcmLength=boundaryRange.location-dcmLocation;
                    wadorsRange.location=boundaryRange.location+boundaryRange.length;
                    wadorsRange.length=wadors.length-wadorsRange.location;
                    
                    NSString *dcmUUID=[[[NSUUID UUID]UUIDString]stringByAppendingPathExtension:@"dcm"];
                    NSData *dcmName=[dcmUUID dataUsingEncoding:NSUTF8StringEncoding];
                    NSLog(@"dcm (%lu bytes):%@",dcmLength,dcmUUID);
                    
                    __block NSMutableData *entry=[NSMutableData data];
                    [entry appendBytes:&zipLocalFileHeader length:4];//0x04034B50
                    [entry appendBytes:&zipVersion length:2];//0x000A
                    [entry increaseLengthBy:8];//uint32 flagCompression,zipTimeDate
                    
                    NSData *dcmData=[wadors subdataWithRange:NSMakeRange(dcmLocation,dcmLength)];
                    uint32 zipCrc32=[dcmData crc32];
                    
                    [entry appendBytes:&zipCrc32 length:4];
                    [entry appendBytes:&dcmLength length:4];//zipCompressedSize
                    [entry appendBytes:&dcmLength length:4];//zipUncompressedSize
                    [entry appendBytes:&zipNameLength length:4];//0x28
                    [entry appendData:dcmName];
                    //extra param
                    [entry appendData:dcmData];
                    
                    completionBlock(entry, nil);
                    
                    //directory
                    [directory appendBytes:&zipFileHeader length:4];//0x02014B50
                    [directory appendBytes:&zipVersion length:2];//0x000A
                    [directory appendBytes:&zipVersion length:2];//0x000A
                    [directory increaseLengthBy:8];//uint32 flagCompression,zipTimeDate
                    [directory appendBytes:&zipCrc32 length:4];
                    [directory appendBytes:&dcmLength length:4];//zipCompressedSize
                    [directory appendBytes:&dcmLength length:4];//zipUncompressedSize
                    [directory appendBytes:&zipNameLength length:4];//0x28
                    /*
                     uint16 zipFileCommLength=0x0;
                     uint16 zipDiskStart=0x0;
                     uint16 zipInternalAttr=0x0;
                     uint32 zipExternalAttr=0x0;
                     */
                    [directory increaseLengthBy:10];
                    
                    [directory appendBytes:&entryPointer length:4];//offsetOfLocalHeader
                    entryPointer+=dcmLength+70;
                    entriesCount++;
                    [directory appendData:dcmName];
                    //extra param
                }
                else if (directory.length) //chunk with directory
                {
                    //ZIP "end of central directory record"
                    
                    //uint32 zipEndOfCentralDirectory=0x06054B50;
                    [directory appendBytes:&zipEndOfCentralDirectory length:4];
                    [directory increaseLengthBy:4];//zipDiskNumber
                    [directory appendBytes:&entriesCount length:2];//disk zipEntries
                    [directory appendBytes:&entriesCount length:2];//total zipEntries
                    uint32 directorySize=86 * entriesCount;
                    [directory appendBytes:&directorySize length:4];
                    [directory appendBytes:&entryPointer length:4];
                    [directory increaseLengthBy:2];//zipCommentLength
                    completionBlock(directory, nil);
                    [directory setData:[NSData data]];
                }
                else completionBlock([NSData data], nil);//last chunck
                
            }];

            return response;
        }];

        

        
#pragma mark ot  doc  cda
        /*
        {proxy}/ot?
        {proxy}/doc?
        {proxy}/cda?
         */
        NSRegularExpression *applicableregex = [NSRegularExpression regularExpressionWithPattern:@"^\\/pacs\\/[1-2](\\d)*(\\.0|\\.[1-9](\\d)*)*\\/(ot|doc|cda)$" options:NSRegularExpressionCaseInsensitive error:NULL];
         
         [httpdicomServer addHandlerForMethod:@"GET"
                       pathRegularExpression:applicableregex
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
             NSArray *pComponents=[request.path componentsSeparatedByString:@"/"];
             NSDictionary *destPacs=pacsArray[pComponents[2]];
             if (!destPacs) return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [{pacs} not found]",request.path];
             
             //buscar SERIES wadors URIs
             if (!destPacs[@"qido"]) return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [qido not available]",request.path];

             //AccessionNumber
             NSString *q=request.URL.query;
             if (q.length>32 || ![q hasPrefix:@"AccessionNumber="]) [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [lacks parameter AccessionNumber]",request.path];
             NSString *accessionNumber=[q substringWithRange:NSMakeRange(16,q.length-16)];
             
             NSString *modality;
                  if ([pComponents[3] isEqualToString:@"doc"]) modality=@"DOC";
             else if ([pComponents[3] isEqualToString:@"cda"]) modality=@"DOC";
             else if ([pComponents[3] isEqualToString:@"ot"]) modality=@"OT";
             
             //instances?AccessionNumber={AccessionNumber}&Modality=DOC
             NSString *qidoString=[NSString stringWithFormat:@"%@/instances?AccessionNumber=%@&Modality=%@",
                                destPacs[@"qido"],
                                accessionNumber,
                                modality];
             GWS_LOG_DEBUG(@"%@/r/n->%@",request.path,qidoString);
             NSData *instanceQidoData=[NSData dataWithContentsOfURL:
                                   [NSURL URLWithString:qidoString]];

             
             //applicable, latest doc
             //6.7.1.2.3.2 JSON Results
             //If there are no matching results,the JSON message is empty.
             if (!instanceQidoData || ![instanceQidoData length]) [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [not found]",request.path];
             
             NSArray *instanceArray=[NSJSONSerialization JSONObjectWithData:instanceQidoData options:0 error:nil];
             NSUInteger instanceArrayCount=[instanceArray count];
             if (instanceArrayCount==0) [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"dev0 /applicable not found"];
             
             NSDictionary *instance;
             NSInteger i=0;
             NSInteger index=0;
             NSInteger date=0;
             NSInteger time=0;
             if (instanceArrayCount==1) instance=instanceArray[0];
             else
             {
                 for (i=0;  i<instanceArrayCount; i++)
                 {
                     NSInteger PPSSD=[(((instanceArray[i])[@"00400244"])[@"Value"])[0] longValue];
                     NSInteger PPSST=[(((instanceArray[i])[@"00400245"])[@"Value"])[0] longValue];
                     if ((PPSSD > date) || ((PPSSD==date)&&(PPSST>time)))
                     {
                         date=PPSSD;
                         time=PPSST;
                         index=i;
                     }
                 }
                 instance=instanceArray[index];
             }

             //wadors returns bytstream with 00420010
             NSString *wadoRsString=(((instanceArray[index])[@"00081190"])[@"Value"])[0];
             GWS_LOG_INFO(@"applicable wadors %@",wadoRsString);
             
             NSData *applicableData=[NSData dataWithContentsOfURL:[NSURL URLWithString:wadoRsString]];
             if (!applicableData || ![applicableData length]) return [GCDWebServerErrorResponse responseWithClientError:404 message:@"applicable %@ notFound",request.URL.path];

             NSUInteger applicableDataLength=[applicableData length];

             NSUInteger valueLocation;
             //between "Content-Type: " and "\r\n"
             NSRange ctRange  = [applicableData rangeOfData:contentType options:0 range:NSMakeRange(0, applicableDataLength)];
             valueLocation=ctRange.location+ctRange.length;
             NSRange rnRange  = [applicableData rangeOfData:rn options:0 range:NSMakeRange(valueLocation, applicableDataLength-valueLocation)];
             NSData *contentTypeData=[applicableData subdataWithRange:NSMakeRange(valueLocation,rnRange.location-valueLocation)];
             NSString *ctString=[[NSString alloc]initWithData:contentTypeData encoding:NSUTF8StringEncoding];
             GWS_LOG_INFO(@"%@",ctString);

             
             //between "\r\n\r\n" and "\r\n--"
             NSRange rnrnRange=[applicableData rangeOfData:rnrn options:0 range:NSMakeRange(0, applicableDataLength)];
             valueLocation=rnrnRange.location+rnrnRange.length;
             NSRange rnhhRange=[applicableData rangeOfData:rnhh options:0 range:NSMakeRange(valueLocation, applicableDataLength-valueLocation)];
             
             //encapsulatedData
             NSData *encapsulatedData=[applicableData subdataWithRange:NSMakeRange(valueLocation,rnhhRange.location-valueLocation - 1 - ([[applicableData subdataWithRange:NSMakeRange(rnhhRange.location-2,2)] isEqualToData:rn] * 2))];
                 
             if ([modality isEqualToString:@"CDA"])
             {
                 GWS_LOG_INFO(@"CDA");
                 NSRange CDAOpeningTagRange=[encapsulatedData rangeOfData:CDAOpeningTag options:0 range:NSMakeRange(0, encapsulatedData.length)];
                 if (CDAOpeningTagRange.location != NSNotFound)
                 {
                     NSRange CDAClosingTagRange=[encapsulatedData rangeOfData:CDAClosingTag options:0 range:NSMakeRange(0, encapsulatedData.length)];
                     NSData *cdaData=[encapsulatedData subdataWithRange:NSMakeRange(CDAOpeningTagRange.location, CDAClosingTagRange.location+CDAClosingTagRange.length-CDAOpeningTagRange.location)];
                     return [GCDWebServerDataResponse
                             responseWithData:cdaData
                             contentType:ctString];
                 }
             }
             
             return [GCDWebServerDataResponse
                    responseWithData:encapsulatedData
                    contentType:ctString];
         }
         ];

        
        
#pragma mark /manifest/weasis/studies?
        
        NSRegularExpression *mwstudiesregex = [NSRegularExpression regularExpressionWithPattern:@"^/manifest/weasis/studies" options:NSRegularExpressionCaseInsensitive error:NULL];
        [httpdicomServer addHandlerForMethod:@"GET"
                       pathRegularExpression:mwstudiesregex
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
             //request parts logging
             NSURL *requestURL=request.URL;
             NSString *bSlash=requestURL.baseURL.absoluteString;
             NSString *b=[bSlash substringToIndex:[bSlash length]-1];
             NSString *p=requestURL.path;
             //NSString *q=requestURL.query;
             NSDictionary *q=request.query;


             NSDictionary *destPacs=pacsArray[q[@"custodianOID"]];
             NSDictionary *destSql=sql[destPacs[@"sql"]];
             if (!destSql) return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [sql not found]",request.path];

             NSString *sqlString;
             NSString *AccessionNumber=request.query[@"AccessionNumber"];
             if (AccessionNumber)sqlString=[NSString stringWithFormat:destSql[@"manifestWeasisStudyAccessionNumber"],AccessionNumber];
             else
             {
                 NSString *StudyInstanceUID=request.query[@"StudyInstanceUID"];
                 if (StudyInstanceUID)sqlString=[NSString stringWithFormat:destSql[@"manifestWeasisStudyStudyInstanceUID"],StudyInstanceUID];
                 else return [GCDWebServerErrorResponse responseWithClientError:404 message:
                              @"parameter AccessionNumber or StudyInstanceUID required in %@%@?%@",b,p,q];
             }
             //SQL for studies
             NSMutableData *studiesData=[NSMutableData data];
             int studiesResult=task(@"/bin/bash",
                                    @[@"-s"],
                                    [sqlString dataUsingEncoding:NSUTF8StringEncoding],
                                    studiesData
                                    );
             NSMutableArray *studyArray=[NSJSONSerialization JSONObjectWithData:studiesData options:0 error:nil];
            /*
                [0]  p.family_name,p.given_name,p.middle_name,p.name_prefix,p.name_suffix,
                [1] patient_id.pat_id,
                [2] iopid.entity_uid,
                [3] patient.pat_birthdate,
                [4] patient.pat_sex,
             
                [5] study.study_iuid,
                [6] study.accession_no,
                [7] ioan.entity_uid,
                [8] study_query_attrs.retrieve_aets,
                [9] study.study_id,
                [10] study.study_desc,
                [11] study.study_date,
                [12] study.study_time
                [13] NumberOfStudyRelatedInstances
             */
             //the accessionNumber may join more than one study of one or more patient !!!
             //look for patient roots first
             NSMutableArray *uniquePatients=[NSMutableArray array];
             for (NSArray *studyInstance in studyArray)
             {
                 [uniquePatients addObject:[studyInstance[1]stringByAppendingPathComponent:studyInstance[2]]];
             }
             
             NSMutableString *weasisManifest=[NSMutableString string];
             //each patient
                 for (NSString *patient in [NSSet setWithArray:uniquePatients])
                 {
                     NSUInteger studyIndex=[uniquePatients indexOfObject:patient];
                     NSArray *patientAttrs=studyArray[studyIndex];
                     [weasisManifest appendFormat:
                      @"<Patient PatientName=\"%@\" PatientID=\"%@\" IssuerOfPatientID=\"%@\" PatientBirthDate=\"%@\" PatientSex=\"%@\">\r",
                      patientAttrs[0],
                      patientAttrs[1],
                      patientAttrs[2],
                      patientAttrs[3],
                      patientAttrs[4]
                      ];
                     
                     for (NSArray *studyInstance in studyArray)
                     {
                         if (  [studyInstance[1]isEqualToString:patientAttrs[1]]
                             &&[studyInstance[2]isEqualToString:patientAttrs[2]]
                            )
                         {
                            //each study of this patient
                             [weasisManifest appendFormat:
                              @"<Study SpecificCharacterSet=\"UTF-8\" StudyInstanceUID=\"%@\" AccessionNumber=\"%@\" IssuerOfAccessionNumber=\"%@\" RetrieveAETitle=\"%@\" StudyID=\"%@\" StudyDescription=\"%@\" StudyDate=\"%@\" StudyTime=\"%@\" WadorsURI=\"/studies/%@\" NumberOfStudyRelatedInstances=\"%@\">\r",
                              studyInstance[5],
                              studyInstance[6],
                              studyInstance[7],
                              studyInstance[8],
                              studyInstance[9],
                              studyInstance[10],
                              studyInstance[11],
                              studyInstance[12],
                              studyInstance[5],
                              studyInstance[13]
                              ];
                             
                             //series

                             NSMutableData *seriesData=[NSMutableData data];
                             int seriesResult=task(@"/bin/bash",
                                                    @[@"-s"],
                                                    [[NSString stringWithFormat:destSql[@"manifestWeasisSeriesStudyInstanceUID"],studyInstance[5]]
                                                     dataUsingEncoding:NSUTF8StringEncoding],
                                                    seriesData
                                                    );
                             NSMutableArray *seriesArray=[NSJSONSerialization JSONObjectWithData:seriesData options:0 error:nil];
                             for (NSArray *seriesInstance in seriesArray)
                             {
                                 [weasisManifest appendFormat:
                                  @"<Series SeriesInstanceUID=\"%@\" SeriesDescription=\"%@\" SeriesNumber=\"%@\" Modality=\"%@\"  WadorsURI=\"/studies/%@/series/%@\" NumberOfSeriesRelatedInstances=\"%@\">\r",
                                  seriesInstance[0],
                                  seriesInstance[1],
                                  seriesInstance[2],
                                  seriesInstance[3],
                                  studyInstance[5],
                                  seriesInstance[0],
                                  seriesInstance[4]
                                  ];
                                 //instances
                                 NSMutableData *instanceData=[NSMutableData data];
                                 int instanceResult=task(@"/bin/bash",
                                                       @[@"-s"],
                                                       [[NSString stringWithFormat:destSql[@"manifestWeasisInstanceSeriesInstanceUID"],seriesInstance[0]]
                                                        dataUsingEncoding:NSUTF8StringEncoding],
                                                       instanceData
                                                       );
                                 NSMutableArray *instanceArray=[NSJSONSerialization JSONObjectWithData:instanceData options:0 error:nil];
                                 for (NSArray *instance in instanceArray)
                                 {
                                     [weasisManifest appendFormat:
                                      @"<Instance SOPInstanceUID=\"%@\" InstanceNumber=\"%@\" SOPClassUID=\"%@\"/>\r",
                                      instance[0],
                                      instance[1],
                                      instance[2]
                                      ];
                                 }
                                 [weasisManifest appendString:@"</Series>\r"];
                             }
                             [weasisManifest appendString:@"</Study>\r"];
                         }
                     }
                     [weasisManifest appendString:@"</Patient>\r"];
                 }
                 return [GCDWebServerDataResponse responseWithData:[weasisManifest dataUsingEncoding:NSUTF8StringEncoding] contentType:@"text/xml"];
         }
         ];
        
        
#pragma mark /manifest/weasis/studies/{StudyInstanceUID}/series/{SeriesInstanceUID}
        
        NSRegularExpression *mwseriesregex = [NSRegularExpression regularExpressionWithPattern:@"^/manifest/weasis/studies/[1-2](\\d)*(\\.0|\\.[1-9](\\d)*)*/series/[1-2](\\d)*(\\.0|\\.[1-9](\\d)*)*" options:NSRegularExpressionCaseInsensitive error:NULL];
        [httpdicomServer addHandlerForMethod:@"GET"
                       pathRegularExpression:mwseriesregex
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
             //request parts logging
             NSURL *requestURL=request.URL;
             NSString *bSlash=requestURL.baseURL.absoluteString;
             NSString *b=[bSlash substringToIndex:[bSlash length]-1];
             
             NSString *p=requestURL.path;
             NSArray *pComponents=[p componentsSeparatedByString:@"/"];
             NSString *StudyInstanceUID=pComponents[4];
             NSString *SeriesInstanceUID=pComponents[6];
             
             //NSString *q=requestURL.query;
             NSDictionary *q=request.query;
             NSDictionary *destPacs=pacsArray[q[@"custodianOID"]];
             NSDictionary *destSql=sql[destPacs[@"sql"]];
             if (!destSql) return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [sql not found]",request.path];

             NSString *sqlString=[NSString stringWithFormat:destSql[@"manifestWeasisSeriesStudyInstanceUIDSeriesInstanceUID"],StudyInstanceUID,SeriesInstanceUID];
 
             NSLog(@"%@",sqlString);
            
             //SQL for series
             NSMutableData *seriesData=[NSMutableData data];
             int seriesResult=task(@"/bin/bash",
                                    @[@"-s"],
                                    [sqlString dataUsingEncoding:NSUTF8StringEncoding],
                                    seriesData
                                    );
             NSMutableArray *seriesArray=[NSJSONSerialization JSONObjectWithData:seriesData options:0 error:nil];
             if (![seriesArray count]) return [GCDWebServerErrorResponse responseWithClientError:404 message:@"0 record for %@%@?%@",b,p,q];
             /*
              [0] SeriesInstanceUID,
              [1] SeriesDescription,
              [2] SeriesNumber,
              [3] Modality,
              */
             
             //get corresponding patient and study
             //SQL for studies

             NSMutableData *studiesData=[NSMutableData data];
             int studiesResult=task(@"/bin/bash",
                                    @[@"-s"],
                                    [[NSString stringWithFormat:destSql[@"manifestWeasisStudyStudyInstanceUID"],StudyInstanceUID] dataUsingEncoding:NSUTF8StringEncoding],
                                    studiesData
                                    );
             NSMutableArray *studyArray=[NSJSONSerialization JSONObjectWithData:studiesData options:0 error:nil];
             /*
              [0]  p.family_name,p.given_name,p.middle_name,p.name_prefix,p.name_suffix,
              [1] patient_id.pat_id,
              [2] iopid.entity_uid,
              [3] patient.pat_birthdate,
              [4] patient.pat_sex,
              
              [5] study.study_iuid,
              [6] study.accession_no,
              [7] ioan.entity_uid,
              [8] study_query_attrs.retrieve_aets,
              [9] study.study_id,
              [10] study.study_desc,
              [11] study.study_date,
              [12] study.study_time
              */
             //the accessionNumber may join more than one study of one or more patient !!!
             //look for patient roots first
             NSMutableArray *uniquePatients=[NSMutableArray array];
             for (NSArray *studyInstance in studyArray)
             {
                 [uniquePatients addObject:[studyInstance[1]stringByAppendingPathComponent:studyInstance[2]]];
             }
             
             NSMutableString *weasisManifest=[NSMutableString string];
             //each patient
             for (NSString *patient in [NSSet setWithArray:uniquePatients])
             {
                 NSUInteger studyIndex=[uniquePatients indexOfObject:patient];
                 NSArray *patientAttrs=studyArray[studyIndex];
                 [weasisManifest appendFormat:
                  @"<Patient PatientName=\"%@\" PatientID=\"%@\" IssuerOfPatientID=\"%@\" PatientBirthDate=\"%@\" PatientSex=\"%@\">\r",
                  patientAttrs[0],
                  patientAttrs[1],
                  patientAttrs[2],
                  patientAttrs[3],
                  patientAttrs[4]
                  ];
                 
                 for (NSArray *studyInstance in studyArray)
                 {
                     if (  [studyInstance[1]isEqualToString:patientAttrs[1]]
                         &&[studyInstance[2]isEqualToString:patientAttrs[2]]
                         )
                     {
                         //each study of this patient
                         [weasisManifest appendFormat:
                          @"<Study SpecificCharacterSet=\"UTF-8\" StudyInstanceUID=\"%@\" AccessionNumber=\"%@\" IssuerOfAccessionNumber=\"%@\" RetrieveAETitle=\"%@\" StudyID=\"%@\" StudyDescription=\"%@\" StudyDate=\"%@\" StudyTime=\"%@\" WadorsURI=\"/studies/%@\" NumberOfStudyRelatedInstances=\"%@\">\r",
                          studyInstance[5],
                          studyInstance[6],
                          studyInstance[7],
                          studyInstance[8],
                          studyInstance[9],
                          studyInstance[10],
                          studyInstance[11],
                          studyInstance[12],
                          studyInstance[5],
                          studyInstance[13]
                          ];
                         for (NSArray *seriesInstance in seriesArray)
                         {
                             [weasisManifest appendFormat:
                              @"<Series SeriesInstanceUID=\"%@\" SeriesDescription=\"%@\" SeriesNumber=\"%@\" Modality=\"%@\"  WadorsURI=\"/studies/%@/series/%@\" NumberOfSeriesRelatedInstances=\"%@\">\r",
                              seriesInstance[0],
                              seriesInstance[1],
                              seriesInstance[2],
                              seriesInstance[3],
                              studyInstance[5],
                              seriesInstance[0],
                              seriesInstance[4]
                              ];
                             
                             //instances
                             NSMutableData *instanceData=[NSMutableData data];
                             int instanceResult=task(@"/bin/bash",
                                                     @[@"-s"],
                                                     [[NSString stringWithFormat:destSql[@"manifestWeasisInstanceSeriesInstanceUID"],seriesInstance[0]]
                                                      dataUsingEncoding:NSUTF8StringEncoding],
                                                     instanceData
                                                     );
                             NSMutableArray *instanceArray=[NSJSONSerialization JSONObjectWithData:instanceData options:0 error:nil];
                             for (NSArray *instance in instanceArray)
                             {
                                 [weasisManifest appendFormat:
                                  @"<Instance SOPInstanceUID=\"%@\" InstanceNumber=\"%@\" SOPClassUID=\"%@\"/>\r",
                                  instance[0],
                                  instance[1],
                                  instance[2]
                                  ];
                             }
                             [weasisManifest appendString:@"</Series>\r"];
                         }
                         [weasisManifest appendString:@"</Study>\r"];
                     }
                 }
                 [weasisManifest appendString:@"</Patient>\r"];
             }
             return [GCDWebServerDataResponse responseWithData:[weasisManifest dataUsingEncoding:NSUTF8StringEncoding] contentType:@"application/json"];
         }
         ];
#pragma mark -
#pragma mark datatables/studies
        /*
         query ajax with params:
         agregate 00080090 in other accesible PCS...
         */
        [httpdicomServer addHandlerForMethod:@"GET"
                                        path:@"/datatables/studies"
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
             NSDictionary *q=request.query;
             NSString *session=q[@"session"];
             if (!session || [session isEqualToString:@""]) return [GCDWebServerDataResponse responseWithData:[NSData jsonpCallback:q[@"callback"] forDraw:q[@"draw"] withErrorString:@"query without required 'session' parameter"] contentType:@"application/dicom+json"];
             
             NSDictionary *r=Req[session];
             int recordsTotal;
             
             NSString *qPatientID=q[@"columns[3][search][value]"];
             NSString *qPatientName=q[@"columns[4][search][value]"];
             //NSString *qStudyDate=q[@"columns[5][search][value]"];
             NSString *qDate_start=q[@"date_start"];
             NSString *qDate_end=q[@"date_end"];
             NSString *qModalitiesInStudy=q[@"columns[6][search][value]"];
             NSString *qStudyDescription=q[@"columns[7][search][value]"];
             
             NSString *rPatientID=r[@"columns[3][search][value]"];
             NSString *rPatientName=r[@"columns[4][search][value]"];
             //NSString *rStudyDate=r[@"columns[5][search][value]"];
             NSString *rDate_start=r[@"date_start"];
             NSString *rDate_end=r[@"date_end"];
             NSString *rModalitiesInStudy=r[@"columns[6][search][value]"];
             NSString *rStduyDescription=r[@"columns[7][search][value]"];
             
             
             //same or different context?
             if (
                 !r
                 || [q[@"new"]isEqualToString:@"true"]
                 || (q[@"username"]    && ![q[@"username"]isEqualToString:r[@"username"]])
                 || (q[@"useroid"]     && ![q[@"useroid"]isEqualToString:r[@"useroid"]])
                 || (session           && ![session isEqualToString:r[@"session"]])
                 || (q[@"custodiantitle"]         && ![q[@"custodiantitle"]isEqualToString:r[@"custodiantitle"]])
                 || (q[@"aet"] && ![q[@"aet"]isEqualToString:r[@"aet"]])
                 || (q[@"role"]        && ![q[@"role"]isEqualToString:r[@"role"]])
                 
                 || (q[@"search[value]"] && ![q[@"search[value]"]isEqualToString:r[@"search[value]"]])
                 
                 ||(    qPatientID
                    &&![qPatientID isEqualToString:rPatientID]
                    &&![rPatientID isEqualToString:@""]
                    )
                 ||(    qPatientName
                    &&![qPatientName isEqualToString:rPatientName]
                    &&![rPatientName isEqualToString:@""]
                    )
                 ||(    qDate_start
                    &&![qDate_start isEqualToString:rDate_start]
                    &&![rDate_start isEqualToString:@""]
                    )
                 ||(    qDate_end
                    &&![qDate_end isEqualToString:rDate_end]
                    &&![rDate_end isEqualToString:@""]
                    )
                 ||(    qModalitiesInStudy
                    &&![qModalitiesInStudy isEqualToString:rModalitiesInStudy]
                    &&![rModalitiesInStudy isEqualToString:@""]
                    )
                 ||(    qStudyDescription
                    &&![qStudyDescription isEqualToString:rStduyDescription]
                    &&![rStduyDescription isEqualToString:@""]
                    )
                 )
             {
                 NSLog(@"%@",[[request URL]description]);
#pragma mark --different context
#pragma mark reemplazar org por custodianTitle e institucion por aet
                 //find dest
                 NSUInteger custodianTitleIndex=[custodianTitlesArray indexOfObject:q[@"custodiantitle"]];
                 NSUInteger aetIndex=[[custodianTitlesaets objectForKey:q[@"custodiantitle"]] indexOfObject:q[@"aet"]];
                 NSDictionary *destPacs=pacsArray[(custodianOIDsaeis[custodianOIDsArray[custodianTitleIndex]])[aetIndex]];
                 
                 NSDictionary *destSql=sql[destPacs[@"sql"]];
                 if (!destSql) return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [sql not found]",request.path];
                 
                 //local ... simulation qido through database access
                 
                 NSLog(@"different context with db: %@",destPacs[@"sql"]);
                 
                 if (r){
                     //replace previous request of the session.
                     [Req removeObjectForKey:session];
                     [Total removeObjectForKey:session];
                     [Filtered removeObjectForKey:session];
                     [Date removeObjectForKey:session];
                     if(sPatientID[@"session"])[sPatientID removeObjectForKey:session];
                     if(sPatientName[@"session"])[sPatientName removeObjectForKey:session];
                     //if(sStudyDate[@"session"])[sStudyDate removeObjectForKey:session];
                     if(sDate_start[@"session"])[sDate_start removeObjectForKey:session];
                     if(sDate_end[@"session"])[sDate_end removeObjectForKey:session];
                     if(sModalitiesInStudy[@"session"])[sModalitiesInStudy removeObjectForKey:session];
                     if(sStudyDescription[@"session"])[sStudyDescription removeObjectForKey:session];
                     
                 }
                 [Req setObject:q forKey:session];
                 [Date setObject:[NSDate date] forKey:session];
                 if(qPatientID)[sPatientID setObject:qPatientID forKey:session];
                 if(qPatientName)[sPatientName setObject:qPatientName forKey:session];
                 //if(qStudyDate)[sStudyDate setObject:qStudyDate forKey:session];
                 if(qDate_start)[sDate_start setObject:qDate_start forKey:session];
                 if(qDate_end)[sDate_end setObject:qDate_end forKey:session];
                 if(qModalitiesInStudy)[sModalitiesInStudy setObject:qModalitiesInStudy forKey:session];
                 if(qStudyDescription)[sStudyDescription setObject:qStudyDescription forKey:session];
                 
//1 create where clause
                 
                 //WHERE study.rejection_state!=2    (or  1=1)
                 //following filters use formats like " AND a like 'b'"
                 NSMutableString *studiesWhere=[NSMutableString stringWithString:destSql[@"studiesWhere"]];

                 //PEP por aet or custodian
                 
                 [studiesWhere appendFormat:
                      @" AND %@ in ('%@','%@')",
                      destSql[@"accessControlId"],
                      q[@"aet"],
                      q[@"custodiantitle"]
                  ];
                 
                 if (q[@"search[value]"] && ![q[@"search[value]"] isEqualToString:@""])
                 {
                     //AccessionNumber q[@"search[value]"]
                     [studiesWhere appendString:
                      [NSString mysqlEscapedFormat:@" AND %@ like '%@'"
                                       fieldString:destSql[@"AccessionNumber"]
                                       valueString:q[@"search[value]"]
                       ]
                      ];
                 }
                 else
                 {
                     if(qPatientID && [qPatientID length])
                     {
                         [studiesWhere appendString:
                          [NSString mysqlEscapedFormat:@" AND %@ like '%@%%'"
                                           fieldString:destSql[@"PatientID"]
                                           valueString:qPatientID
                           ]
                          ];
                     }
                     
                     if(qPatientName && [qPatientName length])
                     {
                         //PatientName _00100010 Nombre
                         NSArray *patientNameComponents=[qPatientName componentsSeparatedByString:@"^"];
                         NSUInteger patientNameCount=[patientNameComponents count];
                         
                         [studiesWhere appendString:
                          [NSString mysqlEscapedFormat:@" AND %@ like '%@%%'"
                                           fieldString:(destSql[@"PatientName"])[0]
                                           valueString:patientNameComponents[0]
                           ]
                          ];
                         
                         if (patientNameCount > 1)
                         {
                             [studiesWhere appendString:
                              [NSString mysqlEscapedFormat:@" AND %@ like '%@%%'"
                                               fieldString:(destSql[@"PatientName"])[1]
                                               valueString:patientNameComponents[1]
                               ]
                              ];
                             
                             if (patientNameCount > 2)
                             {
                                 [studiesWhere appendString:
                                  [NSString mysqlEscapedFormat:@" AND %@ like '%@%%'"
                                                   fieldString:(destSql[@"PatientName"])[2]
                                                   valueString:patientNameComponents[2]
                                   ]
                                  ];
                                 
                                 if (patientNameCount > 3)
                                 {
                                     [studiesWhere appendString:
                                      [NSString mysqlEscapedFormat:@" AND %@ like '%@%%'"
                                                       fieldString:(destSql[@"PatientName"])[3]
                                                       valueString:patientNameComponents[3]
                                       ]
                                      ];
                                     
                                     if (patientNameCount > 4)
                                     {
                                         [studiesWhere appendString:
                                          [NSString mysqlEscapedFormat:@" AND %@ like '%@%%'"
                                                           fieldString:(destSql[@"PatientName"])[4]
                                                           valueString:patientNameComponents[4]
                                           ]
                                          ];
                                     }
                                 }
                             }
                         }
                     }
                     
                     if(
                        (qDate_start && [qDate_start length])
                        ||(qDate_end && [qDate_end length])
                        )
                     {
                         //StudyDate _00080020 aaaammdd,-aaaammdd,aaaammdd-,aaaammdd-aaaammdd
                         
                         if ([qDate_start isEqualToString:qDate_end])
                         {
                             //no hyphen
                             [studiesWhere appendFormat:@" AND %@ = '%@'", destSql[@"StudyDate"], qDate_start];
                         }
                         else if (!qDate_start || [qDate_start isEqualToString:@""])
                         {
                             //until
                             [studiesWhere appendFormat:@" AND %@ <= '%@'", destSql[@"StudyDate"], qDate_end];
                         }
                         else if (!qDate_end || [qDate_end isEqualToString:@""])
                         {
                             //since
                             [studiesWhere appendFormat:@" AND %@ <= '%@'", destSql[@"StudyDate"], qDate_start];
                         }
                         else
                         {
                             //inbetween
                             [studiesWhere appendFormat:@" AND %@ >= '%@'", destSql[@"StudyDate"], qDate_start];
                             [studiesWhere appendFormat:@" AND %@ <= '%@'", destSql[@"StudyDate"], qDate_end];
                         }
                     }
                     
                     if(qModalitiesInStudy && [qModalitiesInStudy length] && ![qModalitiesInStudy isEqualToString:@"*"])
                     {
                         //ModalitiesInStudy _00080061 Modalidades (coma separated)
                         [studiesWhere appendFormat:@" AND %@ like '%%%@%%'", destSql[@"ModalitiesInStudy"], qModalitiesInStudy];
                     }
                     
                     if(qStudyDescription && [qStudyDescription length])
                     {
                         //StudyDescription _00081030 Descripción
                         [studiesWhere appendString:
                          [NSString mysqlEscapedFormat:@" AND %@ like '%@%%'"
                                           fieldString:destSql[@"StudyDescription"]
                                           valueString:qStudyDescription
                           ]
                          ];
                     }
                 }
                 GWS_LOG_INFO(@"%@",studiesWhere);


//2 count
                 NSString *sqlCountQuery=
                 [[destSql[@"studiesCountProlog"]
                   stringByAppendingString:studiesWhere]
                  stringByAppendingString:destSql[@"studiesCountEpilog"]];
                 GWS_LOG_DEBUG(@"%@",sqlCountQuery);
                 NSMutableData *countData=[NSMutableData data];
                 if (task(@"/bin/bash",@[@"-s"],[sqlCountQuery dataUsingEncoding:NSUTF8StringEncoding],countData))
                     [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"%@",@"can not access the db"];
                 NSString *countString=[[NSString alloc]initWithData:countData encoding:NSUTF8StringEncoding];
                 // max (max records filtered para evitar que filtros insuficientes devuelvan casi todos los registros... lo que devolvería un resultado inútil.
                 recordsTotal=[countString intValue];
                 int maxCount=[q[@"max"]intValue];
                 NSLog(@"total:%d, max:%d",recordsTotal,maxCount);
                 if (recordsTotal > maxCount) return [GCDWebServerDataResponse responseWithData:[NSData jsonpCallback:q[@"callback"] forDraw:q[@"draw"] withErrorString:[NSString stringWithFormat:@"you need a narrower filter. The browser table accepts up to %d matches. %d matches were found",maxCount, recordsTotal]] contentType:@"application/dicom+json"];

                 if (!recordsTotal) return [GCDWebServerDataResponse
                                            responseWithData:[NSData jsonpCallback:q[@"callback"]withDictionary:@{
                                                      @"draw":q[@"draw"],
                                                      @"recordsTotal":@0,
                                                      @"recordsFiltered":@0,
                                                      @"data":@[]
                                                      }]
                                     contentType:@"application/dicom+json"
                                     ];
                 else
                 {
                     //order is performed later, from mutableDictionary
//3 select
                     NSString *sqlDataQuery=
                     [[destSql[@"datatablesStudiesProlog"]
                       stringByAppendingString:studiesWhere]
                      stringByAppendingFormat:destSql[@"datatablesStudiesEpilog"],session,session];
                     
                     NSMutableArray *studiesArray=jsonMutableArray(sqlDataQuery, [destSql[@"stringEncoding"]unsignedIntegerValue]);

                     [Total setObject:studiesArray forKey:session];
                     [Filtered setObject:[studiesArray mutableCopy] forKey:session];
                 }
                 
             }//end diferent context
             else
             {
                 
#pragma mark --same context
                 
                 recordsTotal=[Total[session] count];
                 NSLog(@"same context recordsTotal: %d ",recordsTotal);
                 
                 //subfilter?
                 // in case there is subfilter, derive BFiltered from BTotal
                 //https://developer.apple.com/reference/foundation/nsmutablearray/1412085-filterusingpredicate?language=objc
                 
                 if (recordsTotal > 0)
                 {
                     BOOL toBeFiltered=false;
                     
                     NSRegularExpression *PatientIDRegex=nil;
                     if(qPatientID && ![qPatientID isEqualToString:sPatientID[session]])
                     {
                         toBeFiltered=true;
                         PatientIDRegex=[NSRegularExpression regularExpressionWithPattern:[NSString regexDicomString:qPatientID withFormat:@"datatables\\/patient\\?PatientID=%@.*"] options:0 error:NULL];
                     }
                     
                     NSRegularExpression *PatientNameRegex=nil;
                     if(qPatientName && ![qPatientName isEqualToString:sPatientName[session]])
                     {
                         toBeFiltered=true;
                         PatientNameRegex=[NSRegularExpression regularExpressionWithPattern:[NSString regexDicomString:qPatientName withFormat:@"%@.*"] options:NSRegularExpressionCaseInsensitive error:NULL];
                     }
                     
                     NSString *until;
                     if(   qDate_end
                        && (  !sDate_end[session]
                            || ([qDate_end compare:sDate_end[session]]==NSOrderedAscending)
                            )
                        )
                     {
                         toBeFiltered=true;
                         until=qDate_end;
                     }
                     
                     NSString *since;
                     if(   qDate_start
                        && (  !sDate_start[session]
                            || ([qDate_start compare:sDate_start[session]]==NSOrderedDescending)
                            )
                        )
                     {
                         toBeFiltered=true;
                         since=qDate_start;
                     }
                     
                     NSString *newModalitiesInStudy=nil;
                     if(qModalitiesInStudy && ![qModalitiesInStudy isEqualToString:sModalitiesInStudy[session]])
                     {
                         toBeFiltered=true;
                         newModalitiesInStudy=qModalitiesInStudy;
                     }
                     
                     
                     NSRegularExpression *StudyDescriptionRegex=nil;
                     if(qStudyDescription  && ![qStudyDescription isEqualToString:sStudyDescription[session]])
                     {
                         toBeFiltered=true;
                         StudyDescriptionRegex=[NSRegularExpression regularExpressionWithPattern:[NSString regexDicomString:qStudyDescription withFormat:@"%@.*"] options:NSRegularExpressionCaseInsensitive error:NULL];
                     }
                     
                     if(toBeFiltered)
                     {
                         //filter from BTotal copy
                         [Filtered removeObjectForKey:session];
                         [Filtered setObject:[Total[session] mutableCopy] forKey:session];
                         
                         //create compound predicate
                         NSPredicate *compoundPredicate = [NSPredicate predicateWithBlock:^BOOL(NSArray *BRow, NSDictionary *bindings) {
                             if (PatientIDRegex)
                             {
                                 //NSLog(@"patientID filter");
                                 if (![PatientIDRegex numberOfMatchesInString:BRow[3] options:0 range:NSMakeRange(0,[BRow[3] length])]) return false;
                             }
                             if (PatientNameRegex)
                             {
                                 //NSLog(@"patientName filter");
                                 if (![PatientNameRegex numberOfMatchesInString:BRow[4] options:0 range:NSMakeRange(0,[BRow[4] length])]) return false;
                             }
                             if (until)
                             {
                                 //NSLog(@"until filter");
                                 if ([until compare:BRow[5]]==NSOrderedDescending) return false;
                             }
                             if (since)
                             {
                                 //NSLog(@"since filter");
                                 if ([since compare:BRow[5]]==NSOrderedAscending) return false;
                             }
                             if (newModalitiesInStudy)
                             {
                                 //NSLog(@"modalities filter");
                                 if (![BRow[6] containsString:newModalitiesInStudy]) return false;
                             }
                             if (StudyDescriptionRegex)
                             {
                                 //NSLog(@"description filter");
                                 if (![StudyDescriptionRegex numberOfMatchesInString:BRow[7] options:0 range:NSMakeRange(0,[BRow[7] length])]) return false;
                             }
                             return true;
                         }];
                         
                         [Filtered[session] filterUsingPredicate:compoundPredicate];
                     }
                 }
             }
#pragma mark --order
             if (q[@"order[0][column]"] && q[@"order[0][dir]"])
             {
                 NSLog(@"ordering with %@, %@",q[@"order[0][column]"],q[@"order[0][dir]"]);
                 
                 int column=[q[@"order[0][column]"]intValue];
                 if ([q[@"order[0][dir]"]isEqualToString:@"desc"])
                 {
                     [Filtered[session] sortWithOptions:0 usingComparator:^NSComparisonResult(id obj1, id obj2) {
                         return [obj2[column] caseInsensitiveCompare:obj1[column]];
                     }];
                 }
                 else
                 {
                     [Filtered[session] sortWithOptions:0 usingComparator:^NSComparisonResult(id obj1, id obj2) {
                         return [obj1[column] caseInsensitiveCompare:obj2[column]];
                     }];
                 }
             }
             
#pragma mark --response
             
             NSMutableDictionary *resp = [NSMutableDictionary dictionary];
             NSUInteger recordsFiltered=[Filtered[session]count];
             [resp setObject:q[@"draw"] forKey:@"draw"];
             [resp setObject:[NSNumber numberWithInt:recordsTotal] forKey:@"recordsTotal"];
             [resp setObject:[NSNumber numberWithUnsignedInteger:recordsFiltered] forKey:@"recordsFiltered"];
             
             if (!recordsFiltered)  return [GCDWebServerDataResponse
                                            responseWithData:[NSData jsonpCallback:q[@"callback"]withDictionary:@{@"draw":q[@"draw"],@"recordsTotal":@0,@"recordsFiltered":@0,@"data":@[]}]
                                            contentType:@"application/dicom+json"
                                            ];
             else
             {
                 //start y length
                 long ps=[q[@"start"]intValue];
                 long pl=[q[@"length"]intValue];
                 NSLog(@"paging desired (start=[%ld],filas=[%ld],last=[%lu])",ps,pl,recordsFiltered-1);
                 if (ps < 0) ps=0;
                 if (ps > recordsFiltered-1) ps=0;
                 if (ps+pl+1 > recordsFiltered) pl=recordsFiltered-ps;
                 NSLog(@"paging applied (start=[%ld],filas=[%ld],last=[%lu])",ps,pl,recordsFiltered-1);
                 NSArray *page=[Filtered[session] subarrayWithRange:NSMakeRange(ps,pl)];
                 if (!page)page=@[];
                 [resp setObject:page forKey:@"data"];
             }
             
             return [GCDWebServerDataResponse
                     responseWithData:[NSData jsonpCallback:q[@"callback"]withDictionary:resp]
                     contentType:@"application/dicom+json"
                     ];
         }];
        
#pragma mark datatables/patient
        /*
         ventana emergente con todos los estudios del paciente
         "datatables/patient?PatientID=33333333&IssuerOfPatientID.UniversalEntityID=NULL&session=1"
         */
        
        [httpdicomServer addHandlerForMethod:@"GET"
                                        path:@"/datatables/patient"
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
             NSDictionary *q=request.query;
             NSLog(@"%@",[q description]);
             
             NSString *session=q[@"session"];
             if (!session || [session isEqualToString:@""]) return [GCDWebServerDataResponse responseWithData:[NSData jsonpCallback:q[@"callback"] forDraw:q[@"draw"] withErrorString:@"query without required 'session' parameter"] contentType:@"application/dicom+json"];
             
             if (!q[@"PatientID"]) return [GCDWebServerDataResponse responseWithData:[NSData jsonpCallback:q[@"callback"] forDraw:q[@"draw"] withErrorString:@"studies of patient query without required 'patientID' parameter"] contentType:@"application/dicom+json"];
             
             //WHERE study.rejection_state!=2    (or  1=1)
             //following filters use formats like " AND a like 'b'"
             
             //find dest
             NSUInteger custodianTitleIndex=[custodianTitlesArray indexOfObject:q[@"custodiantitle"]];
             NSUInteger aetIndex=[[custodianTitlesaets objectForKey:q[@"custodiantitle"]] indexOfObject:q[@"aet"]];
             NSDictionary *destPacs=pacsArray[(custodianOIDsaeis[custodianOIDsArray[custodianTitleIndex]])[aetIndex]];
             
             NSDictionary *destSql=sql[destPacs[@"sql"]];
             if (!destSql) return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [sql not found]",request.path];
             
             NSMutableString *studiesWhere=[NSMutableString stringWithString:destSql[@"studiesWhere"]];
             [studiesWhere appendString:
              [NSString mysqlEscapedFormat:@" AND %@ like '%@'"
                               fieldString:destSql[@"PatientID"]
                               valueString:q[@"PatientID"]
               ]
              ];
             //PEP por custodian aets
             [studiesWhere appendFormat:
              @" AND %@ in ('%@')",
              destSql[@"accessControlId"],
              [custodianTitlesaets[q[@"custodiantitle"]] componentsJoinedByString:@"','"]
              ];

             NSLog(@"SQL: %@",studiesWhere);
             

             
             NSString *sqlDataQuery=
             [[destSql[@"datatablesStudiesProlog"]
               stringByAppendingString:studiesWhere]
              stringByAppendingFormat:destSql[@"datatablesStudiesEpilog"],session,session];
             
             NSMutableArray *studiesArray=jsonMutableArray(sqlDataQuery, [destSql[@"stringEncoding"]unsignedIntegerValue]);
             
             //sorted study date (5) desc
             [studiesArray sortWithOptions:0 usingComparator:^NSComparisonResult(id obj1, id obj2) {
                 return [obj2[5] caseInsensitiveCompare:obj1[5]];
             }];
             
             
             NSMutableDictionary *resp = [NSMutableDictionary dictionary];
             if (q[@"draw"])[resp setObject:q[@"draw"] forKey:@"draw"];
             NSNumber *count=[NSNumber numberWithUnsignedInteger:[studiesArray count]];
             [resp setObject:count forKey:@"recordsTotal"];
             [resp setObject:count forKey:@"recordsFiltered"];
             [resp setObject:studiesArray forKey:@"data"];
             return [GCDWebServerDataResponse
                     responseWithData:[NSData jsonpCallback:q[@"callback"]withDictionary:resp]
                     contentType:@"application/dicom+json"
                     ];
         }
         ];
        
        
#pragma mark datatables/series
        //"datatables/series?AccessionNumber=22&IssuerOfAccessionNumber.UniversalEntityID=NULL&StudyIUID=2.16.858.2.10000675.72769.20160411084701.1.100&session=1"
        [httpdicomServer addHandlerForMethod:@"GET"
                                        path:@"/datatables/series"
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
             NSDictionary *q=request.query;
             NSString *session=q[@"session"];
             if (!session || [session isEqualToString:@""]) return [GCDWebServerDataResponse responseWithData:[NSData jsonpCallback:q[@"callback"] forDraw:q[@"draw"] withErrorString:@"query without required 'session' parameter"] contentType:@"application/dicom+json"];
             
             
             //find dest
             NSUInteger custodianTitleIndex=[custodianTitlesArray indexOfObject:q[@"custodiantitle"]];
             NSUInteger aetIndex=[[custodianTitlesaets objectForKey:q[@"custodiantitle"]] indexOfObject:q[@"aet"]];
             NSDictionary *destPacs=pacsArray[(custodianOIDsaeis[custodianOIDsArray[custodianTitleIndex]])[aetIndex]];
             
             NSDictionary *destSql=sql[destPacs[@"sql"]];
             if (!destSql) return [GCDWebServerErrorResponse responseWithClientError:404 message:@"%@ [sql not found]",request.path];
             
             NSString *where;
             NSString *AccessionNumber=q[@"AccessionNumber"];
             NSString *StudyInstanceUID=q[@"StudyInstanceUID"];
             if (AccessionNumber && ![AccessionNumber isEqualToString:@"NULL"])
             {
                 NSString *IssuerOfAccessionNumber=q[@"IssuerOfAccessionNumber.UniversalEntityID"];
                 if (IssuerOfAccessionNumber && ![IssuerOfAccessionNumber isEqualToString:@"NULL"]) where=[NSString stringWithFormat:@"%@ AND %@='%@' AND %@='%@'", destSql[@"seriesWhere"],destSql[@"AccessionNumber"],AccessionNumber,destSql[@"IssuerOfAccessionNumber"],IssuerOfAccessionNumber];
                 else where=[NSString stringWithFormat:@"%@ AND %@='%@'",destSql[@"seriesWhere"],destSql[@"AccessionNumber"],AccessionNumber];
                 
             }
             else if (StudyInstanceUID && ![StudyInstanceUID isEqualToString:@"NULL"]) where=[NSString stringWithFormat:@"%@ AND %@='%@'",destSql[@"seriesWhere"],destSql[@"StudyInstanceUID"],@"StudyInstanceUID"];
             else return [GCDWebServerDataResponse responseWithData:[NSData jsonpCallback:q[@"callback"] forDraw:q[@"draw"] withErrorString:@"query without required 'AccessionNumber' or 'StudyInstanceUID' parameter"] contentType:@"application/dicom+json"];
             
             
             NSLog(@"SQL: %@",where);
             
             NSString *sqlDataQuery=
             [[destSql[@"datatablesSeriesProlog"]
               stringByAppendingString:where]
              stringByAppendingFormat:destSql[@"datatablesSeriesEpilog"],session,session];
             
             NSMutableArray *seriesArray=jsonMutableArray(sqlDataQuery, [destSql[@"stringEncoding"]unsignedIntegerValue]);
             NSLog(@"series array:%@",[seriesArray description]);
             
             NSMutableDictionary *resp = [NSMutableDictionary dictionary];
             if (q[@"draw"])[resp setObject:q[@"draw"] forKey:@"draw"];
             NSNumber *count=[NSNumber numberWithUnsignedInteger:[seriesArray count]];
             [resp setObject:count forKey:@"recordsTotal"];
             [resp setObject:count forKey:@"recordsFiltered"];
             [resp setObject:seriesArray forKey:@"data"];
             return [GCDWebServerDataResponse
                     responseWithData:[NSData jsonpCallback:q[@"callback"]withDictionary:resp]
                     contentType:@"application/dicom+json"
                     ];
         }
         ];

        
#pragma mark IHEInvokeImageDisplay
        // IHEInvokeImageDisplay?requestType=STUDY&accessionNumber=1&viewerType=IHE_BIR&diagnosticQuality=true&keyImagesOnly=false&custodianOID=xxx&proxyURI=yyy
        
        [httpdicomServer addHandlerForMethod:@"GET"
                                        path:@"/IHEInvokeImageDisplay"
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
             NSDictionary *q=request.query;
             
             //(1) b= html5dicomURL
             NSURL *requestURL=request.URL;
             NSString *bSlash=requestURL.baseURL.absoluteString;
             NSString *b=[bSlash substringToIndex:[bSlash length]-1];
             NSString *p=requestURL.path;
             GWS_LOG_INFO(@"%@%@?%@",b,p,requestURL.query);
             
             
             //(2) accept requestType STUDY / SERIES only
             NSString *requestType=q[@"requestType"];
             if (
                 !requestType
                 ||!
                 (  [requestType isEqualToString:@"STUDY"]
                  ||[requestType isEqualToString:@"SERIES"]
                  )
                 ) return [GCDWebServerDataResponse responseWithText:[NSString stringWithFormat:@"missing requestType param in %@%@?%@",b,p,requestURL.query]];
             
             //session
             if (!q[@"session"]) return [GCDWebServerDataResponse responseWithText:[NSString stringWithFormat:@"missing session param in %@%@?%@",b,p,requestURL.query]];
             
             
             //custodianURI
             
             if (!q[@"custodianOID"]) return [GCDWebServerDataResponse responseWithText:[NSString stringWithFormat:@"missing custodianOID param in %@%@?%@",b,p,requestURL.query]];
             NSString *custodianURI;
             if ((pacsArray[q[@"custodianOID"]])[@"islocalhosted"])custodianURI=[NSString stringWithFormat:@"http://localhost:%lld",port];
             else custodianURI=(pacsArray[q[@"custodianOID"]])[@"publicuri"];
             if (!@"custodianURI") return [GCDWebServerDataResponse responseWithText:[NSString stringWithFormat:@"invalid custodianOID param in %@%@?%@",b,p,requestURL.query]];
             
             
             //proxyURI
             NSString *proxyURI=q[@"proxyURI"];
             if (!proxyURI) proxyURI=b;
             
             //redirect to specific manifest
             NSMutableString *manifest=[NSMutableString string];
             
             NSString *viewerType=q[@"viewerType"];
             if (  !viewerType
                 || [viewerType isEqualToString:@"IHE_BIR"]
                 || [viewerType isEqualToString:@"weasis"]
                 )
             {
                 [manifest appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\r"];
                 NSString *additionalParameters=(pacsArray[q[@"custodianOID"]])[@"wadoadditionalparameters"];
                 if (!additionalParameters)additionalParameters=@"";
                 [manifest appendFormat:@"<wado_query xmlns=\"http://www.weasis.org/xsd\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" wadoURL=\"%@\" requireOnlySOPInstanceUID=\"false\" additionnalParameters=\"%@&amp;session=%@&amp;custodianOID=%@\" overrideDicomTagsList=\"\">",
                  proxyURI,
                  additionalParameters,
                  q[@"session"],
                  q[@"custodianOID"]
                  ];
                 
                 NSString *manifestWeasisURI;
                 if ([requestType isEqualToString:@"STUDY"])
                 {
                     if (q[@"accessionNumber"]) manifestWeasisURI=[NSString stringWithFormat:@"%@/manifest/weasis/studies?AccessionNumber=%@&custodianOID=%@",custodianURI,q[@"accessionNumber"],q[@"custodianOID"]];
                     else if (q[@"studyUID"]) manifestWeasisURI=[NSString stringWithFormat:@"%@/manifest/weasis/studies?StudyInstanceUID=%@&custodianOID=%@",custodianURI,q[@"studyUID"],q[@"custodianOID"]];
                     else return [GCDWebServerDataResponse responseWithText:[NSString stringWithFormat:@"requestType=STUDY requires param accessionNumber or studyUID in %@%@?%@",b,p,requestURL.query]];
                 }
                 else
                 {
                     //SERIES
                     if (q[@"studyUID"] && q[@"seriesUID"]) manifestWeasisURI=[NSString stringWithFormat:@"%@/manifest/weasis/studies/%@/series/%@?custodianOID=%@",custodianURI,q[@"studyUID"],q[@"seriesUID"],q[@"custodianOID"]];
                     else return [GCDWebServerDataResponse responseWithText:[NSString stringWithFormat:@"requestType=SERIES requires params studyUID and seriesUID in %@%@?%@",b,p,requestURL.query]];
                 }
                 NSLog(@"%@",manifestWeasisURI);
                 [manifest appendFormat:@"%@\r</wado_query>\r",[NSString stringWithContentsOfURL:[NSURL URLWithString:manifestWeasisURI] encoding:NSUTF8StringEncoding error:nil]];
                 GWS_LOG_INFO(@"%@",manifest);
                 
                 if ([manifest length]<350) [GCDWebServerDataResponse responseWithText:[NSString stringWithFormat:@"zero objects for %@%@?%@",b,p,requestURL.query]];
                 
                 
                 if (![custodianURI isEqualToString:@"http://localhost"])
                 {
                     //get series not available in dev0
                     
                     NSXMLDocument *xmlDocument=[[NSXMLDocument alloc]initWithXMLString:manifest options:0 error:nil];
                     NSArray *seriesWadorsArray = [xmlDocument nodesForXPath:@"wado_query/Patient/Study/Series" error:nil];
                     for (NSXMLNode *node in seriesWadorsArray)
                     {
                         NSString *seriesWadors=[node stringValue];// /studies/{studies}/series/{series}
                         
                         //cantidad de instancias en la serie en dev0?
                         
                     }
                 }
                 GCDWebServerDataResponse *response=[GCDWebServerDataResponse responseWithData:[[[LFCGzipUtility gzipData:[manifest dataUsingEncoding:NSUTF8StringEncoding]] base64EncodedStringWithOptions:0]dataUsingEncoding:NSUTF8StringEncoding] contentType:@"application/x-gzip"];
                 [response setValue:@"Base64" forAdditionalHeader:@"Content-Transfer-Encoding"];//https://tools.ietf.org/html/rfc2045
                 
                 return response;
             }
             else if ([viewerType isEqualToString:@"cornerstone"])
             {
                 //cornerstone
                 NSMutableDictionary *cornerstone=[NSMutableDictionary dictionary];
                 
                 //qido uri
                 NSString *qidoSeriesString;
                 if ([requestType isEqualToString:@"STUDY"])
                 {
                     if (q[@"accessionNumber"]) qidoSeriesString=[NSString stringWithFormat:@"%@/series?AccessionNumber=%@",(pacsArray[q[@"custodianOID"]])[@"qido"],q[@"accessionNumber"]];
                     else if (q[@"studyUID"]) qidoSeriesString=[NSString stringWithFormat:@"%@/series?StudyInstanceUID=%@",(pacsArray[q[@"custodianOID"]])[@"qido"],q[@"studyUID"]];
                     else return [GCDWebServerDataResponse responseWithText:[NSString stringWithFormat:@"requestType=STUDY requires param accessionNumber or studyUID in %@%@?%@",b,p,requestURL.query]];
                 }
                 else
                 {
                     //SERIES
                     if (q[@"studyUID"] && q[@"seriesUID"]) qidoSeriesString=[NSString stringWithFormat:@"%@/series?StudyInstanceUID=%@&SeriesInstanceUID=%@",(pacsArray[q[@"custodianOID"]])[@"qido"],q[@"studyUID"],q[@"seriesUID"]];
                     else return [GCDWebServerDataResponse responseWithText:[NSString stringWithFormat:@"requestType=SERIES requires params studyUID and seriesUID in %@%@?%@",b,p,requestURL.query]];
                 }
                 NSLog(@"%@",qidoSeriesString);
                 
                 NSMutableArray *seriesArray=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:qidoSeriesString]] options:NSJSONReadingMutableContainers error:nil];
                 
                 [cornerstone setObject:((((seriesArray[0])[@"00100010"])[@"Value"])[0])[@"Alphabetic"] forKey:@"patientName"];
                 [cornerstone setObject:(((seriesArray[0])[@"00100020"])[@"Value"])[0] forKey:@"patientId"];
                 NSString *s=(((seriesArray[0])[@"00080020"])[@"Value"])[0];
                 NSString *StudyDate=[NSString stringWithFormat:@"%@-%@-%@",
                                      [s substringWithRange:NSMakeRange(0,4)],
                                      [s substringWithRange:NSMakeRange(4,2)],
                                      [s substringWithRange:NSMakeRange(6,2)]];
                 [cornerstone setObject:StudyDate forKey:@"studyDate"];
                 [cornerstone setObject:(((seriesArray[0])[@"00080061"])[@"Value"])[0] forKey:@"modality"];
                 NSString *studyDescription=(((seriesArray[0])[@"00081030"])[@"Value"])[0];
                 if (!studyDescription) studyDescription=@"";
                 [cornerstone setObject:studyDescription forKey:@"studyDescription"];//
                 [cornerstone setObject:@999 forKey:@"numImages"];
                 [cornerstone setObject:(((seriesArray[0])[@"00200010"])[@"Value"])[0] forKey:@"studyId"];
                 NSMutableArray *seriesList=[NSMutableArray array];
                 [cornerstone setObject:seriesList forKey:@"seriesList"];
                 for (NSDictionary *seriesQido in seriesArray)
                 {
                     if (
                         !([((seriesQido[@"00080060"])[@"Value"])[0] isEqualToString:@"OT"])
                         &&!([((seriesQido[@"00080060"])[@"Value"])[0] isEqualToString:@"DOC"]))
                     {
                         //cornerstone no muestra los documentos encapsulados
                         NSMutableDictionary *seriesCornerstone=[NSMutableDictionary dictionary];
                         [seriesList addObject:seriesCornerstone];
                         [seriesCornerstone setObject:((seriesQido[@"0008103E"])[@"Value"])[0] forKey:@"seriesDescription"];
                         [seriesCornerstone setObject:((seriesQido[@"00200011"])[@"Value"])[0] forKey:@"seriesNumber"];
                         NSMutableArray *instanceList=[NSMutableArray array];
                         [seriesCornerstone setObject:instanceList forKey:@"instanceList"];
                         //get instances for the series
                         
                         NSString *qidoInstancesString=
                         [NSString stringWithFormat:@"%@/instances?StudyInstanceUID=%@&SeriesInstanceUID=%@",
                          (pacsArray[q[@"custodianOID"]])[@"qido"],
                          q[@"studyUID"],
                          ((seriesQido[@"0020000E"])[@"Value"])[0]
                          ];
                         NSLog(@"%@",qidoInstancesString);
                         NSMutableArray *instancesArray=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:qidoInstancesString]] options:NSJSONReadingMutableContainers error:nil];
                         
                         //classify instancesArray by instanceNumber
                         
                         [instancesArray sortWithOptions:0 usingComparator:^NSComparisonResult(id obj1, id obj2) {
                             if ([((obj1[@"00200013"])[@"Value"])[0]intValue]<[((obj2[@"00200013"])[@"Value"])[0]intValue])
                                 return NSOrderedAscending;
                             return NSOrderedDescending;
                         }];
                         
                         
                         
                         for (NSDictionary *instance in instancesArray)
                         {
                             NSString *wadouriInstance=[NSString stringWithFormat:@"%@?requestType=WADO&studyUID=%@&seriesUID=%@&objectUID=%@&session=%@&custodianOID=%@",proxyURI,
                                                        q[@"studyUID"],
                                                        ((seriesQido[@"0020000E"])[@"Value"])[0],
                                                        ((instance[@"00080018"])[@"Value"])[0],
                                                        q[@"session"],
                                                        q[@"custodianOID"]
                                                        ];
                             [instanceList addObject:@{
                                                       @"imageId":wadouriInstance
                                                       }];
                         }
                     }
                 }
                 NSLog(@"%@",[cornerstone description]);
                 return [GCDWebServerDataResponse responseWithData:[NSJSONSerialization dataWithJSONObject:cornerstone options:0 error:nil] contentType:@"application/json"];
             }
             else if ([viewerType isEqualToString:@"MHD-I"])
             {
                 //MHD-I
                 if ([requestType isEqualToString:@"STUDY"])
                 {
                     NSString *accessionNumber=q[@"accessionNumber"];
                     NSString *studyUID=q[@"studyUID"];
                     if (accessionNumber)
                     {
                         
                     }
                     else if (studyUID)
                     {
                         
                     }
                     else return [GCDWebServerDataResponse responseWithText:[NSString stringWithFormat:@"requestType=STUDY requires param accessionNumber or studyUID in %@%@?%@",b,p,requestURL.query]];
                     
                 }
                 else
                 {
                     //SERIES
                 }
             }
             return [GCDWebServerDataResponse responseWithText:[NSString stringWithFormat:@"unknown viewerType in %@%@?%@",b,p,requestURL.query]];
         }
         ];
        

#pragma mark run
        [httpdicomServer runWithPort:port bonjourName:nil];
        while (true) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, true);
        }
        [httpdicomServer stop];
        
    }//end autorelease pool
    return success ? 0 : -1;
}
