#import <Foundation/Foundation.h>

@interface NSData (PCS)

//jsonp

+(NSData*)jsonpCallback:(NSString*)callback
         withDictionary:(NSDictionary*)dictionary;

+(NSData*)jsonpCallback:(NSString*)callback
                forDraw:(NSString*)draw
        withErrorString:(NSString*)error;

//zip

#define DEFAULT_POLYNOMIAL 0xEDB88320L
#define DEFAULT_SEED       0xFFFFFFFFL

-(uint32_t) crc32;
-(uint32_t) crc32WithSeed:(uint32_t)seed;
-(uint32_t) crc32UsingPolynomial:(uint32_t)poly;
-(uint32_t) crc32WithSeed:(uint32_t)seed usingPolynomial:(uint32_t)poly;

-(NSData*)gzip;
-(NSData*)rawzip;
-(NSData*)zipWithWindowBits:(int)windowBits;

//mysql parsing
-(NSArray*)arrayOfRecordsOfStringUnitsEncoding:(NSStringEncoding)encoding orderedByUnitIndex:(NSUInteger)index decreasing:(BOOL)decreasing;
-(NSArray*)arrayOfStringUnitsForRecordRange:(NSRange)recordRange encoding:(NSStringEncoding)encoding;

//html5 form parsing
+(void)initPCS;
-(NSDictionary*)parseNamesValuesTypesInBodySeparatedBy:(NSData*)separator;

@end
