#import "DRS+zipped.h"
#import "NSData+PCS.h"
#import "NSURLSessionDataTask+DRS.h"
#import "zlib.h"
#import "zconf.h"

@implementation DRS (zipped)


+(RSResponse*)dcmzip:(RSRequest*)request
{
   NSData *ctad=[@"Content-Type: application/dicom\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
   
   //static immutable write
   uint32 zipLocalFileHeader=0x04034B50;
   uint16 zipVersion=0x0A;
   uint32 zipNameLength=0x28;
   uint32 zipFileHeader=0x02014B50;
   uint32 zipEndOfCentralDirectory=0x06054B50;

   
    //using NSURLComponents instead of RSRequest
    NSURLComponents *urlComponents=[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
    NSArray *pComponents=[urlComponents.path componentsSeparatedByString:@"/"];
    
    
   NSDictionary *destPacs=DRS.pacs[pComponents[2]];
   if (!destPacs) return [RSErrorResponse responseWithClientError:404 message:@"%@ [{pacs} not found]",request.path];
   
   LOG_VERBOSE(@"dcm.zip?%@",[urlComponents query]);
   
//series wadors
   {
      
      NSArray *seriesArray=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/series?%@",destPacs[@"qido"],request.URL.query]]] options:0 error:nil];
      
      
      __block NSMutableArray *wados=[NSMutableArray array];
      for (NSDictionary *dictionary in seriesArray)
      {
         //download series
         //00081190 UR RetrieveURL
         [wados addObject:((dictionary[@"00081190"])[@"Value"])[0]];
#pragma mark TODO correct proxy wadors...
      }
      LOG_DEBUG(@"%@",[wados description]);
      
      
      __block NSMutableData *wadors=[NSMutableData data];
      __block NSMutableData *boundary=[NSMutableData data];
      __block NSMutableData *directory=[NSMutableData data];
      __block NSRange wadorsRange=NSMakeRange(0,0);
      __block uint32 entryPointer=0;
      __block uint16 entriesCount=0;
      __block NSRange ctadRange=NSMakeRange(0,0);
      __block NSRange boundaryRange=NSMakeRange(0,0);
      
      /**
       *  The RSAsyncStreamBlock works like the RSStreamBlock
       *  except the streamed data can be returned at a later time allowing for
       *  truly asynchronous generation of the data.
       *
       *  The block must call "completionBlock" passing the new chunk of data when ready,
       *  an empty NSData when done, or nil on error and pass a NSError.
       *
       *  The block cannot call "completionBlock" more than once per invocation.
       */
      
      RSStreamedResponse* response = [RSStreamedResponse responseWithContentType:@"application/octet-stream" asyncStreamBlock:^(RSBodyReaderCompletionBlock completionBlock)
                                      {
                                         if (wadorsRange.length<1000)
                                         {
                                            LOG_INFO(@"need data. Remaining wadors:%lu",(unsigned long)wados.count);
                                            if (wados.count>0)
                                            {
#pragma mark cache policy + timeout to correct
                                               //request, response and error
                                               NSMutableURLRequest *wadorsRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:wados[0]] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
                                               //https://developer.apple.com/reference/foundation/nsurlrequestcachepolicy?language=objc
                                               //NSURLRequestReloadIgnoringCacheData
                                               [wadorsRequest setHTTPMethod:@"GET"];
                                               [wadorsRequest setValue:@"multipart/related;type=application/dicom" forHTTPHeaderField:@"Accept"];
                                               NSHTTPURLResponse *response=nil;
                                               //URL properties: expectedContentLength, MIMEType, textEncodingName
                                               //HTTP properties: statusCode, allHeaderFields


                                               NSError *error=nil;
                                               [wadors setData:[NSURLSessionDataTask sendSynchronousRequest:wadorsRequest returningResponse:&response error:&error]];
                                               if (response.statusCode==200)
                                               {
                                                  wadorsRange.location=0;
                                                  wadorsRange.length=[wadors length];
                                                  NSString *ctString=response.allHeaderFields[@"Content-Type"];
                                                  NSString *boundaryString=[@"\r\n--" stringByAppendingString:[ctString substringFromIndex:ctString.length-36]];
                                                  [boundary setData:[boundaryString dataUsingEncoding:NSUTF8StringEncoding]];
                                                  LOG_INFO(@"%@\r\n(%lu,%lu) boundary:%@",wados[0],(unsigned long)wadorsRange.location,(unsigned long)wadorsRange.length,boundaryString);
                                               }
                                               [wados removeObjectAtIndex:0];
                                            }
                                         }
                                         ctadRange=[wadors rangeOfData:ctad options:0 range:wadorsRange];
                                         boundaryRange=[wadors rangeOfData:boundary options:0 range:wadorsRange];
                                         if ((ctadRange.length>0) && (boundaryRange.length>0)) //chunk with new entry
                                         {
                                            //dcm
                                            unsigned long dcmLocation=ctadRange.location+ctadRange.length;
                                            unsigned long dcmLength=boundaryRange.location-dcmLocation;
                                            wadorsRange.location=boundaryRange.location+boundaryRange.length;
                                            wadorsRange.length=wadors.length-wadorsRange.location;
                                            
                                            NSString *dcmUUID=[[[NSUUID UUID]UUIDString]stringByAppendingPathExtension:@"dcm"];
                                            NSData *dcmName=[dcmUUID dataUsingEncoding:NSUTF8StringEncoding];
                                            //LOG_INFO(@"dcm (%lu bytes):%@",dcmLength,dcmUUID);
                                            
                                            __block NSMutableData *entry=[NSMutableData data];
                                            [entry appendBytes:&zipLocalFileHeader length:4];//0x04034B50
                                            [entry appendBytes:&zipVersion length:2];//0x000A
                                            [entry increaseLengthBy:8];//uint32 flagCompression,zipTimeDate
                                            
                                            NSData *dcmData=[wadors subdataWithRange:NSMakeRange(dcmLocation,dcmLength)];
                                            uint32 zipCrc32=[dcmData crc32];
                                            
                                            [entry appendBytes:&zipCrc32 length:4];
                                            [entry appendBytes:&dcmLength length:4];//zipCompressedSize
                                            [entry appendBytes:&dcmLength length:4];//zipUncompressedSize
                                            [entry appendBytes:&zipNameLength length:4];//0x28
                                            [entry appendData:dcmName];
                                            //extra param
                                            [entry appendData:dcmData];
                                            
                                            completionBlock(entry, nil);
                                            
                                            //directory
                                            [directory appendBytes:&zipFileHeader length:4];//0x02014B50
                                            [directory appendBytes:&zipVersion length:2];//0x000A
                                            [directory appendBytes:&zipVersion length:2];//0x000A
                                            [directory increaseLengthBy:8];//uint32 flagCompression,zipTimeDate
                                            [directory appendBytes:&zipCrc32 length:4];
                                            [directory appendBytes:&dcmLength length:4];//zipCompressedSize
                                            [directory appendBytes:&dcmLength length:4];//zipUncompressedSize
                                            [directory appendBytes:&zipNameLength length:4];//0x28
                                            /*
                                             uint16 zipFileCommLength=0x0;
                                             uint16 zipDiskStart=0x0;
                                             uint16 zipInternalAttr=0x0;
                                             uint32 zipExternalAttr=0x0;
                                             */
                                            [directory increaseLengthBy:10];
                                            
                                            [directory appendBytes:&entryPointer length:4];//offsetOfLocalHeader
                                            entryPointer+=dcmLength+70;
                                            entriesCount++;
                                            [directory appendData:dcmName];
                                            //extra param
                                         }
                                         else if (directory.length) //chunk with directory
                                         {
                                            //ZIP "end of central directory record"
                                            
                                            //uint32 zipEndOfCentralDirectory=0x06054B50;
                                            [directory appendBytes:&zipEndOfCentralDirectory length:4];
                                            [directory increaseLengthBy:4];//zipDiskNumber
                                            [directory appendBytes:&entriesCount length:2];//disk zipEntries
                                            [directory appendBytes:&entriesCount length:2];//total zipEntries
                                            uint32 directorySize=86 * entriesCount;
                                            [directory appendBytes:&directorySize length:4];
                                            [directory appendBytes:&entryPointer length:4];
                                            [directory increaseLengthBy:2];//zipCommentLength
                                            completionBlock(directory, nil);
                                            [directory setData:[NSData data]];
                                         }
                                         else completionBlock([NSData data], nil);//last chunck
                                         
                                      }];
      
      return response;
   }
}


@end
