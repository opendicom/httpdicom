#import "NSData+ZLIB.h"

#import "zlib.h"


@implementation NSData (ZLIB)

//Generates a lookup table for CRC calculations using a supplied polynomial.
//pTable: A pointer to pre-allocated memory to store the lookup table.
//poly: The polynomial to use in calculating the CRC table values.
void generateCRC32Table(uint32_t *pTable, uint32_t poly)
{
    for (uint32_t i = 0; i <= 255; i++)
    {
        uint32_t crc = i;
        
        for (uint32_t j = 8; j > 0; j--)
        {
            if ((crc & 1) == 1)
                crc = (crc >> 1) ^ poly;
            else
                crc >>= 1;
        }
        pTable[i] = crc;
    }
}

//Calculates the CRC32 of a data object using the default seed and polynomial.
-(uint32_t)crc32
{
    return [self crc32WithSeed:DEFAULT_SEED usingPolynomial:DEFAULT_POLYNOMIAL];
}

//Calculates the CRC32 of a data object using supplied seed and default polynomial.
//seed: The initial CRC value.
//returns CRC32 value.
-(uint32_t)crc32WithSeed:(uint32_t)seed
{
    return [self crc32WithSeed:seed usingPolynomial:DEFAULT_POLYNOMIAL];
}

//Calculates the CRC32 of a data object using a supplied polynomial and default seed.
//poly: The polynomial to use in calculating the CRC.
//returns CRC32 value.
-(uint32_t)crc32UsingPolynomial:(uint32_t)poly
{
    return [self crc32WithSeed:DEFAULT_SEED usingPolynomial:poly];
}

//Calculates the CRC32 of a data object using supplied polynomial and seed values.
//seed: The initial CRC value.
//poly: The polynomial to use in calculating the CRC.
//returns CRC32 value.
-(uint32_t)crc32WithSeed:(uint32_t)seed usingPolynomial:(uint32_t)poly
{
    uint32_t *pTable = malloc(sizeof(uint32_t) * 256);
    generateCRC32Table(pTable, poly);
    
    uint32_t crc    = seed;
    uint8_t *pBytes = (uint8_t *)[self bytes];
    uint32_t length = (uint32_t)[self length];
    
    while (length--)
    {
        crc = (crc>>8) ^ pTable[(crc & 0xFF) ^ *pBytes++];
    }
    
    free(pTable);
    return crc ^ 0xFFFFFFFFL;
}


-(NSData*)gzip
{
   return [self zipWithWindowBits:15+16 memLevel:8];
}

-(NSData*)rawzip
{
   return [self zipWithWindowBits:-15 memLevel:8];
}

-(NSData*)maxrawzip
{
   return [self zipWithWindowBits:-15 memLevel:9];
}

-(NSData*)zipWithWindowBits:(int)windowBits memLevel:(int)memLevel
{
   if (!self.length) return nil;//do not compress empty objects
   
   //C struct z_stream

   z_stream zlibStreamStruct;
   zlibStreamStruct.zalloc    = Z_NULL;                    // Set zalloc, zfree, and opaque to Z_NULL so
   zlibStreamStruct.zfree     = Z_NULL;                    // that when we call deflateInit2 they will be
   zlibStreamStruct.opaque    = Z_NULL;                    // updated to use default allocation functions.
   zlibStreamStruct.total_out = 0;                         // Total number of output bytes produced so far
   zlibStreamStruct.next_in   = (Bytef*)self.bytes;        // Pointer to input bytes
   zlibStreamStruct.avail_in  = (unsigned int)self.length; // Number of input bytes left to process

   /*
    deflateInit2() params:
    
    z_streamp strm
                     Pointer to a zstream struct
    int level
                     Must be Z_DEFAULT_COMPRESSION or 9 (best)
    int method
                     "Z_DEFLATED"
    int windowBits
                     Base two logarithm of the maximum window size (the size of the history buffer).
                     It should be in the range 8..15.
                     Add 16 to windowBits to write a simple gzip header and trailer (no file name, no extra data, no comment, no modification time (set to zero), no header crc, operating system will be set to 255 (unknown).
                     Negative values return raw deflated data (without any header or trailer at all)
    int memLevel
                     Amount of memory allocated for internal compression state.
                     1 uses minimum memory but is slow and reduces compressionratio;
                     9 uses maximum memory for optimal speed.
                     Default value is 8.
    int strategy
                     Z_DEFAULT_STRATEGY for normal data,
    */
   int initError = deflateInit2(
                                &zlibStreamStruct,
                                Z_DEFAULT_COMPRESSION,
                                Z_DEFLATED,
                                windowBits,
                                memLevel,
                                Z_DEFAULT_STRATEGY
                                );
   switch (initError)
   {
      case Z_OK:
         break;
         
      case Z_STREAM_ERROR:
         NSLog(@"%s: deflateInit2() Invalid parameter passed in to function: %s", __func__, zlibStreamStruct.msg);//warning
         return nil;
         
      case Z_MEM_ERROR:
         NSLog(@"%s: deflateInit2() Insufficient memory: %s", __func__, zlibStreamStruct.msg);
         return nil;//warning
         
      case Z_VERSION_ERROR:
         NSLog(@"%s: deflateInit2() The version of zlib.h and the version of the library linked do not match: %s", __func__, zlibStreamStruct.msg);//warning
         return nil;
         
      default:
         NSLog(@"%s: deflateInit2() unknown error: %s", __func__, zlibStreamStruct.msg);
         return nil;//warning
   }

   // destination buffer size must be at least 0.1% larger than avail_in plus 12 bytes.
   NSMutableData *compressedData = [NSMutableData dataWithLength:self.length * 1.01 + 12];

   int deflateStatus;
   do
   {
       // Store location where next byte should be put in next_out
       zlibStreamStruct.next_out = [compressedData mutableBytes] + zlibStreamStruct.total_out;
       
       // Calculate the amount of remaining free space in the output buffer
       // by subtracting the number of bytes that have been written so far
       // from the buffer's total capacity
       zlibStreamStruct.avail_out = (unsigned int)([compressedData length] - zlibStreamStruct.total_out);
       
       /* deflate() compresses as much data as possible, and stops/returns when
        the input buffer becomes empty or the output buffer becomes full. If
        deflate() returns Z_OK, it means that there are more bytes left to
        compress in the input buffer but the output buffer is full; the output
        buffer should be expanded and deflate should be called again (i.e., the
        loop should continue to rune). If deflate() returns Z_STREAM_END, the
        end of the input stream was reached (i.e.g, all of the data has been
        compressed) and the loop should stop. */
       deflateStatus = deflate(&zlibStreamStruct, Z_FINISH);
       
   } while ( deflateStatus == Z_OK );

   // Free data structures that were dynamically created for the stream.
   deflateEnd(&zlibStreamStruct);

   switch (deflateStatus)
   {
      case Z_STREAM_END:
         [compressedData setLength: zlibStreamStruct.total_out];
         return compressedData;
         
      case Z_ERRNO:
         NSLog(@"%s: deflateInit2() Error occured while reading file: ", __func__);//warning
         break;
         
      case Z_STREAM_ERROR:
         NSLog(@"%s: deflateInit2() The stream state was inconsistent (e.g., next_in or next_out was NULL): ", __func__);//warning
         break;
         
      case Z_DATA_ERROR:
         NSLog(@"%s: deflateInit2() The stream state was inconsistent (e.g., next_in or next_out was NULL): ", __func__);//warning
         break;
         
      case Z_MEM_ERROR:
         NSLog(@"%s: deflateInit2() The stream state was inconsistent (e.g., next_in or next_out was NULL): ", __func__);//warning
         break;
         
      case Z_BUF_ERROR:
         NSLog(@"%s: deflateInit2() The stream state was inconsistent (e.g., next_in or next_out was NULL): ", __func__);//warning
         break;
         
      case Z_VERSION_ERROR:
         NSLog(@"%s: deflateInit2() The stream state was inconsistent (e.g., next_in or next_out was NULL): ", __func__);//warning
         break;
         
      default:
         NSLog(@"%s: deflateInit2() The stream state was inconsistent (e.g., next_in or next_out was NULL): ", __func__);//warning
         break;
   }
   return nil;
}

@end
