#import "NSData+PCS.h"
#import "ODLog.h"

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


#pragma mark - mysql parsing

-(NSArray*)arrayOfRecordsOfStringUnitsEncoding:(NSStringEncoding)encoding orderedByUnitIndex:(NSUInteger)index decreasing:(BOOL)decreasing
{
   return [self arrayOfRecordsOfStringUnitsEncoding:encoding stringUnitsPostProcessTitle:nil orderedByUnitIndex:index decreasing:decreasing];
}

-(NSArray*)arrayOfRecordsOfStringUnitsEncoding:(NSStringEncoding)encoding stringUnitsPostProcessTitle:(NSString*)stringUnitsPostProcessTitle orderedByUnitIndex:(NSUInteger)index decreasing:(BOOL)decreasing
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

      [recordArray addObject:[self arrayOfStringUnitsForRecordRange:NSMakeRange(dataRange.location,currentRecordSeparator.location - dataRange.location) encoding:encoding stringUnitsPostProcessTitle:stringUnitsPostProcessTitle]];
      
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
      
-(NSArray*)arrayOfStringUnitsForRecordRange:(NSRange)recordRange encoding:(NSStringEncoding)encoding stringUnitsPostProcessTitle:(NSString*)stringUnitsPostProcessTitle
{
   /*
    post processing may be placed in various places
    */
   if (recordRange.length==0) return @[];
   
   NSRange remainingRecordRange=recordRange;
   
   NSMutableArray *unitArray=[NSMutableArray array];

   NSRange currentUnitSeparator=NSMakeRange(remainingRecordRange.location,0);
   while ((currentUnitSeparator.location + currentUnitSeparator.length) < (recordRange.location + recordRange.length))
   {
      //first to before last string unit
      currentUnitSeparator=[self rangeOfData:unitSeparator options:0 range:remainingRecordRange];
      if (currentUnitSeparator.location!=NSNotFound)
      {
         //replace true by a negation of special case
         if (
                 (!stringUnitsPostProcessTitle)
             || ![stringUnitsPostProcessTitle length]
             || true
             )
         [unitArray addObject:[[NSString alloc]initWithData:[self subdataWithRange:NSMakeRange(remainingRecordRange.location,currentUnitSeparator.location-remainingRecordRange.location)] encoding:encoding]];
         else
         {
#pragma mark place holder for post processing first string units
         }
         
         remainingRecordRange=NSMakeRange(currentUnitSeparator.location + currentUnitSeparator.length, recordRange.location + recordRange.length - currentUnitSeparator.location - currentUnitSeparator.length);
      }
      else
      {
         //last string unit
         
         if (
                 (!stringUnitsPostProcessTitle)
             || ![stringUnitsPostProcessTitle length]
             || ![stringUnitsPostProcessTitle isEqualToString:@"lastTextUnitHEX2ASCII"]
             )
            //default case: no postprocessing
            [unitArray addObject:[[NSString alloc]initWithData:[self subdataWithRange:NSMakeRange(remainingRecordRange.location,remainingRecordRange.length)] encoding:encoding]];
         else
         {
#pragma mark postprocessing last string unit
            
            if ([stringUnitsPostProcessTitle isEqualToString:@"lastTextUnitHEX2ASCII"])
            {
               NSMutableString *decodedString=[NSMutableString string];
               uint16 asciiCode;
               BOOL numbersOnly=(remainingRecordRange.length > 1);
               for (NSUInteger i=remainingRecordRange.location;i < remainingRecordRange.location + remainingRecordRange.length ; i+=2)
               {
                  [self getBytes:&asciiCode range:NSMakeRange(i,2)];
                  if (asciiCode / 30 != 1) numbersOnly=false;
                  [decodedString appendString:[NSString stringWithFormat:@"%c", asciiCode]];
               }
               
               if (numbersOnly) [unitArray addObject:decodedString];
               else [unitArray addObject:@"-1"];
            }
         }
          
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
   uint16 recordSeparatorNewLine=0x0A7C;
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
