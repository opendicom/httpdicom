//
//  NSMutableData+SQL.m
//  httpdicom
//
//  Created by jacquesfauquex on 20171222.
//  Copyright © 2017 opendicom.com. All rights reserved.
//

#import "NSMutableData+SQL.h"
#import "ODLog.h"

@implementation NSMutableData (SQL)

+(NSMutableData*)countTask:(NSString*)string
{
    if (!string || ![string length])
    {
        LOG_ERROR(@"[SQL] parameters of countTask (null or empty string");
        return nil;
    }
    
    NSTask *task=[[NSTask alloc]init];
    [task setLaunchPath:@"/bin/bash"];
    [task setArguments:@[@"-s"]];
    NSPipe *writePipe = [NSPipe pipe];
    NSFileHandle *writeHandle = [writePipe fileHandleForWriting];
    [task setStandardInput:writePipe];
    
    NSPipe* readPipe = [NSPipe pipe];
    NSFileHandle *readingFileHandle=[readPipe fileHandleForReading];
    [task setStandardOutput:readPipe];
    [task setStandardError:readPipe];
    
    NSError *error=nil;
    if (![task launchAndReturnError:&error])
    {
        LOG_ERROR(@"[SQL] cannot launch countTask. Error: %@",[error description]);
        return nil;
    };
    
    [writeHandle writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
    [writeHandle closeFile];
    
    //pipping is necesary for very large answers
    NSMutableData *resultData=[NSMutableData data];
    NSData *dataPiped = nil;
    while((dataPiped = [readingFileHandle availableData]) && [dataPiped length])
    {
        [resultData appendData:dataPiped];
    }
    [task waitUntilExit];
    LOG_DEBUG(@"[SQL] ERROR countTask terminationStatus: %d",[task terminationStatus]);
    
    return resultData;
}

+(NSMutableData*)jsonTask:(NSString*)string sqlCharset:(NSStringEncoding)encoding
{
    if (!string || ![string length] || !encoding)
    {
        LOG_ERROR(@"[SQL] parameters of jsonTask (null or empty string or no sql charset");
        return nil;
    }
    
    LOG_DEBUG(@"[SQL] encoding: [%lu] jsonTask: %@ ",(unsigned long)encoding, string);
    
    NSTask *task=[[NSTask alloc]init];
    [task setLaunchPath:@"/bin/bash"];
    [task setArguments:@[@"-s"]];
    NSPipe *writePipe = [NSPipe pipe];
    NSFileHandle *writeHandle = [writePipe fileHandleForWriting];
    [task setStandardInput:writePipe];
    
    NSPipe* readPipe = [NSPipe pipe];
    NSFileHandle *readingFileHandle=[readPipe fileHandleForReading];
    [task setStandardOutput:readPipe];
    [task setStandardError:readPipe];
    
    NSError *error=nil;
    if (![task launchAndReturnError:&error])
    {
        LOG_ERROR(@"cannot launch jsonTask. Error: %@",[error description]);
        return nil;
    };
    
    [writeHandle writeData:[string dataUsingEncoding:encoding]];
    [writeHandle closeFile];
    
    //pipping is necesary for very large answers
    NSMutableData *resultData=[NSMutableData data];
    NSData *dataPiped = nil;
    while((dataPiped = [readingFileHandle availableData]) && [dataPiped length])
    {
        [resultData appendData:dataPiped];
    }
    [task waitUntilExit];
    LOG_DEBUG(@"ERROR jsontask terminationStatus: %d",[task terminationStatus]);
    
    
    
    /*
     //execute sql select
     NSMutableData *mutableData=[NSMutableData countTask:sqlCount ];
     if (!mutableData) [RSErrorResponse responseWithClientError:404 message:@"[qido] %@ did not answer to sql count",oid];
     
     //sqlCharset:(NSStringEncoding)loopDevice[@"sqlstringencoding"]
     //response can be almost empty
     //in this case we remove lost ']'
     if ([mutableData length]<10) return [RSDataResponse responseWithData:emptymatchRoot contentType:@"application/json"];
     
     //db response may be in latin1
     NSStringEncoding charset=(NSStringEncoding)[loopDevice[@"sqlstringencoding"] longLongValue ];
     if (charset!=4 && charset!=5) return [RSErrorResponse responseWithClientError:404 message:@"unknown sql charset : %lu",(unsigned long)charset];
     
     if (charset==5) //latin1
     {
     NSString *latin1String=[[NSString alloc]initWithData:mutableData encoding:NSISOLatin1StringEncoding];
     [mutableData setData:[latin1String dataUsingEncoding:NSUTF8StringEncoding]];
     }
     
     NSError *error=nil;
     NSMutableArray *arrayOfDicts=[NSJSONSerialization JSONObjectWithData:mutableData options:0 error:&error];
     if (error) return [RSErrorResponse responseWithClientError:404 message:@"bad qido sql result : %@",[error description]];
     
     //formato JSON qido
     NSMutableArray *qidoResponseArray=[NSMutableArray array];
     for (NSDictionary *dict in arrayOfDicts)
     {
     NSMutableDictionary *object=[NSMutableDictionary dictionary];
     for (NSString *key in dict)
     {
     NSDictionary *attrDesc=qidokey[key];
     NSMutableDictionary *attrInst=[NSMutableDictionary dictionary];
     if ([attrDesc[@"vr"] isEqualToString:@"PN"])
     [attrInst setObject:@[@{@"Alphabetic":dict[key]}] forKey:@"Value"];
     else if ([attrDesc[@"vr"] isEqualToString:@"DA"]) [attrInst setObject:@[[dict[key] dcmDaFromDate]] forKey:@"Value"];
     else [attrInst setObject:@[dict[key]] forKey:@"Value"];
     //TODO add other cases, like TM, DT, etc...
     
     [attrInst setObject:attrDesc[@"vr"] forKey:@"vr"];
     [object setObject:attrInst forKey:attrDesc[@"tag"]];
     }
     [qidoResponseArray addObject:object];
     }
*/
    
    return resultData;
}

@end
