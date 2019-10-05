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
-(NSArray*)arrayOfStringUnitsForRecordRange:(NSRange)recordRange encoding:(NSStringEncoding)encoding;

//html5 form parsing
+(void)initPCS;
-(NSDictionary*)parseNamesValuesTypesInBodySeparatedBy:(NSData*)separator;

@end
