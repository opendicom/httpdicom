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

#import <Cocoa/Cocoa.h>


#import "GCDWebServerResponse.h"
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerPrivate.h"
#import "LFCGzipUtility.h"
#import "ZZArchiveEntry.h"
#import "ZZArchive.h"
#import "ZZConstants.h"
#import "ZZChannel.h"
#import "ZZError.h"

static NSData *rn;
static NSData *rnhh;
static NSData *rnrn;
static NSData *contentType;

static BOOL _run;

static void _SignalHandler(int signal) {
    _run = NO;
    printf("\n");
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
    //[task waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
    //[aTask interrupt];
    
    [task waitUntilExit];
    int terminationStatus = [task terminationStatus];
    if (terminationStatus!=0) NSLog(@"ERROR task terminationStatus: %d",terminationStatus);
    return terminationStatus;
}

int main(int argc, const char* argv[]) {
    BOOL success = NO;

    /*
     syntax: httpdicom
     
     [1] path to oids.plist
     [2] dicomweb (OID del dcm4chee-arc-light del PCS)
     [3] dicom1
     [4] lan...
     */
    
    @autoreleasepool {
        NSFileManager *fileManager=[NSFileManager defaultManager];

        NSDateFormatter *dicomDTFormatter = [[NSDateFormatter alloc] init];
        [dicomDTFormatter setDateFormat:@"yyyyMMddHHmmss"];

        rn = [@"\r\n" dataUsingEncoding:NSASCIIStringEncoding];
        rnrn = [@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
        rnhh = [@"\r\n--" dataUsingEncoding:NSASCIIStringEncoding];
        contentType=[@"Content-Type: " dataUsingEncoding:NSASCIIStringEncoding];
        
        //regex for url validation
        NSRegularExpression *UIRegex = [NSRegularExpression regularExpressionWithPattern:@"^[1-2](\\d)*(\\.0|\\.[1-9](\\d)*)*$" options:0 error:NULL];
        NSRegularExpression *SHRegex = [NSRegularExpression regularExpressionWithPattern:@"^(?:\\s*)([^\\r\\n\\f\\t]*[^\\r\\n\\f\\t\\s])(?:\\s*)$" options:0 error:NULL];

        NSMutableArray *args=[NSMutableArray arrayWithArray:[[NSProcessInfo processInfo] arguments]];
        //oids
        NSDictionary *oids=[NSDictionary dictionaryWithContentsOfFile:[args[1]stringByExpandingTildeInPath]];
        NSMutableSet *orgis=[NSMutableSet set];
        NSMutableSet *orgts=[NSMutableSet set];
        for (NSDictionary *d in [oids allValues])
        {
            [orgis addObject:[d objectForKey:@"pcsi"]];
            [orgts addObject:[d objectForKey:@"pcst"]];
        }
        NSArray *orgisArray=[orgis allObjects];
        NSData *orgisData = [NSJSONSerialization dataWithJSONObject:orgisArray options:0 error:nil];
        NSArray *orgtsArray=[orgts allObjects];
        NSData *orgtsData = [NSJSONSerialization dataWithJSONObject:orgtsArray options:0 error:nil];

        //crear un dictionario con índice orgi y orgt y objeto el json corresondiente de lista de aet o de lista de aei
        NSMutableDictionary *orgtsaets=[NSMutableDictionary dictionary];
        NSMutableDictionary *orgisaeis=[NSMutableDictionary dictionary];
        for (NSString *orgi in orgisArray)
        {
            //para cada org
            NSString *orgt=[orgtsArray objectAtIndex:[orgisArray indexOfObject:orgi]];
            NSMutableArray *orgtaets=[NSMutableArray array];
            NSMutableArray *orgiaeis=[NSMutableArray array];
            for (NSString *k in [oids allKeys])
            {
                NSDictionary *d=[oids objectForKey:k];
                if ([[d objectForKey:@"pcsi"]isEqualToString:orgi])
                {
                    [orgtaets addObject:[d objectForKey:@"dicomaet"]];
                    [orgiaeis addObject:k];
                }
            }
            [orgtsaets setValue:orgtaets forKey:orgt];
            [orgisaeis setValue:orgiaeis forKey:orgi];
        }
        
        NSString *dicomweb=args[2];
        NSDictionary *dicomwebDict=[oids objectForKey:dicomweb];
        NSString *dicom1=args[3];
        NSString *dicom2=args[4];

        //-loglevel 0=debug, 1=verbose, 2=info
        [GCDWebServer setLogLevel:[[dicomwebDict objectForKey:@"logLevel"]intValue]];
        
        NSString *IIDURL=[dicomwebDict objectForKey:@"pcsURL"];
        NSString *resources=[[dicomwebDict objectForKey:@"pcsResources"]stringByExpandingTildeInPath];
        NSString *jnlp=[[NSString stringWithContentsOfFile:[resources stringByAppendingPathComponent:@"weasis/weasis.jnlp"] encoding:NSUTF8StringEncoding error:nil]stringByReplacingOccurrencesOfString:@"{IIDURL}" withString:IIDURL];
        
        //auditPath
        NSString *auditPath=[[dicomwebDict objectForKey:@"pcsAudit"]stringByExpandingTildeInPath];
        
        //storescu
        NSString *storescu=[[dicomwebDict objectForKey:@"storescu"]stringByExpandingTildeInPath];
        NSArray *storescuArgs=[dicomwebDict objectForKey:@"storescuArgs"];
        
        //pcsPort
        int pcsPort=[[dicomwebDict objectForKey:@"pcsPort"]intValue];
        GCDWebServer* httpdicomServer = [[GCDWebServer alloc] init];

#pragma mark -
#pragma mark no handler
        NSRegularExpression *defaultregex = [NSRegularExpression regularExpressionWithPattern:@"^/.*" options:NSRegularExpressionCaseInsensitive error:NULL];
        [httpdicomServer addHandlerForMethod:@"GET"
                       pathRegularExpression:defaultregex
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                                    NSURL *requestURL=request.URL;
                                    NSString *bSlash=requestURL.baseURL.absoluteString;
                                    NSString *b=[bSlash substringToIndex:[bSlash length]-1];
                                    NSString *p=requestURL.path;
                                    NSString *q=requestURL.query;
                                    GWS_LOG_INFO(@"no handler for:(%@) %@%@?%@",request.method,b,p,q);
                                    return [GCDWebServerDataResponse responseWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://opendicom.com"]] contentType:@"text/html"];
                                }
         ];

#pragma mark -
#pragma mark _____________dcm4chee-arc-light_____________
#pragma mark GET wado-uri
        NSRegularExpression *wadoregex = [NSRegularExpression regularExpressionWithPattern:@"^/.*" options:NSRegularExpressionCaseInsensitive error:NULL];
        
        [httpdicomServer addHandlerForMethod:@"GET"
                       pathRegularExpression:wadoregex
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                                    NSURL *requestURL=request.URL;
                                    NSString *bSlash=requestURL.baseURL.absoluteString;
                                    NSString *b=[bSlash substringToIndex:[bSlash length]-1];
                                    NSString *p=requestURL.path;
                                    NSString *q=requestURL.query;
                                    GWS_LOG_INFO(@"no handler for:(%@) %@%@?%@",request.method,b,p,q);
                                    return [GCDWebServerDataResponse responseWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://opendicom.com"]] contentType:@"text/html"];
                                }
         ];
#pragma mark GET studies
//studies

        NSRegularExpression *studiesqidoregex = [NSRegularExpression regularExpressionWithPattern:@"studies" options:NSRegularExpressionCaseInsensitive error:NULL];

#pragma mark GET series
//series

        NSRegularExpression *seriesqidoregex = [NSRegularExpression regularExpressionWithPattern:@"series" options:NSRegularExpressionCaseInsensitive error:NULL];

#pragma mark GET instances
//instances
        
        NSRegularExpression *instancesqidoregex = [NSRegularExpression regularExpressionWithPattern:@"instances" options:NSRegularExpressionCaseInsensitive error:NULL];
        
#pragma mark GET studies/
//studies/{StudyInstanceUID}

        NSRegularExpression *studieswadoregex = [NSRegularExpression regularExpressionWithPattern:@"studies/" options:NSRegularExpressionCaseInsensitive error:NULL];


#pragma mark GET series/
//studies/{StudyInstanceUID}/series/{SeriesInstanceUID}

        NSRegularExpression *serieswadoregex = [NSRegularExpression regularExpressionWithPattern:@"/series/" options:NSRegularExpressionCaseInsensitive error:NULL];

#pragma mark GET cda
//studies/{StudyInstanceUID}/series/{SeriesInstanceUID}/instances/{SOPInstanceUID}/cda
        
        NSRegularExpression *cdaregex = [NSRegularExpression regularExpressionWithPattern:@"/cda$" options:NSRegularExpressionCaseInsensitive error:NULL];

#pragma mark GET encapsulated
//studies/{StudyInstanceUID}/series/{SeriesInstanceUID}/instances/{SOPInstanceUID}/encapsulated
        
        NSRegularExpression *encapsulatedregex = [NSRegularExpression regularExpressionWithPattern:@"/encapsulated$" options:NSRegularExpressionCaseInsensitive error:NULL];
        [httpdicomServer addHandlerForMethod:@"GET"
                       pathRegularExpression:encapsulatedregex
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
             NSString *wadoString=[NSString stringWithFormat:@"%@%@",[dicomwebDict objectForKey:@"wadoRS"],[request.URL.path substringToIndex:[request.URL.path length]-13]];
             GWS_LOG_INFO(@"dicomweb encapsulated: %@",wadoString);
             NSData *responseData=[NSData dataWithContentsOfURL:[NSURL URLWithString:wadoString]];
             if (responseData)
             {
                 NSUInteger responseDataLength=[responseData length];
                 if (responseDataLength)
                 {
                     NSUInteger valueLocation;
                     //between "Content-Type: " and "\r\n"
                     NSRange ctRange  = [responseData rangeOfData:contentType options:0 range:NSMakeRange(0, responseDataLength)];
                     valueLocation=ctRange.location+ctRange.length;
                     NSRange rnRange  = [responseData rangeOfData:rn options:0 range:NSMakeRange(valueLocation, responseDataLength-valueLocation)];
                     NSData *contentTypeData=[responseData subdataWithRange:NSMakeRange(valueLocation,rnRange.location-valueLocation)];
                     NSString *ctString=[[NSString alloc]initWithData:contentTypeData encoding:NSUTF8StringEncoding];
                     GWS_LOG_INFO(@"%@",ctString);

                     
                     //between "\r\n\r\n" and "\r\n--"
                     NSRange rnrnRange=[responseData rangeOfData:rnrn options:0 range:NSMakeRange(0, responseDataLength)];
                     valueLocation=rnrnRange.location+rnrnRange.length;
                     NSRange rnhhRange=[responseData rangeOfData:rnhh options:0 range:NSMakeRange(valueLocation, responseDataLength-valueLocation)];
                     
                     NSData *encapsulatedData=[responseData subdataWithRange:NSMakeRange(valueLocation,rnhhRange.location-valueLocation - 1 - ([[responseData subdataWithRange:NSMakeRange(rnhhRange.location-2,2)] isEqualToData:rn] * 2))];
                     
                     return [GCDWebServerDataResponse
                             responseWithData:encapsulatedData
                             contentType:ctString];
                 }
             }
             return [GCDWebServerErrorResponse responseWithClientError:404 message:@"dicomweb: %@ notFound",request.URL.path];
         }
         ];
        
#pragma mark GET metadata
//studies/{StudyInstanceUID}/series/{SeriesInstanceUID}/instances/{SOPInstanceUID}/metadata

        NSRegularExpression *metadataregex = [NSRegularExpression regularExpressionWithPattern:@"/metadata$" options:NSRegularExpressionCaseInsensitive error:NULL];

        [httpdicomServer addHandlerForMethod:@"GET"
                       pathRegularExpression:metadataregex
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
             GWS_LOG_INFO(@"dicomweb metadata: %@",request.URL.path);
             return [GCDWebServerDataResponse
                     responseWithData:
                        [NSData dataWithContentsOfURL:
                          [NSURL URLWithString:
                           [NSString stringWithFormat:@"%@%@",
                            [dicomwebDict objectForKey:@"wadoRS"],
                            request.URL.path
                           ]
                          ]
                         ]
                       contentType:@"application/dicom+json"
                     ];
         }
         ];
        

#pragma mark -
#pragma mark _____________dicom local_____________
#pragma mark wado-uri
        /*
        NSRegularExpression *dicomwadoregex = [NSRegularExpression regularExpressionWithPattern:@"^/.*" options:NSRegularExpressionCaseInsensitive error:NULL];
        
        [httpdicomServer addHandlerForMethod:@"GET"
                       pathRegularExpression:dicomwadoregex
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                                    NSURL *requestURL=request.URL;
                                    NSString *bSlash=requestURL.baseURL.absoluteString;
                                    NSString *b=[bSlash substringToIndex:[bSlash length]-1];
                                    NSString *p=requestURL.path;
                                    NSString *q=requestURL.query;
                                    GWS_LOG_INFO(@"no handler for:(%@) %@%@?%@",request.method,b,p,q);
                                    return [GCDWebServerDataResponse responseWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://opendicom.com"]] contentType:@"text/html"];
                                }
         ];
         */
        
#pragma mark studies
        //studies
        
        NSRegularExpression *dicomstudiesqidoregex = [NSRegularExpression regularExpressionWithPattern:@"studies" options:NSRegularExpressionCaseInsensitive error:NULL];
        
#pragma mark series
        //series
        
        NSRegularExpression *dicomseriesqidoregex = [NSRegularExpression regularExpressionWithPattern:@"series" options:NSRegularExpressionCaseInsensitive error:NULL];
        
#pragma mark instances
        //instances
        
        NSRegularExpression *dicominstancesqidoregex = [NSRegularExpression regularExpressionWithPattern:@"instances" options:NSRegularExpressionCaseInsensitive error:NULL];
        
#pragma mark studies/
        //studies/{StudyInstanceUID}
        
        NSRegularExpression *dicomstudieswadoregex = [NSRegularExpression regularExpressionWithPattern:@"studies/" options:NSRegularExpressionCaseInsensitive error:NULL];
        
        
#pragma mark series/
        //studies/{StudyInstanceUID}/series/{SeriesInstanceUID}
        
        NSRegularExpression *dicomserieswadoregex = [NSRegularExpression regularExpressionWithPattern:@"/series/" options:NSRegularExpressionCaseInsensitive error:NULL];
        
#pragma mark cda
        //studies/{StudyInstanceUID}/series/{SeriesInstanceUID}/instances/{SOPInstanceUID}/cda
        
        NSRegularExpression *dicomcdaregex = [NSRegularExpression regularExpressionWithPattern:@"/cda$" options:NSRegularExpressionCaseInsensitive error:NULL];
        
#pragma mark encapsulated
        //studies/{StudyInstanceUID}/series/{SeriesInstanceUID}/instances/{SOPInstanceUID}/encapsulated
        
        NSRegularExpression *dicomencapsulatedregex = [NSRegularExpression regularExpressionWithPattern:@"/encapsulated$" options:NSRegularExpressionCaseInsensitive error:NULL];
        
#pragma mark metadata
        //studies/{StudyInstanceUID}/series/{SeriesInstanceUID}/instances/{SOPInstanceUID}/metadata
        
        NSRegularExpression *diocmmetadataregex = [NSRegularExpression regularExpressionWithPattern:@"/metadata$" options:NSRegularExpressionCaseInsensitive error:NULL];
#pragma mark -
#pragma mark _____________remoto_____________
#pragma mark wado-uri
        
        /*
        NSRegularExpression *remotowadoregex = [NSRegularExpression regularExpressionWithPattern:@"^/.*" options:NSRegularExpressionCaseInsensitive error:NULL];
        
        [httpdicomServer addHandlerForMethod:@"GET"
                       pathRegularExpression:remotowadoregex
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                                    NSURL *requestURL=request.URL;
                                    NSString *bSlash=requestURL.baseURL.absoluteString;
                                    NSString *b=[bSlash substringToIndex:[bSlash length]-1];
                                    NSString *p=requestURL.path;
                                    NSString *q=requestURL.query;
                                    GWS_LOG_INFO(@"no handler for:(%@) %@%@?%@",request.method,b,p,q);
                                    return [GCDWebServerDataResponse responseWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://opendicom.com"]] contentType:@"text/html"];
                                }
         ];
         */
        
#pragma mark studies
        //studies
        
        NSRegularExpression *remotostudiesqidoregex = [NSRegularExpression regularExpressionWithPattern:@"studies" options:NSRegularExpressionCaseInsensitive error:NULL];
        
#pragma mark series
        //series
        
        NSRegularExpression *remotoseriesqidoregex = [NSRegularExpression regularExpressionWithPattern:@"series" options:NSRegularExpressionCaseInsensitive error:NULL];
        
#pragma mark instances
        //instances
        
        NSRegularExpression *remotoinstancesqidoregex = [NSRegularExpression regularExpressionWithPattern:@"instances" options:NSRegularExpressionCaseInsensitive error:NULL];
        
#pragma mark studies/
        //studies/{StudyInstanceUID}
        
        NSRegularExpression *remotostudieswadoregex = [NSRegularExpression regularExpressionWithPattern:@"studies/" options:NSRegularExpressionCaseInsensitive error:NULL];
        
        
#pragma mark series/
        //studies/{StudyInstanceUID}/series/{SeriesInstanceUID}
        
        NSRegularExpression *remotoserieswadoregex = [NSRegularExpression regularExpressionWithPattern:@"/series/" options:NSRegularExpressionCaseInsensitive error:NULL];
        
#pragma mark cda
        //studies/{StudyInstanceUID}/series/{SeriesInstanceUID}/instances/{SOPInstanceUID}/cda
        
        NSRegularExpression *remotocdaregex = [NSRegularExpression regularExpressionWithPattern:@"/cda$" options:NSRegularExpressionCaseInsensitive error:NULL];
        
#pragma mark encapsulated
        //studies/{StudyInstanceUID}/series/{SeriesInstanceUID}/instances/{SOPInstanceUID}/encapsulated
        
        NSRegularExpression *remotoencapsulatedregex = [NSRegularExpression regularExpressionWithPattern:@"/encapsulated$" options:NSRegularExpressionCaseInsensitive error:NULL];
        
#pragma mark metadata
        //studies/{StudyInstanceUID}/series/{SeriesInstanceUID}/instances/{SOPInstanceUID}/metadata
        
        NSRegularExpression *remotometadataregex = [NSRegularExpression regularExpressionWithPattern:@"/metadata$" options:NSRegularExpressionCaseInsensitive error:NULL];
        

#pragma mark -
#pragma mark _____________IID_____________
#pragma mark    /bir/weasis
//-----------------------------------------------------------------
// http://{localpcs}/weasis/
//-----------------------------------------------------------------
        [httpdicomServer addGETHandlerForBasePath:@"/bir/weasis/" directoryPath:[resources stringByAppendingPathComponent:@"weasis/"] indexFilename:nil cacheAge:3600 allowRangeRequests:YES];
        
        
#pragma mark /bir/weasis/bundle
//-----------------------------------------------------------------
// http://{localpcs}/weasis/bundle/
//-----------------------------------------------------------------
        [httpdicomServer addGETHandlerForBasePath:@"/bir/weasis/bundle/" directoryPath:[resources stringByAppendingPathComponent:@"weasis/bundle/"] indexFilename:nil cacheAge:3600 allowRangeRequests:YES];

        
#pragma mark IHEInvokeImageDisplay
//-----------------------------------------------------------------------------------------------------------------------------
// IHEInvokeImageDisplay?requestType=STUDY&accessionNumber=123&viewerType=IHE_BIR&diagnosticQuality=true&keyImagesOnly&pcs=1.2
//-----------------------------------------------------------------------------------------------------------------------------
        
        [httpdicomServer addHandlerForMethod:@"GET"
                                  path:@"/IHEInvokeImageDisplay"
                               requestClass:[GCDWebServerRequest class]
                               processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
             //request parts logging
             NSURL *requestURL=request.URL;
             NSString *bSlash=requestURL.baseURL.absoluteString;
             NSString *b=[bSlash substringToIndex:[bSlash length]-1];
             NSString *p=requestURL.path;
             NSString *q=requestURL.query;
             GWS_LOG_INFO(@"%@%@?%@",b,p,q);

             //request validation
             NSString *requestType=[request.query objectForKey:@"requestType"];
             NSString *accessionNumber=[request.query objectForKey:@"accessionNumber"];
             NSString *pacs=[request.query objectForKey:@"pacs"];
             if (   ([request.query count]>2)
                 && requestType
                 && [requestType isEqualToString:@"STUDY"]
                 && accessionNumber
                 && ([accessionNumber length]<17)
                 && [SHRegex numberOfMatchesInString:accessionNumber options:0 range:NSMakeRange(0,[accessionNumber length])]
                 && pacs
                 && ([pacs length]<65)
                 && [UIRegex numberOfMatchesInString:pacs options:0 range:NSMakeRange(0,[pacs length])]
                 && [oids objectForKey:pacs]
                 )
             {
                 NSString *accessionNumberURL=[accessionNumber stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                 //find remote pcs url
                 NSDictionary *remote=[oids objectForKey:pacs];
                 NSString *remotepcs=[remote objectForKey:@"pcsURL"];
                 
                 //request http://{remotepcs}/weasisManifest?accessionNumber=123&pacs=1.2
                 NSString *weasisManifestURL=[NSString stringWithFormat:@"%@/weasisManifest?accessionNumber=%@&pacs=%@",remotepcs,accessionNumberURL,pacs];
                 GWS_LOG_INFO(@"-> %@",weasisManifestURL);
                 NSData *xmlData=[NSData dataWithContentsOfURL:[NSURL URLWithString:weasisManifestURL] options:NSDataReadingUncached error:nil];
                 /*
                 if (error)
                 {
                     GWS_LOG_WARNING(@"%@",[error description]);
                     return [GCDWebServerDataResponse responseWithText:[NSString stringWithFormat:@"%@",[error description]]];
                 }
                  */
                 if ([xmlData length]>0)
                 {
                     BOOL seriesFetched=false;
                     //get study and series UID
                     NSXMLDocument *xmlDocument=[[NSXMLDocument alloc]initWithData:xmlData options:0 error:nil];
                     NSArray *studyArray = [xmlDocument nodesForXPath:@"wado_query/Patient/Study" error:NULL];
                     for (id studyNode in studyArray)
                     {
                         NSArray *studyInstanceUIDarray = [studyNode nodesForXPath:@"@StudyInstanceUID" error:NULL];
                         NSString *studyInstanceUID = [[studyInstanceUIDarray objectAtIndex:0]stringValue];
                         
                         NSArray *seriesArray = [studyNode nodesForXPath:@"Series" error:NULL];
#pragma mark download series and forward them to dcm4chee
                         //dispach download of series from OsiriX
                         for (id seriesNode in seriesArray)
                         {
                             seriesFetched=true;
                             NSArray *seriesInstanceUIDarray = [seriesNode nodesForXPath:@"@SeriesInstanceUID" error:NULL];
                             NSString *seriesInstanceUID = [[seriesInstanceUIDarray objectAtIndex:0]stringValue];
                             
                             NSString *retrieveSeries=[NSString stringWithFormat:@"%@/%@/studies/%@/series/%@",
                                                       [remote objectForKey:@"wadoRS"],
                                                       [remote objectForKey:@"aet"],
                                                       studyInstanceUID,
                                                       seriesInstanceUID
                                                       ];
                             NSString *seriesPath=[[auditPath stringByAppendingPathComponent:seriesInstanceUID] stringByAppendingPathComponent:[dicomDTFormatter stringFromDate:[NSDate date]]];
                             if(![fileManager fileExistsAtPath:seriesPath])
                             {
                                 NSLog(@"wado-rs series: %@",seriesPath);
                                 //first processing of solicitud
                                 if(![fileManager createDirectoryAtPath:seriesPath withIntermediateDirectories:YES attributes:nil error:nil])
                                     NSLog(@"ERROR could not create folder");
                                 else
                                 {
                                     NSData *downloaded=[NSData dataWithContentsOfURL:[NSURL URLWithString:retrieveSeries]];
                                     if (downloaded && [downloaded length]>0)
                                     {
                                         //[downloaded writeToFile:[seriesPath stringByAppendingPathComponent:@"downloaded.zip"] atomically:NO];
                                         
                                         //unzip
                                         NSError *error=nil;
                                         ZZArchive *archive = [ZZArchive archiveWithData:downloaded];
                                         NSUInteger entriesCount=archive.entries.count;
                                         NSLog(@"unzipped objects %lu",(unsigned long)entriesCount);
                                         
                                         unsigned long counter=0;
                                         BOOL oneOrMoreUnzipped=false;
                                         for (ZZArchiveEntry *entry in archive.entries)
                                         {
                                             NSData *unzipped= [entry newDataWithError:&error];
                                             if (error!=nil) NSLog(@"ERROR could NOT unzip\r%@",[error description]);
                                             else oneOrMoreUnzipped|=[unzipped writeToFile:[NSString stringWithFormat:@"%@/%lu.dcm",seriesPath,counter++] atomically:NO];
                                         }
                                         if (oneOrMoreUnzipped)
                                         {
                                             NSMutableArray *argsSeries=[NSMutableArray arrayWithArray:storescuArgs];
                                             [argsSeries addObject:seriesPath];

                                             NSMutableData *stdoutData = [NSMutableData data];
                                             task(
                                                  storescu,
                                                  argsSeries,
                                                  [NSData data],
                                                  stdoutData
                                                  );
                                             [stdoutData writeToFile:[seriesPath stringByAppendingPathComponent:@"stdout+stderr.log"] atomically:NO];
                                         }
                                     }
                                 }
                             }
                         }
                     }
                     
                     if (seriesFetched)
                     {
                         //create jnlp
                         NSString *xmlString=[[NSString alloc]initWithData:xmlData encoding:NSUTF8StringEncoding];
                         NSString *localizedXmlString=[NSString stringWithFormat:xmlString,[dicomwebDict objectForKey:@"wadoURL"],[dicomwebDict objectForKey:@"wadoAdditionnalParameters"]];
                         NSData *gzipped=[LFCGzipUtility gzipData:[localizedXmlString dataUsingEncoding:NSUTF8StringEncoding]];

                         return [GCDWebServerDataResponse responseWithData:[[NSString stringWithFormat:jnlp,[gzipped base64EncodedStringWithOptions:0]] dataUsingEncoding:NSUTF8StringEncoding] contentType:@"application/x-java-jnlp-file"];//application/x-gzip"];//
                     }
                     GWS_LOG_WARNING(@"no series");
                     return [GCDWebServerDataResponse responseWithText:@"no series"];
                 }
                 else
                 {
                     GWS_LOG_WARNING(@"no series");
                     return [GCDWebServerDataResponse responseWithText:@"no series"];
                 }
             }
             GWS_LOG_WARNING(@"incorrect syntax for request /bir/study");
             return [GCDWebServerDataResponse responseWithText:@"incorrect syntax for request /IHEInvokeImageDisplay"];
         }
         ];
        
        
#pragma mark /bir/weasisManifest
//-------------------------------------------------------------------
// http://{remotepcs}/bir/weasisManifest?accessionNumber=123&pacs=1.2
//-------------------------------------------------------------------

        [httpdicomServer addHandlerForMethod:@"GET"
                                       path:@"/bir/weasisManifest"
                               requestClass:[GCDWebServerRequest class]
                               processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
             //request parts logging
             NSURL *requestURL=request.URL;
             NSString *bSlash=requestURL.baseURL.absoluteString;
             NSString *b=[bSlash substringToIndex:[bSlash length]-1];
             NSString *p=requestURL.path;
             NSString *q=requestURL.query;
             GWS_LOG_INFO(@"%@%@?%@",b,p,q);

 
             //request validation
             NSString *accessionNumber=[request.query objectForKey:@"accessionNumber"];
             NSString *pcs=[request.query objectForKey:@"pcs"];
             if (   ([request.query count]==2)
                 && accessionNumber
                 && ([accessionNumber length]<17)
                 && [SHRegex numberOfMatchesInString:accessionNumber options:0 range:NSMakeRange(0,[accessionNumber length])]
                 && pcs
                 && ([pcs length]<65)
                 && [UIRegex numberOfMatchesInString:pcs options:0 range:NSMakeRange(0,[pcs length])]
                 && [oids objectForKey:pcs]
                )
             {
                 NSString *accessionNumberURL=[accessionNumber stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                 //pacs params
                 NSDictionary *pacsDict=[oids objectForKey:pcs];
                 
#pragma mark allow other select (sql, dicom Q/R)
                 
                 NSString *qidoRS=[pacsDict objectForKey:@"qidoRS"];
                 NSString *aet=[pacsDict objectForKey:@"aet"];
                 
                 //weasisManifest
                 NSMutableString *weasisManifest=[NSMutableString stringWithCapacity:10000];
                 [weasisManifest appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\r"];
                 [weasisManifest appendString:@"<wado_query wadoURL=\"%@\" requireOnlySOPInstanceUID=\"false\" additionnalParameters=\"%@\">\r"];

                 //study list
                 NSString *studyURL=nil;
                 if ([[pacsDict objectForKey:@"accessionNumberIssuer"]boolValue]==true)
                     studyURL=[NSString stringWithFormat:@"%@/%@/studies?AccessionNumber=%@&00080051.00400032=%@&00080051.00400033=ISO",qidoRS,aet,accessionNumberURL,pcs];
                 else studyURL=[NSString stringWithFormat:@"%@/%@/studies?AccessionNumber=%@",qidoRS,aet,accessionNumberURL];
                 GWS_LOG_INFO(@"-> %@",studyURL);
                 NSData *studyJson=[NSData dataWithContentsOfURL:[NSURL URLWithString:studyURL]];
                 NSArray *studyArray=[NSJSONSerialization JSONObjectWithData:studyJson options:0 error:nil];
                 NSUInteger studyArrayCount=[studyArray count];
                 //GWS_LOG_INFO(@"%@",[studyArray description]);

                 //the accessionNumber may join more than one study of one or more patient !!!
                 //look for patient roots first
                 NSMutableArray *p=[NSMutableArray array];
                 for (NSDictionary *studyInstance in studyArray)
                 {
                     NSString *ii=[[studyInstance objectForKey:@"00100021"]objectForKey:@"Value"];
                     if (!ii) ii=@"";
                     [p addObject:[[[[studyInstance objectForKey:@"00100020"]objectForKey:@"Value"]objectAtIndex:0]stringByAppendingPathComponent:ii]];
                 }
             
                 //each patient
                 NSMutableDictionary *patientStudy=[NSMutableDictionary dictionaryWithCapacity:32];
                 for (NSString *patient in [NSSet setWithArray:p])
                 {
                     NSUInteger studyIndex=[p indexOfObject:patient];
                     [patientStudy setDictionary:[studyArray objectAtIndex:studyIndex]];
                     
                     NSString *PatientName=[[[[patientStudy objectForKey:@"00100010"]objectForKey:@"Value"]objectAtIndex:0]valueForKey:@"Alphabetic"];
                     if (!PatientName) PatientName=@"";
                     NSString *PatientID=[[[patientStudy objectForKey:@"00100020"]objectForKey:@"Value"]objectAtIndex:0];
                     if (!PatientID) PatientID=@"";
                     NSString *IssuerOfPatientID=[[[patientStudy objectForKey:@"00100021"]objectForKey:@"Value"]objectAtIndex:0];
                     if (!IssuerOfPatientID) IssuerOfPatientID=@"";
                     NSString *PatientBirthDate=[[[patientStudy objectForKey:@"00100030"]objectForKey:@"Value"]objectAtIndex:0];
                     if (!PatientBirthDate) PatientBirthDate=@"";
                     NSString *PatientSex=[[[patientStudy objectForKey:@"00100040"]objectForKey:@"Value"]objectAtIndex:0];
                     if (!PatientSex) PatientSex=@"";
                     
                     [weasisManifest appendFormat:@"<Patient PatientName=\"%@\" PatientID=\"%@\" IssuerOfPatientID=\"%@\" PatientBirthDate=\"%@\" PatientSex=\"%@\">\r",PatientName,PatientID,IssuerOfPatientID,PatientBirthDate,PatientSex];
                     
                     //each study of this patient
                     while ([patientStudy count]>0)
                     {
                         NSString *SpecificCharacterSet=[[[patientStudy objectForKey:@"00080005"]objectForKey:@"Value"]objectAtIndex:0];
                         if (!SpecificCharacterSet) SpecificCharacterSet=@"";
                         NSString *StudyInstanceUID=[[[patientStudy objectForKey:@"0020000D"]objectForKey:@"Value"]objectAtIndex:0];
                         if (!StudyInstanceUID) StudyInstanceUID=@"";
                         NSString *AccessionNumber=[[[patientStudy objectForKey:@"00080050"]objectForKey:@"Value"]objectAtIndex:0];
                         if (!AccessionNumber) AccessionNumber=@"";
                         NSString *RetrieveAETitle=[[[patientStudy objectForKey:@"00080054"]objectForKey:@"Value"]objectAtIndex:0];
                         if (!RetrieveAETitle) RetrieveAETitle=@"";
                         NSString *StudyID=[[[patientStudy objectForKey:@"00200010"]objectForKey:@"Value"]objectAtIndex:0];
                         if (!StudyID) StudyID=@"";
                         NSString *StudyDescription=[[[patientStudy objectForKey:@"00081030"]objectForKey:@"Value"]objectAtIndex:0];
                         if (!StudyDescription) StudyDescription=@"";
                         NSString *StudyDate=[[[patientStudy objectForKey:@"00080020"]objectForKey:@"Value"]objectAtIndex:0];
                         if (!StudyDate) StudyDate=@"";
                         NSString *StudyTime=[[[patientStudy objectForKey:@"00080030"]objectForKey:@"Value"]objectAtIndex:0];
                         if (!StudyTime) StudyTime=@"";
                         
                         [weasisManifest appendFormat:@"<Study SpecificCharacterSet=\"%@\" StudyInstanceUID=\"%@\" AccessionNumber=\"%@\" RetrieveAETitle=\"%@\" StudyID=\"%@\" StudyDescription=\"%@\" StudyDate=\"%@\" StudyTime=\"%@\">\r",SpecificCharacterSet, StudyInstanceUID,AccessionNumber,RetrieveAETitle,StudyID,StudyDescription,StudyDate,StudyTime];
                         
                         //patient study series list
                         NSString *seriesURL=[NSString stringWithFormat:@"%@/%@/studies/%@/series",qidoRS,aet,StudyInstanceUID];
                         GWS_LOG_INFO(@"-> %@",seriesURL);
                         NSData *seriesJson=[NSData dataWithContentsOfURL:[NSURL URLWithString:seriesURL]];
                         NSArray *seriesArray=[NSJSONSerialization JSONObjectWithData:seriesJson options:0 error:nil];

                         for (NSDictionary *series in seriesArray)
                         {
                             NSString *SeriesInstanceUID=[[[series objectForKey:@"0020000E"]objectForKey:@"Value"]objectAtIndex:0];
                             if (!SeriesInstanceUID) SeriesInstanceUID=@"";
                             NSString *SeriesDescription=[[[series objectForKey:@"0008103E"]objectForKey:@"Value"]objectAtIndex:0];
                             if (!SeriesDescription) SeriesDescription=@"";
                             NSString *SeriesNumber=[[[series objectForKey:@"00200011"]objectForKey:@"Value"]objectAtIndex:0];
                             if (!SeriesNumber) SeriesNumber=@"";
                             NSString *Modality=[[[series objectForKey:@"00080060"]objectForKey:@"Value"]objectAtIndex:0];
                             if (!Modality) Modality=@"";
                             
                             [weasisManifest appendFormat:@"<Series SeriesInstanceUID=\"%@\" SeriesDescription=\"%@\" SeriesNumber=\"%@\" Modality=\"%@\">\r",SeriesInstanceUID,SeriesDescription,SeriesNumber,Modality];
                             
                             //patient study series instances list
                             NSString *instanceURL=[NSString stringWithFormat:@"%@/%@/studies/%@/series/%@/instances",qidoRS,aet,StudyInstanceUID,SeriesInstanceUID];
                             GWS_LOG_INFO(@"-> %@",instanceURL);
                             NSData *instanceJson=[NSData dataWithContentsOfURL:[NSURL URLWithString:instanceURL]];
                             NSArray *instanceArray=[NSJSONSerialization JSONObjectWithData:instanceJson options:0 error:nil];
                             
                             for (NSDictionary *instance in instanceArray)
                             {
                                 NSString *SOPInstanceUID=[[[instance objectForKey:@"00080018"]objectForKey:@"Value"]objectAtIndex:0];
                                 if (!SeriesInstanceUID) SeriesInstanceUID=@"";
                                 NSString *InstanceNumber=[[[instance objectForKey:@"00200013"]objectForKey:@"Value"]objectAtIndex:0];
                                 if (!InstanceNumber) InstanceNumber=@"";
                                 NSString *SOPClassUID=[[[instance objectForKey:@"00080016"]objectForKey:@"Value"]objectAtIndex:0];
                                 if (!SOPClassUID) SOPClassUID=@"";
                                 
                                 [weasisManifest appendFormat:@"<Instance SOPInstanceUID=\"%@\" InstanceNumber=\"%@\" SOPClassUID=\"%@\"/>\r",SOPInstanceUID,InstanceNumber,SOPClassUID];
                             }
                             
                             [weasisManifest appendString:@"</Series>\r"];
                         }
                         
                         [weasisManifest appendString:@"</Study>\r"];
                         
                         //next study of this patient
                         if (studyIndex<studyArrayCount)
                         {
                             studyIndex++;
                             studyIndex=[p indexOfObject:patient inRange:NSMakeRange(studyIndex,studyArrayCount-studyIndex)];
                             if (studyIndex==NSNotFound)[patientStudy removeAllObjects];
                             else [patientStudy setDictionary:[studyArray objectAtIndex:studyIndex]];
                         }
                         else [patientStudy removeAllObjects];
                     }
                     [weasisManifest appendString:@"</Patient>\r"];
                 }
                 
                 [weasisManifest appendString:@"</wado_query>\r"];
                 //GWS_LOG_INFO(@"%@",weasisManifest);
                 
                 return [GCDWebServerDataResponse responseWithData:[weasisManifest dataUsingEncoding:NSUTF8StringEncoding] contentType:@"application/xml"];
             }
             GWS_LOG_WARNING(@"incorrect syntax for request /weasisManifest");
             return [GCDWebServerDataResponse responseWithText:@"incorrect syntax for request /weasisManifest"];
         }
         ];
#pragma mark -
#pragma mark _____________handlers adaptivos_____________
#pragma mark -
#pragma mark _____________redirects dicomweb, dicom (local, (pcs) remoto_____________

#pragma mark /pcs
        
        NSRegularExpression *pcsregex = [NSRegularExpression regularExpressionWithPattern:@"^/pcs/[1-2](\\d)*(\\.0|\\.[1-9](\\d)*)*/.*$" options:NSRegularExpressionCaseInsensitive error:NULL];

        [httpdicomServer addHandlerForMethod:@"GET"
                       pathRegularExpression:pcsregex
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
             //request parts logging
             NSURL *requestURL=request.URL;
             NSString *bSlash=requestURL.baseURL.absoluteString;
             NSString *b=[bSlash substringToIndex:[bSlash length]-1];
             NSString *p=requestURL.path;
             NSString *q=requestURL.query;
             NSMutableArray *pComponent=[NSMutableArray arrayWithArray:[p componentsSeparatedByString:@"/"]];
             NSString *oid=[NSString stringWithString:pComponent[2]];
             NSString *oidURLString=[[oids objectForKey:oid]objectForKey:@"pcsURL"];
             if (oidURLString){
                 [pComponent removeObjectAtIndex:2];
                 [pComponent removeObjectAtIndex:1];
                 NSString *redirectString;
                 if (q){
                     redirectString=[NSString stringWithFormat:@"%@%@?%@&ian=%@",oidURLString,[pComponent componentsJoinedByString:@"/"],q,oid];
                 }
                 else {
                     redirectString=[NSString stringWithFormat:@"%@%@?ian=%@",oidURLString,[pComponent componentsJoinedByString:@"/"],oid];
                 }
                 GWS_LOG_INFO(@"%@%@?%@ -> %@",b,p,q,redirectString);
                 
                 //tenemos una orden a realizar por PCS remoto
                 //si es un query, conviene obtener la respuesta, y luego devolverla al cliente, cambiando el wado para que vaya a lo local
                 //si es un fetch wado o wado rest, cargar los archivos en dicomweb
                 
                 
                 return [GCDWebServerResponse
                         responseWithRedirect:[NSURL URLWithString:redirectString]
                         permanent:YES
                         ];
             }
             else {
                 GWS_LOG_INFO(@"%@%@?%@ doesn´t match any known OID",b,p,q);
                 return [GCDWebServerErrorResponse responseWithClientError:404 message:
                         @"%@%@?%@ doesn´t match any known OID",b,p,q];
             }
         }
         ];
#pragma mark /pcs/dicom2
        
        NSRegularExpression *dicom2regex = [NSRegularExpression regularExpressionWithPattern:[[@"^/pcs/" stringByAppendingString:dicom2] stringByAppendingString:@"/.*$"] options:NSRegularExpressionCaseInsensitive error:NULL];

        [httpdicomServer addHandlerForMethod:@"GET"
                       pathRegularExpression:dicom2regex
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
/*             //qido,wado,stow?
             //protocolo?
             if ([request.method isEqualToString:@"POST"])
             {
                 //probable stow
             }
             else if ([pComponents count]==4)
             {
                 //probable //qido studies, series or instances
             }
             else if ([pComponents count]==3)
             {
                 //probable wado-uri
             }
*/
             
             
             //request parts logging
             NSURL *requestURL=request.URL;
             NSString *bSlash=requestURL.baseURL.absoluteString;
             NSString *b=[bSlash substringToIndex:[bSlash length]-1];
             NSString *p=requestURL.path;
             NSString *q=requestURL.query;
             NSMutableArray *pComponents=(NSMutableArray*)[p componentsSeparatedByString:@"/"];
             NSString *oid=[NSString stringWithString:pComponents[2]];
             [pComponents removeObjectsInRange:NSMakeRange(1,2)];
             NSString *redirectString;
             if (q){redirectString=[NSString stringWithFormat:@"%@?%@&pcs=%@",[pComponents componentsJoinedByString:@"/"],q,oid];}
             else {redirectString=[NSString stringWithFormat:@"%@?pcs=%@",[pComponents componentsJoinedByString:@"/"],oid];}
             GWS_LOG_INFO(@"dicom2: %@%@?%@ -> %@",b,p,q,redirectString);
             
             //redirect dentro del PCS local
             return [GCDWebServerResponse
                     responseWithRedirect:[NSURL URLWithString:redirectString]
                     permanent:NO
                     ];
         }
         ];
#pragma mark /pcs/dicom1
        
        NSRegularExpression *dicom1regex = [NSRegularExpression regularExpressionWithPattern:[[@"^/pcs/" stringByAppendingString:dicom1] stringByAppendingString:@"/.*$"] options:NSRegularExpressionCaseInsensitive error:NULL];

        [httpdicomServer addHandlerForMethod:@"GET"
                       pathRegularExpression:dicom1regex
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
             //request parts logging
             NSURL *requestURL=request.URL;
             NSString *bSlash=requestURL.baseURL.absoluteString;
             NSString *b=[bSlash substringToIndex:[bSlash length]-1];
             NSString *p=requestURL.path;
             NSString *q=requestURL.query;
             NSMutableArray *pComponents=(NSMutableArray*)[p componentsSeparatedByString:@"/"];
             NSString *oid=[NSString stringWithString:pComponents[2]];
             [pComponents removeObjectsInRange:NSMakeRange(1,2)];
             NSString *redirectString;
             if (q){redirectString=[NSString stringWithFormat:@"%@?%@&pcs=%@",[pComponents componentsJoinedByString:@"/"],q,oid];}
             else {redirectString=[NSString stringWithFormat:@"%@?pcs=%@",[pComponents componentsJoinedByString:@"/"],oid];}
             GWS_LOG_INFO(@"dicom1: %@%@?%@ -> %@",b,p,q,redirectString);
             
             //redirect dentro del PCS local
             return [GCDWebServerResponse
                     responseWithRedirect:[NSURL URLWithString:redirectString]
                     permanent:NO
                     ];
         }
         ];
#pragma mark /pcs/dicomweb
//el handler principal de dicomweb es sin /pcs/{OID} y Es accesible directamente también.
//por esta razón hacemos un redirect
        NSRegularExpression *dicomwebregex = [NSRegularExpression regularExpressionWithPattern:[[@"^/pcs/" stringByAppendingString:dicomweb] stringByAppendingString:@"/.*$"] options:NSRegularExpressionCaseInsensitive error:NULL];

        [httpdicomServer addHandlerForMethod:@"GET"
                       pathRegularExpression:dicomwebregex
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
             NSString *p=[request.URL.path substringFromIndex:5+[dicomweb length]];

             NSString *q=request.URL.query;
             if (q) return [GCDWebServerResponse
                            responseWithRedirect:[NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",p,q]]
                            permanent:YES];

             return [GCDWebServerResponse
                     responseWithRedirect:[NSURL URLWithString:p]
                     permanent:YES];
          }
         ];

#pragma mark -
#pragma mark orgs y aets

        NSRegularExpression *orgtsRegex = [NSRegularExpression regularExpressionWithPattern:@"^/orgts.*$" options:0 error:NULL];

        [httpdicomServer addHandlerForMethod:@"GET"
                       pathRegularExpression:orgtsRegex
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
             NSURL *requestURL=request.URL;
             NSString *p=requestURL.path;
             NSMutableArray *pComponents=(NSMutableArray*)[p componentsSeparatedByString:@"/"];
             NSUInteger pCount=[pComponents count];
             if (![pComponents[1] isEqualToString:@"orgts"])
             {
                 return [GCDWebServerErrorResponse responseWithClientError:404 message:@"service '%@' not found",pComponents[1]];
             }
             if (pCount==2)
             {
//orgts
                 return [GCDWebServerDataResponse responseWithData:orgtsData contentType:@"application/json"];
             }
             
             NSUInteger lOrg = [pComponents[2]length];
             if (  (lOrg>16)
                 ||![SHRegex numberOfMatchesInString:pComponents[2] options:0 range:NSMakeRange(0,lOrg)]
                 )
                 return [GCDWebServerErrorResponse responseWithClientError:404 message:@"org titles should conform to DICOM SH datatype. '%@' doesn´t.",pComponents[2]];

             NSUInteger orgtIndex=[orgtsArray indexOfObject:pComponents[2]];
             if (orgtIndex==NSNotFound)
                 return [GCDWebServerErrorResponse responseWithClientError:404 message:@"org '%@' not found",pComponents[2]];

             if (pCount==3)
             {
                 NSData *orgiData = [NSJSONSerialization dataWithJSONObject:[NSArray arrayWithObject:[orgisArray objectAtIndex:orgtIndex]] options:0 error:nil];
                 return [GCDWebServerDataResponse responseWithData:orgiData contentType:@"application/json"];
             }
//pCount>3
             if (![pComponents[3]isEqualToString:@"aets"])
                 return [GCDWebServerErrorResponse responseWithClientError:404 message:@"third component of the path '%@' should be 'aets'",p];

//orgts/{title}/aets
             if (pCount==4)
                 return [GCDWebServerDataResponse responseWithData:[NSJSONSerialization dataWithJSONObject:[orgtsaets objectForKey:pComponents[2]] options:0 error:nil] contentType:@"application/json"];
//pCount>4
             NSUInteger lAet = [pComponents[4]length];
             if (  (lAet>16)
                 ||![SHRegex numberOfMatchesInString:pComponents[4] options:0 range:NSMakeRange(0,lAet)]
                 )
                 return [GCDWebServerErrorResponse responseWithClientError:404 message:@"ae titles should conform to DICOM SH datatype. '%@' doesn´t.",pComponents[4]];

             if (pCount==5)
             {
//orgts/{title}/aets/{title}
                 NSUInteger aetIndex=[[orgtsaets objectForKey:pComponents[2]] indexOfObject:pComponents[4]];
                 if (aetIndex==NSNotFound)
                     return [GCDWebServerErrorResponse responseWithClientError:404 message:@"aet '%@' not found",pComponents[4]];
                 return [GCDWebServerDataResponse responseWithData:
                             [NSJSONSerialization dataWithJSONObject:
                              [NSArray arrayWithObject:
                               [
                                [orgisaeis objectForKey:
                                 [orgisArray objectAtIndex:orgtIndex]
                                 ]
                                objectAtIndex:aetIndex
                                ]
                               ] options:0 error:nil
                              ]
                              contentType:@"application/json"
                             ];
             }
             return [GCDWebServerErrorResponse responseWithClientError:404 message:@"too many segments in path '%@'",p];
         }
         ];
        
        
        NSRegularExpression *orgisRegex = [NSRegularExpression regularExpressionWithPattern:@"^/orgis.*$" options:0 error:NULL];
        
        [httpdicomServer addHandlerForMethod:@"GET"
                       pathRegularExpression:orgisRegex
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
         {
             NSURL *requestURL=request.URL;
             NSString *p=requestURL.path;
             NSMutableArray *pComponents=(NSMutableArray*)[p componentsSeparatedByString:@"/"];
             NSUInteger pCount=[pComponents count];
             if (![pComponents[1] isEqualToString:@"orgis"])
             {
                 return [GCDWebServerErrorResponse responseWithClientError:404 message:@"service '%@' not found",pComponents[1]];
             }
             if (pCount==2)
             {
//orgis
                 return [GCDWebServerDataResponse responseWithData:orgisData contentType:@"application/json"];
             }
             
             NSUInteger lOrg = [pComponents[2]length];
             if (  (lOrg>64)
                 ||![UIRegex numberOfMatchesInString:pComponents[2] options:0 range:NSMakeRange(0,lOrg)]
                 )
                 return [GCDWebServerErrorResponse responseWithClientError:404 message:@"org titles should conform to DICOM UI datatype. '%@' doesn´t.",pComponents[2]];
             
             NSUInteger orgiIndex=[orgisArray indexOfObject:pComponents[2]];
             if (orgiIndex==NSNotFound)
                 return [GCDWebServerErrorResponse responseWithClientError:404 message:@"org '%@' not found",pComponents[2]];
             
             if (pCount==3)
             {
//orgis/{oid}
                 NSData *orgtData = [NSJSONSerialization dataWithJSONObject:[NSArray arrayWithObject:[orgtsArray objectAtIndex:orgiIndex]] options:0 error:nil];
                 return [GCDWebServerDataResponse responseWithData:orgtData contentType:@"application/json"];
             }
//pCount>3
             if (![pComponents[3]isEqualToString:@"aeis"])
                 return [GCDWebServerErrorResponse responseWithClientError:404 message:@"third component of the path '%@' should be 'aeis'",p];
             
//orgis/{oid}/aeis
             if (pCount==4)
                 return [GCDWebServerDataResponse responseWithData:[NSJSONSerialization dataWithJSONObject:[orgisaeis objectForKey:pComponents[2]] options:0 error:nil] contentType:@"application/json"];
//pCount>4
             NSUInteger lAet = [pComponents[4]length];
             if (  (lAet>64)
                 ||![UIRegex numberOfMatchesInString:pComponents[4] options:0 range:NSMakeRange(0,lAet)]
                 )
                 return [GCDWebServerErrorResponse responseWithClientError:404 message:@"ae titles should conform to DICOM UI datatype. '%@' doesn´t.",pComponents[4]];
             
             if (pCount==5)
             {
                 NSUInteger aeiIndex=[[orgisaeis objectForKey:pComponents[2]] indexOfObject:pComponents[4]];
                 if (aeiIndex==NSNotFound)
                     return [GCDWebServerErrorResponse responseWithClientError:404 message:@"aei '%@' not found",pComponents[4]];
//orgis/{oid}/aeis/{oid}
                 return [GCDWebServerDataResponse responseWithData:
                         [NSJSONSerialization dataWithJSONObject:
                          [NSArray arrayWithObject:
                           [
                            [orgtsaets objectForKey:
                             [orgtsArray objectAtIndex:orgiIndex]
                             ]
                            objectAtIndex:aeiIndex
                            ]
                           ] options:0 error:nil
                          ]
                          contentType:@"application/json"
                         ];
             }
             return [GCDWebServerErrorResponse responseWithClientError:404 message:@"too many segments in path '%@'",p];
         }
         ];

#pragma mark run
        [httpdicomServer runWithPort:pcsPort bonjourName:nil];
        
        // runloop
        _run = YES;
        void* handler = signal(SIGINT, _SignalHandler);
        if (handler != SIG_ERR) {
            while (_run) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, true);
            }
            
            if (httpdicomServer) {
                [httpdicomServer stop];
            }
            
            signal(SIGINT, handler);
        }
        
    }//end autorelease pool
    return success ? 0 : -1;
}
