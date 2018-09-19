//
//  sql.m
//  httpdicom
//
//  Created by jacquesfauquex on 20180119.
//  Copyright © 2018 ridi.salud.uy. All rights reserved.
//

#import "sql.h"

@implementation sql
@dynamic devices;
@dynamic drsport;

-(id)init{
    return nil;
}

-(id)initWithCodesystems:(NSDictionary*)codesystems
                   codes:(NSDictionary*)codes
                 iso3166:(NSArray*)iso3166
           personIDTypes:(NSDictionary*)personIDTypes
                    sqls:(NSDictionary*)sqls
                 devices:(NSDictionary*)devices
                 drsport:(long long)drsport
                 timeout:(NSTimeInterval)timeout
                loglevel:(int)loglevel
{
    self = [super init];
    if(self) {
        _codesystems=codesystems;
        _codes=codes;
        _iso3166=iso3166;
        _personIDTypes=personIDTypes;
        _sqls=sqls;
        _drsport=drsport;
        _timeout=timeout;
        _devices=devices;
        ODLogLevel=loglevel;
    }
    return nil;
}

#pragma mark -
#pragma mark setters and getters

@end
