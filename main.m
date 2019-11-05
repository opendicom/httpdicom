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
#import "K.h" //constants
#import "ODLog.h" //log level init

#import "DRS.h"

int main(int argc, const char* argv[])
{
    @autoreleasepool
    {

        

NSArray *args=[[NSProcessInfo processInfo] arguments];
if ([args count]!=7)
{
    NSLog(@"syntax: httpdicom defaultpacsoid httpdicomport loglevel defaultTimezone deploydir tmpdir");
    return 1;
}
        
        
//args[5] deploypath
BOOL isDirectory=FALSE;
if (![[NSFileManager defaultManager]fileExistsAtPath:args[5] isDirectory:&isDirectory] || !isDirectory)
{
    LOG_ERROR(@"deploy folder does not exist");
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
ODLogLevel=(int)llindex;

 

#pragma mark K init

        
//arg [4] defaultTimezone
NSRegularExpression *TZRegex = [NSRegularExpression regularExpressionWithPattern:@"^[+-][0-2][0-9][0-5][0-9]$" options:0 error:NULL];
if (![TZRegex numberOfMatchesInString:args[4] options:0 range:NSMakeRange(0,[args[4] length])])
{
    NSLog(@"defaultTimezone (arg 4)format should be ^[+-][0-2][0-9][0-5][0-9]$");
    return 1;
}
else [K setDefaultTimezone:args[4]];

        

// /voc/scheme
NSDictionary *scheme=[NSDictionary dictionaryWithContentsOfFile:[args[5] stringByAppendingPathComponent:@"voc/scheme.xml"]];
if (!scheme) [K loadScheme:@{}];
else [K loadScheme:scheme];

        
// /voc/code
NSArray *codes=[[NSFileManager defaultManager]contentsOfDirectoryAtPath:[args[5] stringByAppendingPathComponent:@"voc/code/"] error:nil];
if (!codes) LOG_WARNING(@"no folder voc/code into deploy");
else if (![codes count]) LOG_WARNING(@"no code file registered");
else
{
     for (NSString *code in codes)
    {
        if ([code hasPrefix:@"."]) continue;
        [K loadCode:[NSDictionary dictionaryWithContentsOfFile:[[args[5] stringByAppendingPathComponent:@"voc/code"] stringByAppendingPathComponent:code]] forKey:[[code stringByDeletingPathExtension]stringByDeletingPathExtension]];
    }
    
}
        
// /voc/procedure
NSArray *procedures=[[NSFileManager defaultManager]contentsOfDirectoryAtPath:[args[5] stringByAppendingPathComponent:@"voc/procedure/"] error:nil];
if (!procedures) LOG_WARNING(@"no folder voc/procedure into deploy");
else if (![procedures count]) LOG_WARNING(@"no procedure file registered");
else
{
    for (NSString *procedure in procedures)
    {
        if ([procedure hasPrefix:@"."]) continue;
        [K loadProcedure:[NSDictionary dictionaryWithContentsOfFile:[[args[5] stringByAppendingPathComponent:@"voc/procedure"]stringByAppendingPathComponent:procedure]] forKey:[[procedure stringByDeletingPathExtension] stringByDeletingPathExtension]];

    }
}

        
// /voc/country (iso3166)
NSArray *iso3166ByCountry=[NSArray arrayWithContentsOfFile:[args[5] stringByAppendingPathComponent:@"voc/country.plist"]];
if (!iso3166ByCountry)
{
    LOG_ERROR(@"no folder voc/country.plist into deploy");
    return 1;
}
else [K loadIso3166ByCountry:iso3166ByCountry];

        

// /voc/personIDType (ica)
NSDictionary *personIDTypes=[NSDictionary dictionaryWithContentsOfFile:[args[5] stringByAppendingPathComponent:@"voc/personIDType.plist"]];
if (!personIDTypes)
{
    LOG_ERROR(@"no folder voc/personIDType.plist into deploy");
    return 1;
}
else [K loadPersonIDTypes:personIDTypes];


        
#pragma mark DRS params
       
//arg [1] defaultpacsoid
NSString *defaultpacsoid=args[1];
NSArray *pacs=[NSArray arrayWithContentsOfFile:
                    [[[args[5]
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
    NSString *sqlpath=[[[[args[5]
                          stringByAppendingPathComponent:@"sql/map"]
                         stringByAppendingPathComponent:sqlname]
                        stringByAppendingPathExtension:@"sql"]
                       stringByAppendingPathExtension:@"xml"];
    NSDictionary *sqlDict=[[NSDictionary alloc] initWithContentsOfFile:sqlpath];
    if (!sqlDict)
    {
        LOG_ERROR(@"%@ unavailable",sqlname);
        return 1;
    }
    
    [sqls setObject:sqlDict forKey:sqlname];
}


        

        
#pragma mark server init and run
       

        DRS *drs=[[DRS alloc] initWithSqls:sqls
                                      pacs:pacs
                                   drsport:port
                            defaultpacsoid:defaultpacsoid
                                 tmpDir:args[6]
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
