//
//  NSData+PCS.m
//  httpdicom
//
//  Created by jacquesfauquex on 2016-10-12.
//  Copyright © 2016 ridi.salud.uy. All rights reserved.
//

#import "NSData+PCS.h"

@implementation NSData (PCS)

+(NSData*)jsonpCallback:(NSString*)callback withDictionary:(NSDictionary*)dictionary
{
    NSMutableData *jsonp=[NSMutableData data];
    [jsonp appendData:[callback dataUsingEncoding:NSUTF8StringEncoding]];
    [jsonp appendData:[@"(" dataUsingEncoding:NSUTF8StringEncoding]];
    [jsonp appendData:[NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil]];
    [jsonp appendData:[@");" dataUsingEncoding:NSUTF8StringEncoding]];
    return [NSData dataWithData:jsonp];
}

+(NSData*)jsonpCallback:(NSString*)callback forDraw:(NSString*)draw withErrorString:(NSString*)error
{
    //https://datatables.net/manual/server-side#Returned-data
    return [NSData jsonpCallback:callback withDictionary:@{@"draw":draw,@"recordsTotal":@0,@"recordsFiltered":@0,@"data":@[],@"error":error}];
}

@end
