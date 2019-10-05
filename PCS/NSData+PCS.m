#import "NSData+PCS.h"
#import "ODLog.h"
#import "zlib.h"

@implementation NSData (PCS)

#pragma mark jsonp

+(NSData*)jsonpCallback:(NSString*)callback
         withDictionary:(NSDictionary*)dictionary
{
    NSMutableData *jsonp=[NSMutableData data];
    [jsonp appendData:[callback dataUsingEncoding:NSUTF8StringEncoding]];
    [jsonp appendData:[@"(" dataUsingEncoding:NSUTF8StringEncoding]];
    [jsonp appendData:[NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil]];
    [jsonp appendData:[@");" dataUsingEncoding:NSUTF8StringEncoding]];
    return [NSData dataWithData:jsonp];
}

+(NSData*)jsonpCallback:(NSString*)callback
                forDraw:(NSString*)draw
        withErrorString:(NSString*)error
{
    //https://datatables.net/manual/server-side#Returned-data
    return [NSData jsonpCallback:callback withDictionary:@{@"draw":draw,@"recordsTotal":@0,@"recordsFiltered":@0,@"data":@[],@"error":error}];
}


#pragma mark - zip
//***********************************************************************************************************
//  Function      : generateCRC32Table
//
//  Description   : Generates a lookup table for CRC calculations using a supplied polynomial.
//
//  Declaration   : void generateCRC32Table(uint32_t *pTable, uint32_t poly);
//
//  Parameters    : pTable
//                    A pointer to pre-allocated memory to store the lookup table.
//
//                  poly
//                    The polynomial to use in calculating the CRC table values.
//
//  Return Value  : None.
//***********************************************************************************************************
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

//***********************************************************************************************************
//  Method        : crc32
//
//  Description   : Calculates the CRC32 of a data object using the default seed and polynomial.
//
//  Declaration   : -(uint32_t)crc32;
//
//  Parameters    : None.
//
//  Return Value  : The CRC32 value.
//***********************************************************************************************************
-(uint32_t)crc32
{
   return [self crc32WithSeed:DEFAULT_SEED usingPolynomial:DEFAULT_POLYNOMIAL];
}

//***********************************************************************************************************
//  Method        : crc32WithSeed:
//
//  Description   : Calculates the CRC32 of a data object using a supplied seed and default polynomial.
//
//  Declaration   : -(uint32_t)crc32WithSeed:(uint32_t)seed;
//
//  Parameters    : seed
//                    The initial CRC value.
//
//  Return Value  : The CRC32 value.
//***********************************************************************************************************
-(uint32_t)crc32WithSeed:(uint32_t)seed
{
   return [self crc32WithSeed:seed usingPolynomial:DEFAULT_POLYNOMIAL];
}

//***********************************************************************************************************
//  Method        : crc32UsingPolynomial:
//
//  Description   : Calculates the CRC32 of a data object using a supplied polynomial and default seed.
//
//  Declaration   : -(uint32_t)crc32UsingPolynomial:(uint32_t)poly;
//
//  Parameters    : poly
//                    The polynomial to use in calculating the CRC.
//
//  Return Value  : The CRC32 value.
//***********************************************************************************************************
-(uint32_t)crc32UsingPolynomial:(uint32_t)poly
{
   return [self crc32WithSeed:DEFAULT_SEED usingPolynomial:poly];
}

//***********************************************************************************************************
//  Method        : crc32WithSeed:usingPolynomial:
//
//  Description   : Calculates the CRC32 of a data object using supplied polynomial and seed values.
//
//  Declaration   : -(uint32_t)crc32WithSeed:(uint32_t)seed usingPolynomial:(uint32_t)poly;
//
//  Parameters    : seed
//                    The initial CRC value.
//
//                : poly
//                    The polynomial to use in calculating the CRC.
//
//  Return Value  : The CRC32 value.
//***********************************************************************************************************
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
   return [self zipWithWindowBits:15+16];
}

-(NSData*)rawzip
{
   return [self zipWithWindowBits:-15];
}
-(NSData*)zipWithWindowBits:(int)windowBits
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
                     Compression level.
                     Must be Z_DEFAULT_COMPRESSION,
                     or 0 no compresssion
                     or between 1 and 9 (1 = best speed, 9 = best compression)
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
                     Used to tune the compression algorithm.
                     Z_DEFAULT_STRATEGY for normal data,
                     Z_FILTERED for data produced by a filter (or predictor),
                     Z_HUFFMAN_ONLY to force Huffman encoding only (no string match)
    */
   int initError = deflateInit2(
                                &zlibStreamStruct,
                                Z_DEFAULT_COMPRESSION,
                                Z_DEFLATED,
                                windowBits,
                                8,
                                Z_DEFAULT_STRATEGY
                                );
   switch (initError)
   {
      case Z_OK:
         break;
         
      case Z_STREAM_ERROR:
         LOG_WARNING(@"%s: deflateInit2() Invalid parameter passed in to function: %s", __func__, zlibStreamStruct.msg);
         return nil;
         
      case Z_MEM_ERROR:
         LOG_WARNING(@"%s: deflateInit2() Insufficient memory: %s", __func__, zlibStreamStruct.msg);
         return nil;
         
      case Z_VERSION_ERROR:
         LOG_WARNING(@"%s: deflateInit2() The version of zlib.h and the version of the library linked do not match: %s", __func__, zlibStreamStruct.msg);
         return nil;
         
      default:
         LOG_WARNING(@"%s: deflateInit2() unknown error: %s", __func__, zlibStreamStruct.msg);
         return nil;
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
         LOG_WARNING(@"%s: deflateInit2() Error occured while reading file: ", __func__);
         break;
         
      case Z_STREAM_ERROR:
         LOG_WARNING(@"%s: deflateInit2() The stream state was inconsistent (e.g., next_in or next_out was NULL): ", __func__);
         break;
         
      case Z_DATA_ERROR:
         LOG_WARNING(@"%s: deflateInit2() The stream state was inconsistent (e.g., next_in or next_out was NULL): ", __func__);
         break;
         
      case Z_MEM_ERROR:
         LOG_WARNING(@"%s: deflateInit2() The stream state was inconsistent (e.g., next_in or next_out was NULL): ", __func__);
         break;
         
      case Z_BUF_ERROR:
         LOG_WARNING(@"%s: deflateInit2() The stream state was inconsistent (e.g., next_in or next_out was NULL): ", __func__);
         break;
         
      case Z_VERSION_ERROR:
         LOG_WARNING(@"%s: deflateInit2() The stream state was inconsistent (e.g., next_in or next_out was NULL): ", __func__);
         break;
         
      default:
         LOG_WARNING(@"%s: deflateInit2() The stream state was inconsistent (e.g., next_in or next_out was NULL): ", __func__);
         break;
   }
   return nil;
}



#pragma mark - mysql parsing

-(NSArray*)arrayOfRecordsOfStringUnitsEncoding:(NSStringEncoding)encoding orderedByUnitIndex:(NSUInteger)index decreasing:(BOOL)decreasing
{
   NSUInteger dataLength=[self length];
   if (dataLength==0)return @[];
   
   NSMutableArray *recordArray=[NSMutableArray array];
   NSRange dataRange=NSMakeRange(0, dataLength);
   NSRange currentRecordSeparator=NSMakeRange(0,0);
   while (currentRecordSeparator.location+currentRecordSeparator.length < dataLength)
   {
      currentRecordSeparator=[self rangeOfData:recordSeparator options:0 range:dataRange];
      if (currentRecordSeparator.location==NSNotFound) return nil;//error

      [recordArray addObject:[self arrayOfStringUnitsForRecordRange:NSMakeRange(dataRange.location,currentRecordSeparator.location - dataRange.location) encoding:encoding]];
      
      dataRange=NSMakeRange(currentRecordSeparator.location + currentRecordSeparator.length, dataLength - currentRecordSeparator.location - currentRecordSeparator.length);
   }
   
   if ((index != NSNotFound) && ([recordArray count]>1))
   {
      if (decreasing) [recordArray sortWithOptions:0 usingComparator:^NSComparisonResult(id obj1, id obj2) {
          return [obj2[index] compare:obj1[index] options:(NSCaseInsensitiveSearch | NSNumericSearch | NSDiacriticInsensitiveSearch)];}];
      else [recordArray sortWithOptions:0 usingComparator:^NSComparisonResult(id obj1, id obj2) {
         return [obj1[index] compare:obj2[index] options:(NSCaseInsensitiveSearch | NSNumericSearch | NSDiacriticInsensitiveSearch)];}];
   }
   
   return [NSArray arrayWithArray:recordArray];
}
      
-(NSArray*)arrayOfStringUnitsForRecordRange:(NSRange)recordRange encoding:(NSStringEncoding)encoding
{
   if (recordRange.length==0) return @[];
   
   NSRange remainingRecordRange=recordRange;
   
   NSMutableArray *unitArray=[NSMutableArray array];

   NSRange currentUnitSeparator=NSMakeRange(remainingRecordRange.location,0);
   while ((currentUnitSeparator.location + currentUnitSeparator.length) < (recordRange.location + recordRange.length))
   {
      currentUnitSeparator=[self rangeOfData:unitSeparator options:0 range:remainingRecordRange];
      if (currentUnitSeparator.location!=NSNotFound)
      {
         [unitArray addObject:[[NSString alloc]initWithData:[self subdataWithRange:NSMakeRange(remainingRecordRange.location,currentUnitSeparator.location-remainingRecordRange.location)] encoding:encoding]];
         remainingRecordRange=NSMakeRange(currentUnitSeparator.location + currentUnitSeparator.length, recordRange.location + recordRange.length - currentUnitSeparator.location - currentUnitSeparator.length);
      }
      else
      {
         [unitArray addObject:[[NSString alloc]initWithData:[self subdataWithRange:NSMakeRange(remainingRecordRange.location,remainingRecordRange.length)] encoding:encoding]];
          
         remainingRecordRange=NSMakeRange(remainingRecordRange.location + remainingRecordRange.length, 0);
      }
   }
   return [NSArray arrayWithArray:unitArray];

}



#pragma mark - hltml5 multipart/form-data parsing

static NSData *formDataPartName=nil;
static NSData *doubleQuotes=nil;
static NSData *contentType=nil;
static NSData *semicolon=nil;
static NSData *rnrn=nil;
static NSData *rn=nil;

static NSData *recordSeparator=nil;
static NSData *unitSeparator=nil;

+(void)initPCS
{
    formDataPartName=[@"Content-Disposition: form-data; name=\"" dataUsingEncoding:NSASCIIStringEncoding];
    doubleQuotes=[@"\"" dataUsingEncoding:NSASCIIStringEncoding];
    contentType=[@"Content-Type: " dataUsingEncoding:NSASCIIStringEncoding];
    semicolon=[@";" dataUsingEncoding:NSASCIIStringEncoding];
    rnrn=[@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
    rn=[@"\r\n" dataUsingEncoding:NSASCIIStringEncoding];
   uint16 recordSeparatorNewLine=0x0A1E;
   recordSeparator=[NSData dataWithBytes:&recordSeparatorNewLine length:2];
   uint16 unitSeparatorVerticalBar=0x7C1F;
   unitSeparator=[NSData dataWithBytes:&unitSeparatorVerticalBar length:2];

}

-(NSDictionary*)parseNamesValuesTypesInBodySeparatedBy:(NSData*)separator
{
    //return datatype is array,because a param name may be repeated
    
    NSMutableArray *names=[NSMutableArray array];
    NSMutableArray *values=[NSMutableArray array];
    NSMutableArray *types=[NSMutableArray array];
    //there is a separator at the beginning and at the end
    NSRange containerRange=NSMakeRange(0,self.length);
    NSRange separatorRange=[self rangeOfData:separator options:0 range:containerRange];
    NSUInteger componentStart=separatorRange.location + separatorRange.length + 2;//2...0D0A
    containerRange.location=componentStart;
    containerRange.length=self.length - componentStart;
    
    //skip 0->first separator
    separatorRange=[self rangeOfData:separator options:0 range:containerRange];
    
    while (separatorRange.location != NSNotFound)
    {
        NSMutableData *dataChunk=[NSMutableData dataWithData:[self subdataWithRange:NSMakeRange(componentStart,separatorRange.location - componentStart - 4)]];//4... 0D0A
        
        //add object to types
        NSString *type;
        NSRange contentTypeRange=[dataChunk rangeOfData:contentType options:0 range:NSMakeRange(0,[dataChunk length])];
        if (contentTypeRange.location==NSNotFound) type=@"";
        else
        {
            NSUInteger start=contentTypeRange.location+contentTypeRange.length;
            NSRange semicolonRange=[dataChunk rangeOfData:semicolon options:0 range:NSMakeRange(start,[dataChunk length]-start)];
            NSRange rnRange=[dataChunk rangeOfData:rn options:0 range:NSMakeRange(start,[dataChunk length]-start)];
            if (   semicolonRange.location==NSNotFound
                || (    rnRange.location!=NSNotFound
                    &&  rnRange.location < semicolonRange.location)
                ) type=[[NSString alloc]initWithData:[dataChunk subdataWithRange:NSMakeRange(start,rnRange.location-start)] encoding:NSUTF8StringEncoding];
            else type=[[NSString alloc]initWithData:[dataChunk subdataWithRange:NSMakeRange(start,semicolonRange.location-start)] encoding:NSUTF8StringEncoding];
        }
        [types addObject:type];
        
        //remove everything until name
        NSRange formDataPartNameRange=[dataChunk rangeOfData:formDataPartName options:0 range:NSMakeRange(0,[dataChunk length])];
        if (!formDataPartNameRange.length) break;
        [dataChunk replaceBytesInRange:NSMakeRange(0,formDataPartNameRange.location + formDataPartNameRange.length) withBytes:NULL length:0];
        
        //add object to names
        NSRange doubleQuotesRange=[dataChunk rangeOfData:doubleQuotes options:0 range:NSMakeRange(0,[dataChunk length])];
        [names addObject:[[NSString alloc]initWithData:[dataChunk subdataWithRange:NSMakeRange(0,doubleQuotesRange.location)] encoding:NSUTF8StringEncoding]];
        
        //remove everything until rnrn
        NSRange rnrnRange=[dataChunk rangeOfData:rnrn options:0 range:NSMakeRange(0,[dataChunk length])];
        [dataChunk replaceBytesInRange:NSMakeRange(0,rnrnRange.location + rnrnRange.length) withBytes:NULL length:0];

        //add object to values
        if (  ![type length]
            || [type hasPrefix:@"text"]
            || [type hasPrefix:@"application/json"]
            || [type hasPrefix:@"application/dicom+json"]
            || [type hasPrefix:@"application/xml"]
            || [type hasPrefix:@"application/xml+json"]
            )[values addObject:[[NSString alloc]initWithData:dataChunk encoding:NSUTF8StringEncoding]];
        else [values addObject:[dataChunk base64EncodedStringWithOptions:0]];
        
        componentStart=separatorRange.location + separatorRange.length + 2;//2...0D0A
        containerRange.location=componentStart;
        containerRange.length=self.length - componentStart;
        
        separatorRange=[self rangeOfData:separator options:0 range:containerRange];
    }
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSArray arrayWithArray:names],
            @"names",
            [NSArray arrayWithArray:values],
            @"values",
            [NSArray arrayWithArray:types],
            @"types",
            nil];
}

@end
