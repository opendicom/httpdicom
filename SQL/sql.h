//
//  sql.h
//  httpdicom
//
//  Created by jacquesfauquex on 20180119.
//  Copyright © 2018 ridi.salud.uy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface sql : NSObject
{
    NSDictionary* _codesystems;
    NSDictionary* _codes;
    NSArray* _iso3166;
    NSDictionary* _personIDTypes;
    NSDictionary* _sqls;
    NSDictionary* _devices;
    long long _drsport;
    NSTimeInterval _timeout;
    int loglevel;
}

@property (class, nonatomic, readonly) NSDictionary          *devices;
@property (class, nonatomic, readonly, assign) long long      drsport;



@end
