#import <Foundation/Foundation.h>

@interface NSMutableData (DICM)

+ (id)dataWithEmptyDICMProlog;
- (id)initWithEmptyDICMProlog;

- (void)appendDICMSignature;

+ (NSMutableData*)DICMDataGroup2WithDICMDictionary:(NSDictionary*)dictionary;
- (id)initDICMDataGroup2WithDICMDictionary:(NSDictionary*)dictionary;

+ (NSMutableData*)DICMDataWithDICMDictionary:(NSDictionary*)dictionary bulkdataBaseURI:(NSURL*)bulkdataBaseURI;
- (id)initDICMDataWithDICMDictionary:(NSDictionary*)dictionary bulkdataBaseURI:(NSURL*)bulkdataBaseURI;

- (NSStringEncoding)appendDICMAttribute:(NSString*)tagPath withObject:(id)object bulkdataBaseURI:(NSURL*)bulkdataBaseURI stringEncoding:(NSStringEncoding)stringEncoding;

@end
