//
//  NSString+PCS.m
//  httpdicom
//
//  Created by jacquesfauquex on 2016-10-11.
//  Copyright © 2016 "opendicom" Jesros S.A. All rights reserved.
//

#import "NSString+PCS.h"

@implementation NSString (PCS)

+(NSString*)regexDicomString:(NSString*)dicomString withFormat:(NSString*)formatString
{
    NSString *regex;
    regex = [dicomString stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    regex = [regex stringByReplacingOccurrencesOfString:@"{" withString:@"\\{"];
    regex = [regex stringByReplacingOccurrencesOfString:@"}" withString:@"\\}"];
    regex = [regex stringByReplacingOccurrencesOfString:@"?" withString:@"\\?"];
    regex = [regex stringByReplacingOccurrencesOfString:@"+" withString:@"\\+"];
    regex = [regex stringByReplacingOccurrencesOfString:@"[" withString:@"\\["];
    regex = [regex stringByReplacingOccurrencesOfString:@"(" withString:@"\\("];
    regex = [regex stringByReplacingOccurrencesOfString:@")" withString:@"\\)"];
    regex = [regex stringByReplacingOccurrencesOfString:@"^" withString:@"\\^"];
    regex = [regex stringByReplacingOccurrencesOfString:@"$" withString:@"\\$"];
    regex = [regex stringByReplacingOccurrencesOfString:@"|" withString:@"\\|"];
    regex = [regex stringByReplacingOccurrencesOfString:@"/" withString:@"\\/"];
    regex = [regex stringByReplacingOccurrencesOfString:@"." withString:@"\\."];
    regex = [regex stringByReplacingOccurrencesOfString:@"*" withString:@".*"];
    regex = [regex stringByReplacingOccurrencesOfString:@"_" withString:@"."];
    return [NSString stringWithFormat:formatString,regex];
}


+(NSString*)mysqlEscapedFormat:(NSString*)format fieldString:(NSString*)field valueString:(NSString*)value;
{
    NSString *escapedValue;
    escapedValue = [value stringByReplacingOccurrencesOfString:@"?" withString:@"_"];
    escapedValue = [escapedValue stringByReplacingOccurrencesOfString:@"*" withString:@"%"];
    return [NSString stringWithFormat:format,field,escapedValue];
}

@end


