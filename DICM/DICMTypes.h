@import Foundation;

@interface DICMTypes : NSObject

@property (class, nonatomic, readonly) NSRegularExpression   *DARegex;
@property (class, nonatomic, readonly) NSRegularExpression   *SHRegex;
@property (class, nonatomic, readonly) NSRegularExpression   *UIRegex;
@property (class, nonatomic, readonly) NSRegularExpression   *TZRegex;

+(NSDate*)dateFromDAString:(NSString*)string;
+(NSString*)DAStringFromDate:(NSDate*)date;
+(NSDate*)dateFromTMString:(NSString*)string;
+(NSString*)TMStringFromDate:(NSDate*)date;
+(NSDate*)dateFromDTString:(NSString*)string;
+(NSString*)DTStringFromDate:(NSDate*)date;
+(NSString*)ASSinceDate:(NSDate*)sinceDate untilDate:(NSDate*)untilDate;
+(NSString*)ASSinceDA:(NSString*)sinceDA untilDA:(NSString*)untilDA;
+(bool)isSingleUIString:(NSString*)string;
+(bool)isSingleSHString:(NSString*)string;
+(bool)isSingleDAString:(NSString*)string;

@end
