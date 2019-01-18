//
//  NSData+PCS.m
//  httpdicom
//
//  Created by jacquesfauquex on 2016-10-12.
//  Copyright © 2018 opendicom.com. All rights reserved.
//


#import "NSData+PCS.h"
#import "ODLog.h"

@implementation NSData (PCS)

static NSData *formDataPartName=nil;
static NSData *doubleQuotes=nil;
static NSData *contentType=nil;
static NSData *semicolon=nil;
static NSData *rnrn=nil;
static NSData *rn=nil;


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


+(void)initPCS
{
    formDataPartName=[@"Content-Disposition: form-data; name=\"" dataUsingEncoding:NSASCIIStringEncoding];
    doubleQuotes=[@"\"" dataUsingEncoding:NSASCIIStringEncoding];
    contentType=[@"Content-Type: " dataUsingEncoding:NSASCIIStringEncoding];
    semicolon=[@";" dataUsingEncoding:NSASCIIStringEncoding];
    rnrn=[@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
    rn=[@"\r\n" dataUsingEncoding:NSASCIIStringEncoding];
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

@end
