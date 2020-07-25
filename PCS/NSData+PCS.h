#import <Foundation/Foundation.h>

@interface NSData (PCS)

//jsonp

+(NSData*)jsonpCallback:(NSString*)callback
         withDictionary:(NSDictionary*)dictionary;

+(NSData*)jsonpCallback:(NSString*)callback
                forDraw:(NSString*)draw
        withErrorString:(NSString*)error;


//mysql parsing
-(NSArray*)arrayOfRecordsOfStringUnitsEncoding:(NSStringEncoding)encoding orderedByUnitIndex:(NSUInteger)index decreasing:(BOOL)decreasing;
-(NSArray*)arrayOfRecordsOfStringUnitsEncoding:(NSStringEncoding)encoding stringUnitsPostProcessTitle:(NSString*)stringUnitsPostProcessTitle dictionary:(NSDictionary*)d orderedByUnitIndex:(NSUInteger)index decreasing:(BOOL)decreasing;

-(NSArray*)arrayOfStringUnitsForRecordRange:(NSRange)recordRange encoding:(NSStringEncoding)encoding stringUnitsPostProcessTitle:(NSString*)stringUnitsPostProcessTitle dictionary:(NSDictionary*)d;

//html5 form parsing
+(void)initPCS;
+(NSData*)recordSeparatorData;
+(NSData*)unitSeparatorData;

-(NSDictionary*)parseNamesValuesTypesInBodySeparatedBy:(NSData*)separator;

@end
