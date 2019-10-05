// @author Clint Harris (www.clintharris.net)
//http://deusty.blogspot.com/2007/07/gzip-compressiondecompression.html
//deflateInit2() can be used to make zlib generate a compressed file with gzip headers

#import <Foundation/Foundation.h>
#import "zlib.h"

@interface LFCGzipUtility : NSObject
{
}
                                                                              
//@param pUncompressedData memory buffer of bytes to compress
//@return Compressed data as an NSData object

+(NSData*) gzipData: (NSData*)pUncompressedData;

@end
