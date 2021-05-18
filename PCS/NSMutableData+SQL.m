//
//  NSMutableData+SQL.m
//  httpdicom
//
//  Created by jacquesfauquex on 20171222.
//  Copyright © 2017 opendicom.com. All rights reserved.
//

#import "NSMutableData+SQL.h"


@implementation NSMutableData (SQL)

+(NSMutableData*)countTask:(NSString*)string
{
    if (!string || ![string length])
    {
       NSLog(@"[SQL] parameters of countTask (null or empty string");
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
       NSLog(@"[SQL] cannot launch countTask. Error: %@",[error description]);
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
    NSLog(@"[SQL] ERROR countTask terminationStatus: %d",[task terminationStatus]);//debug
    
    return resultData;
}

+(NSMutableData*)jsonTask:(NSString*)string sqlCharset:(NSStringEncoding)encoding
{
    if (!string || ![string length] || !encoding)
    {
       NSLog(@"[SQL] parameters of jsonTask (null or empty string or no sql charset");
        return nil;
    }
    
   NSLog(@"[SQL] encoding: [%lu] jsonTask: %@ ",(unsigned long)encoding, string);//debug
    
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
       NSLog(@"cannot launch jsonTask. Error: %@",[error description]);
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
   NSLog(@"ERROR jsontask terminationStatus: %d",[task terminationStatus]);//debug
    
    return resultData;
}

@end
