#import "mllpSend.h"

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
