#import "mllpSend.h"

/*
 https://stackoverflow.com/questions/34828257/how-to-find-if-hl7-segment-has-ended-or-not-if-carriage-return-is-not-present
 
 delimiters:
 
 (1) Segment delimiter: 0x0D (or 13 in ASCII), which is the Carriage Return. It's the segment separator, as per HL7v2 standard;
 (2) Message start delimiter: 0x0B (ASCII 11 - Vertical Tab);
 (3) Message finish delimiter: 0x1C0D. My guess is that this value is supposed to be the concatenation of 0x1C (ASCII 28 - File Separator) and 0x0D (ASCII 13 - Carriage Return).
 
 With #1 you get HL7v2 messages standard-compliant. With #2 and #3 you are able to clearly define delimiters for the message so that it can be processed and parsed later by some custom processor.
 */


const uint8 SB=0x0B;
const uint8 EB=0x1C;
const uint8 CR=0x0D;

/*
@"ORC|NW|2013424203649|||||^^^201304242036^^M~EDIUM||20130424203649||||||||MUCAM\rOBR||987861||^^^kdkdkdff^TAC DE CRANEO^CT||||||||||||||987861|1|||||CT|||^^^201111301500\rZDS|987861"
 */

@implementation mllpSend


+(bool)sendIP:ipString
         port:portString
      message:(NSString*)message
 stringEncoding:(NSStringEncoding)stringEncoding
        payload:(NSMutableString*)payload
{
   //create stream structures
   NSInputStream *inputStream=nil;
   NSOutputStream *outputStream=nil;
   [NSStream getStreamsToHostWithName:ipString port:[portString intValue] inputStream:&inputStream outputStream: &outputStream];
   if (outputStream==nil)
   {
      [payload appendFormat:@"can not create output stream to %@:%@",ipString,portString];
      return false;
   }
   if (inputStream==nil)
   {
      [payload appendFormat:@"can not create input stream to %@:%@",ipString,portString];
      return false;
   }
   
   //send message
   [outputStream open];
   NSMutableData *bytes=[NSMutableData data];
   [bytes appendBytes:&SB length:1];
   [bytes appendData:[message dataUsingEncoding:stringEncoding]];
   [bytes appendBytes:&EB length:1];
   [bytes appendBytes:&CR length:1];
   [outputStream write:[bytes bytes] maxLength:[bytes length]];
   
   /*
    unsigned long streamStatus=[outputStream streamStatus];
    NSStreamStatusNotOpen = 0,
    NSStreamStatusOpening = 1,
    NSStreamStatusOpen = 2,
    NSStreamStatusReading = 3,
    NSStreamStatusWriting = 4,
    NSStreamStatusAtEnd = 5,
    NSStreamStatusClosed = 6,
    NSStreamStatusError = 7
    */
   NSError *streamError=[outputStream streamError];
   [outputStream close];
   outputStream = nil;
   if (streamError)
   {
      [payload appendFormat:@">%@:%@\r\n%@",ipString,portString,[streamError description]];
      return false;
   }
   
   //receive payload
   [inputStream open];
   long len = 1024;
   uint8_t buf[len];
   len = [inputStream read:buf maxLength:len];
   streamError=[inputStream streamError];
   [inputStream close];
   inputStream = nil;
   if(streamError)
   {
      [payload appendFormat:@"<%@:%@\r\n%@",ipString,portString,[streamError description]];
      return false;
   }
   
   [payload appendString:[[NSString alloc] initWithData:[NSData dataWithBytes:&buf length:len] encoding:NSASCIIStringEncoding]];
   return true;
}


+(bool)sendIP:ipString
         port:portString
      messageData:(NSData*)messageData
      payloadData:(NSMutableData*)payloadData
{
    //create stream structures
    NSInputStream *inputStream=nil;
    NSOutputStream *outputStream=nil;
    [NSStream getStreamsToHostWithName:ipString port:[portString intValue] inputStream:&inputStream outputStream: &outputStream];
    if (outputStream==nil)
    {
        [payloadData appendData:[@"can not create output stream" dataUsingEncoding:NSASCIIStringEncoding]];
        return false;
    }
    if (inputStream==nil)
    {
        [payloadData appendData:[@"can not create input stream" dataUsingEncoding:NSASCIIStringEncoding]];
        return false;
    }
    
    //send message
    [outputStream open];
    NSMutableData *bytes=[NSMutableData data];
    [bytes appendBytes:&SB length:1];
    [bytes appendData:messageData];
    [bytes appendBytes:&EB length:1];
    [bytes appendBytes:&CR length:1];
    [outputStream write:[bytes bytes] maxLength:[bytes length]];
    
    /*
     unsigned long streamStatus=[outputStream streamStatus];
     NSStreamStatusNotOpen = 0,
     NSStreamStatusOpening = 1,
     NSStreamStatusOpen = 2,
     NSStreamStatusReading = 3,
     NSStreamStatusWriting = 4,
     NSStreamStatusAtEnd = 5,
     NSStreamStatusClosed = 6,
     NSStreamStatusError = 7
     */
    NSError *streamError=[outputStream streamError];
    [outputStream close];
    outputStream = nil;
    if (streamError)
    {
        [payloadData  appendData:[[streamError description] dataUsingEncoding:NSASCIIStringEncoding]];
        return false;
    }
    
    //receive payload
    [inputStream open];
    long len = 1024;
    uint8_t buf[len];
    len = [inputStream read:buf maxLength:len];
    streamError=[inputStream streamError];
    [inputStream close];
    inputStream = nil;
    if(streamError)
    {
        [payloadData  appendData:[[streamError description] dataUsingEncoding:NSASCIIStringEncoding]];
        return false;
    }
    
    [payloadData appendData:[NSData dataWithBytes:&buf length:len]];
    return true;
}

@end
