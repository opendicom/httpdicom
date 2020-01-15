#import "DICMTypes.h"

static NSISO8601DateFormatter *ISO8601yyyyMMdd;
static NSISO8601DateFormatter *ISO8601yyyyMMddhhmmss;

static NSDate *dateZero;
static NSDateFormatter *yyyyFormatter=nil;
static NSDateFormatter *MMFormatter=nil;
static NSDateFormatter *ddFormatter=nil;
static NSDateFormatter *DTFormatter=nil;
static NSDateFormatter *DAFormatter=nil;
static NSDateFormatter *TMFormatter=nil;


static NSRegularExpression *_CSRegex=nil;
static NSRegularExpression *_CSPipeListRegex=nil;
static NSRegularExpression *_DARegex=nil;
static NSRegularExpression *_DAISORegex=nil;
static NSRegularExpression *_SHRegex=nil;
static NSRegularExpression *_UIRegex=nil;
static NSRegularExpression *_UIPipeListRegex=nil;
static NSRegularExpression *_TZRegex=nil;
static NSRegularExpression *_DA0or1PipeRegex=nil;

static NSRegularExpression *_noSingleQuoteRegex=nil;

@implementation DICMTypes


+ (void) initialize {
    ISO8601yyyyMMdd=[[NSISO8601DateFormatter alloc]init];
    ISO8601yyyyMMdd.formatOptions=NSISO8601DateFormatWithFullDate;
    ISO8601yyyyMMddhhmmss=[[NSISO8601DateFormatter alloc]init];
    ISO8601yyyyMMddhhmmss.formatOptions=NSISO8601DateFormatWithFullDate|NSISO8601DateFormatWithFullTime;

    dateZero=[ISO8601yyyyMMdd dateFromString:@"00000101"];
    yyyyFormatter = [[NSDateFormatter alloc] init];
    [yyyyFormatter setDateFormat:@"yyyy"];
    MMFormatter = [[NSDateFormatter alloc] init];
    [MMFormatter setDateFormat:@"MM"];
    ddFormatter = [[NSDateFormatter alloc] init];
    [ddFormatter setDateFormat:@"dd"];
    DTFormatter = [[NSDateFormatter alloc] init];
    [DTFormatter setDateFormat:@"yyyyMMddHHmmss"];
    DAFormatter = [[NSDateFormatter alloc] init];
    [DAFormatter setDateFormat:@"yyyyMMdd"];
    TMFormatter = [[NSDateFormatter alloc] init];
    [TMFormatter setDateFormat:@"HHmmss"];

   _CSRegex = [NSRegularExpression regularExpressionWithPattern:@"^[0-9A-Z\\s_]{1,16}$" options:0 error:NULL];
   _CSPipeListRegex = [NSRegularExpression regularExpressionWithPattern:@"^[0-9A-Z\\s_]{1,16}(//|[0-9A-Z\\s_]{1,16})*$" options:0 error:NULL];
   _TZRegex = [NSRegularExpression regularExpressionWithPattern:@"^[+-][0-2][0-9][0-5][0-9]$" options:0 error:NULL];
   _UIRegex = [NSRegularExpression regularExpressionWithPattern:@"^[1-9](\\d)*(\\.0|\\.[1-9](\\d)*)*$" options:0 error:NULL];
   _UIPipeListRegex = [NSRegularExpression regularExpressionWithPattern:@"^[1-9](\\d)*(\\.0|\\.[1-9](\\d)*)*(\\|[1-9](\\d)*(\\.0|\\.[1-9](\\d)*)*)*$" options:0 error:NULL];
   _SHRegex = [NSRegularExpression regularExpressionWithPattern:@"^(?:\\s*)([^\\r\\n\\f\\t']*[^\\r\\n\\f\\t\\s])(?:\\s*)$" options:0 error:NULL];//' is prohibited in order to allow mysql regex usage
   _DARegex = [NSRegularExpression regularExpressionWithPattern:@"^(19|20)\\d\\d(01|02|03|04|05|06|07|08|09|10|11|12)(01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31)$" options:0 error:NULL];
   _DAISORegex = [NSRegularExpression regularExpressionWithPattern:@"^(19|20)\\d\\d-(01|02|03|04|05|06|07|08|09|10|11|12)-(01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31)$" options:0 error:NULL];
   _DA0or1PipeRegex = [NSRegularExpression regularExpressionWithPattern:@"^(\\|(19|20)\\d\\d-(01|02|03|04|05|06|07|08|09|10|11|12)-(01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31))|((19|20)\\d\\d-(01|02|03|04|05|06|07|08|09|10|11|12)-(01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31)(\\|((19|20)\\d\\d-(01|02|03|04|05|06|07|08|09|10|11|12)-(01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31))?)?)$" options:0 error:NULL];
   
   _noSingleQuoteRegex = [NSRegularExpression regularExpressionWithPattern:@"((?!').)*" options:0 error:NULL];
}

+(NSDate*)dateFromDAString:(NSString*)string
{
    return [DAFormatter dateFromString:string];
}

+(NSString*)DAStringFromDate:(NSDate*)date
{
    return [DAFormatter stringFromDate:date];
}

+(NSString*)DAStringFromDAISOString:(NSString*)string
{
   return [NSString stringWithFormat:@"%@%@%@",
           [string substringWithRange:NSMakeRange(0,4)],
           [string substringWithRange:NSMakeRange(5,2)],
           [string substringWithRange:NSMakeRange(8,2)]
           ];
}

+(NSDate*)dateFromTMString:(NSString*)string
{
    return [TMFormatter dateFromString:string];
}

+(NSString*)TMStringFromDate:(NSDate*)date
{
    return [TMFormatter stringFromDate:date];
}

+(NSString*)TMStringFromTMISOString:(NSString*)string
{
   return [NSString stringWithFormat:@"%@%@%@",
           [string substringWithRange:NSMakeRange(0,2)],
           [string substringWithRange:NSMakeRange(3,2)],
           [string substringWithRange:NSMakeRange(5,2)]
           ];
}

+(NSDate*)dateFromDTString:(NSString*)string
{
    return [DTFormatter dateFromString:string];
}

+(NSString*)DTStringFromDate:(NSDate*)date
{
    return [DTFormatter stringFromDate:date];
}

+(NSString*)ASSinceDate:(NSDate*)sinceDate untilDate:(NSDate*)untilDate
{
    if (!sinceDate || !untilDate) return @"????";
    NSTimeInterval seconds=[untilDate timeIntervalSinceDate:sinceDate];
    NSDate *sinceDateZero=[dateZero dateByAddingTimeInterval:seconds];

    int years=[[yyyyFormatter stringFromDate:sinceDateZero] intValue];
    if( years > 1) return [NSString stringWithFormat: @"%03dY", years];

    int months=[[MMFormatter stringFromDate:sinceDateZero] intValue];
    if (years || months > 8) return [NSString stringWithFormat: @"%03dM", months + (years * 12)];
    
    if (months > 2) return [NSString stringWithFormat: @"%03dW", (int)(seconds / 604800)];
    
    return [NSString stringWithFormat: @"%03dD", (int)(seconds / 86400)];
}

+(NSString*)ASSinceDA:(NSString*)sinceDA untilDA:(NSString*)untilDA
{
    NSDate *sinceDate=[ISO8601yyyyMMdd dateFromString:sinceDA];
    NSDate *untilDate=[ISO8601yyyyMMdd dateFromString:untilDA];
    if (!sinceDate || !untilDate) return @"????";
    return [DICMTypes ASSinceDate:sinceDate untilDate:untilDate];
}

#pragma mark - getters

+(NSRegularExpression*)CSRegex            { return _CSRegex;}
+(NSRegularExpression*)CSPipeListRegex    { return _CSPipeListRegex;}
+(NSRegularExpression*)DARegex            { return _DARegex;}
+(NSRegularExpression*)DA0or1PipeRegex    { return _DA0or1PipeRegex;}
+(NSRegularExpression*)DAISORegex         { return _DAISORegex;}
+(NSRegularExpression*)SHRegex            { return _SHRegex;}
+(NSRegularExpression*)UIRegex            { return _UIRegex;}
+(NSRegularExpression*)UIPipeListRegex    { return _UIPipeListRegex;}
+(NSRegularExpression*)TZRegex            { return _TZRegex;}

+(NSRegularExpression*)noSingleQuoteRegex { return _noSingleQuoteRegex;}

+(bool)isSingleUIString:(NSString*)string
{
   return (bool)[DICMTypes.UIRegex numberOfMatchesInString:string options:0 range:NSMakeRange(0,[string length])];
}

+(bool)isSingleCSString:(NSString*)string
{
   return (bool)[DICMTypes.CSRegex numberOfMatchesInString:string options:0 range:NSMakeRange(0,[string length])];
}

+(bool)isCSPipeListString:(NSString*)string
{
   return (bool)[DICMTypes.CSPipeListRegex numberOfMatchesInString:string options:0 range:NSMakeRange(0,[string length])];
}

+(bool)isUIPipeListString:(NSString*)string
{
   return (bool)[DICMTypes.UIPipeListRegex numberOfMatchesInString:string options:0 range:NSMakeRange(0,[string length])];
}

+(bool)isSingleSHString:(NSString*)string
{
   return (bool)[DICMTypes.SHRegex numberOfMatchesInString:string options:0 range:NSMakeRange(0,[string length])];
}

+(bool)isSingleDAString:(NSString*)string
{
   return (bool)[DICMTypes.DARegex numberOfMatchesInString:string options:0 range:NSMakeRange(0,[string length])];
}

+(bool)isSingleDAISOString:(NSString*)string;
{
   return (bool)[DICMTypes.DAISORegex numberOfMatchesInString:string options:0 range:NSMakeRange(0,[string length])];
}

+(bool)isDA0or1PipeString:(NSString*)string
{
   return (bool)[DICMTypes.DA0or1PipeRegex numberOfMatchesInString:string options:0 range:NSMakeRange(0,[string length])];
}

+(bool)hasNoSingleQuote:(NSString*)string
{
   return (bool)[DICMTypes.noSingleQuoteRegex numberOfMatchesInString:string options:0 range:NSMakeRange(0,[string length])];
}

@end
