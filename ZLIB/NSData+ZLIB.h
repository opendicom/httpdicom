#import <Foundation/Foundation.h>

#define DEFAULT_POLYNOMIAL 0xEDB88320L
#define DEFAULT_SEED       0xFFFFFFFFL

@interface NSData (ZLIB)

-(uint32_t) crc32;
-(uint32_t) crc32WithSeed:(uint32_t)seed;
-(uint32_t) crc32UsingPolynomial:(uint32_t)poly;
-(uint32_t) crc32WithSeed:(uint32_t)seed usingPolynomial:(uint32_t)poly;

-(NSData*)gzip;
-(NSData*)rawzip;
-(NSData*)zipWithWindowBits:(int)windowBits;

@end
