@import Foundation;

@interface DICMTypes : NSObject

@property (class, nonatomic, readonly) NSRegularExpression   *CSRegex;
@property (class, nonatomic, readonly) NSRegularExpression   *CSPipeListRegex;
@property (class, nonatomic, readonly) NSRegularExpression   *DARegex;
@property (class, nonatomic, readonly) NSRegularExpression   *DAISORegex;
@property (class, nonatomic, readonly) NSRegularExpression   *DA0or1PipeRegex;
@property (class, nonatomic, readonly) NSRegularExpression   *SHRegex;
@property (class, nonatomic, readonly) NSRegularExpression   *UIRegex;
@property (class, nonatomic, readonly) NSRegularExpression   *UIPipeListRegex;
@property (class, nonatomic, readonly) NSRegularExpression   *TZRegex;

@property (class, nonatomic, readonly) NSRegularExpression   *noSingleQuoteRegex;

+(NSDate*)dateFromDAString:(NSString*)string;
+(NSString*)DAStringFromDate:(NSDate*)date;
+(NSString*)DAStringFromDAISOString:(NSString*)string;
+(NSDate*)dateFromTMString:(NSString*)string;
+(NSString*)TMStringFromDate:(NSDate*)date;
+(NSString*)TMStringFromTMISOString:(NSString*)string;
+(NSDate*)dateFromDTString:(NSString*)string;
+(NSString*)DTStringFromDate:(NSDate*)date;
+(NSString*)ASSinceDate:(NSDate*)sinceDate untilDate:(NSDate*)untilDate;
+(NSString*)ASSinceDA:(NSString*)sinceDA untilDA:(NSString*)untilDA;
+(bool)isSingleUIString:(NSString*)string;
+(bool)isUIPipeListString:(NSString*)string;
+(bool)isSingleSHString:(NSString*)string;
+(bool)isSingleDAString:(NSString*)string;
+(bool)isSingleDAISOString:(NSString*)string;
+(bool)isDA0or1PipeString:(NSString*)string;
+(bool)isSingleCSString:(NSString*)string;
+(bool)isCSPipeListString:(NSString*)string;

+(bool)hasNoSingleQuote:(NSString*)string;
@end
