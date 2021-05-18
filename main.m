/*
 syntax:
 [0] httpdicom
 [1] defaultPacsOID (which is also the name of the file in deploy/device)
 [2] httpdicomport
 [3] loglevel [ DEBUG | VERBOSE | INFO | WARNING | ERROR | EXCEPTION]
 [4] defaultTimezone
 [5] deploy dir path
 [6] auditFiles dir path
 */

//
//  Created by jacquesfauquex on 2017-03-20.
//  Copyright © 2018 opendicom.com. All rights reserved.
//

#import <Foundation/Foundation.h>
 //log level init

#import "DRS.h"

int main(int argc, const char* argv[])
{
    @autoreleasepool
    {
       NSFileManager *defaultManager=[NSFileManager defaultManager];

        

NSArray *args=[[NSProcessInfo processInfo] arguments];
if ([args count]!=7)
{
    NSLog(@"syntax: httpdicom defaultpacsoid httpdicomport loglevel defaultTimezone deploydir tmpdir");
    return 1;
}
        
        
//args[5] deploypath
NSString *deploypath=[args[5] stringByExpandingTildeInPath];
BOOL isDirectory=FALSE;
if (![defaultManager fileExistsAtPath:deploypath isDirectory:&isDirectory] || !isDirectory)
{
    NSLog(@"deploy folder does not exist");
    return 1;
}

        
        
//arg [2] httpdicomport
long long port=[args[2]longLongValue];
if (port <1 || port>65535)
{
    NSLog(@"port should be between 1 and 65535");
    return 1;
}


        
#pragma mark log level
//arg [3] loglevel
NSUInteger llindex=[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:args[3]];
if (llindex==NSNotFound)
{
    NSLog(@"ODLogLevel (arg 1) should be one of [ DEBUG | VERBOSE | INFO | WARNING | ERROR | EXCEPTION ]");
    return 1;
}

 

#pragma mark K init

        
//arg [4] defaultTimezone
NSRegularExpression *TZRegex = [NSRegularExpression regularExpressionWithPattern:@"^[+-][0-2][0-9][0-5][0-9]$" options:0 error:NULL];
if (![TZRegex numberOfMatchesInString:args[4] options:0 range:NSMakeRange(0,[args[4] length])])
{
    NSLog(@"defaultTimezone (arg 4)format should be ^[+-][0-2][0-9][0-5][0-9]$");
    return 1;
}


        
#pragma mark DRS params
       
//arg [1] defaultpacsoid
NSString *defaultpacsoid=args[1];
NSArray *pacs=[NSArray arrayWithContentsOfFile:
                    [[[deploypath
                       stringByAppendingPathComponent:@"pacs"]
                      stringByAppendingPathComponent:defaultpacsoid]
                     stringByAppendingPathExtension:@"pacs.xml"]
                    ];

if (!pacs)
{
   NSLog(@"could not get contents of pacs/%@.pacs.xml",defaultpacsoid);
   return 1;
}

        
// /sql/map
NSMutableSet *sqlset=[NSMutableSet set];
for (NSDictionary *d in pacs)
{
    if (![d[@"sqlmap"] isEqualToString:@""]) [sqlset addObject:d[@"sqlmap"]];
}
NSMutableDictionary *sqls=[NSMutableDictionary dictionary];
for (NSString *sqlname in sqlset)
{
    NSString *sqlpath=[[[[deploypath
                          stringByAppendingPathComponent:@"sql/map"]
                         stringByAppendingPathComponent:sqlname]
                        stringByAppendingPathExtension:@"sql"]
                       stringByAppendingPathExtension:@"xml"];
    NSDictionary *sqlDict=[[NSDictionary alloc] initWithContentsOfFile:sqlpath];
    if (!sqlDict)
    {
       NSLog(@"%@ unavailable",sqlname);
        return 1;
    }
    
    [sqls setObject:sqlDict forKey:sqlname];
}


#pragma mark /TMP basic structure
       NSString *tmppath=[args[6] stringByExpandingTildeInPath];

       if (![defaultManager fileExistsAtPath:tmppath isDirectory:&isDirectory] || !isDirectory)
       {
          NSLog(@"tmp folder does not exist");
           return 1;
       }
       
       isDirectory=FALSE;
       NSString *queryPath=[tmppath stringByAppendingString:@"query"];
       if (![defaultManager fileExistsAtPath:queryPath isDirectory:&isDirectory] || !isDirectory)
       {
          [defaultManager createDirectoryAtPath:queryPath withIntermediateDirectories:false attributes:nil error:nil];
       }
       
       isDirectory=FALSE;
       NSString *matchPath=[tmppath stringByAppendingString:@"match"];
       if (![defaultManager fileExistsAtPath:matchPath isDirectory:&isDirectory] || !isDirectory)
       {
          [defaultManager createDirectoryAtPath:matchPath withIntermediateDirectories:false attributes:nil error:nil];
       }
       
       isDirectory=FALSE;
       NSString *dicomPath=[tmppath stringByAppendingString:@"dicom"];
       if (![defaultManager fileExistsAtPath:dicomPath isDirectory:&isDirectory] || !isDirectory)
       {
          [defaultManager createDirectoryAtPath:dicomPath withIntermediateDirectories:false attributes:nil error:nil];
       }
       
       isDirectory=FALSE;
       NSString *descartedPath=[tmppath stringByAppendingString:@"descarted"];
       if (![defaultManager fileExistsAtPath:descartedPath isDirectory:&isDirectory] || !isDirectory)
       {
          [defaultManager createDirectoryAtPath:descartedPath withIntermediateDirectories:false attributes:nil error:nil];
       }

        
#pragma mark server init and run
       

        DRS *drs=[[DRS alloc] initWithSqls:sqls
                                      pacs:pacs
                                   drsport:port
                            defaultpacsoid:defaultpacsoid
                                    tmpDir:tmppath
                  ];


        if (!drs)
        {
            NSLog(@"could not add DRS handlers to rest server");
            return 1;
        }

        NSError *error=nil;
        [drs startWithPort:port maxPendingConnections:16 error:&error];
        if (error != nil)
        {
            NSLog(@"could not start server on port:%lld. %@",port,[error description]);
            return 1;
        }

        while (true) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, true);
        }
        return 0;//OK
    }//end autorelease pool
}
