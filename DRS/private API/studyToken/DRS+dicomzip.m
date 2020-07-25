#import "DRS+dicomzip.h"
#import "DRS+studyToken.h"
#import "NSData+PCS.h"
#import "NSData+ZLIB.h"
#import "NSURLSessionDataTask+DRS.h"
#import "zlib.h"
#import "zconf.h"

//#import "DRS+datatablesStudy.h"
#import "ResponseWadouri.h"

@implementation DRS (dicomzip)

+(void)addSeriesPathFor:(NSDictionary*)d toArray:(NSMutableArray*)mutableArray;
{
   NSFileManager *defaultManager=[NSFileManager defaultManager];
   NSDictionary *devDict=DRS.pacs[d[@"devOID"]];
      
   //sql
   NSDictionary *sqlcredentials=@{devDict[@"sqlcredentials"]:devDict[@"sqlpassword"]};
   NSString *sqlprolog=devDict[@"sqlprolog"];
   NSDictionary *sqlDictionary=DRS.sqls[devDict[@"sqlmap"]];

   //sql instance inits
   NSString *instanceANDSOPClass=nil;
   if (d[@"SOPClassRegexString"]) instanceANDSOPClass=
   [NSString stringWithFormat:
    sqlDictionary[@"ANDinstanceSOPClass"],
    d[@"SOPClassRegexString"]
   ];
   else instanceANDSOPClass=@"";

   NSString *instanceANDSOPClassOff=nil;
   if (d[@"SOPClassOffRegexString"]) instanceANDSOPClassOff=
   [NSString stringWithFormat:
    sqlDictionary[@"ANDinstanceSOPClassOff"],
    d[@"SOPClassOffRegexString"]
   ];
   else instanceANDSOPClassOff=@"";


   
   //prepare regex level series
    NSRegularExpression *SeriesInstanceUIDRegex = nil;
    NSRegularExpression *SeriesNumberRegex = nil;
    NSRegularExpression *SeriesDescriptionRegex = nil;
    NSRegularExpression *ModalityRegex = nil;
    NSRegularExpression *SOPClassRegex = nil;
    NSRegularExpression *SOPClassOffRegex = nil;
    if (d[@"hasSeriesFilter"])
    {
        if (d[@"SeriesInstanceUIDRegexString"]) SeriesInstanceUIDRegex=[NSRegularExpression regularExpressionWithPattern:d[@"SeriesInstanceUIDRegexString"] options:0 error:NULL];
        if (d[@"SeriesNumberRegexString"]) SeriesNumberRegex=[NSRegularExpression regularExpressionWithPattern:d[@"SeriesNumberRegexString"] options:0 error:NULL];
        if (d[@"SeriesDescriptionRegexString"]) SeriesDescriptionRegex=[NSRegularExpression regularExpressionWithPattern:d[@"SeriesDescriptionRegexString"] options:0  error:NULL];
        if (d[@"ModalityRegexString"]) ModalityRegex=[NSRegularExpression regularExpressionWithPattern:d[@"ModalityRegexString"] options:0 error:NULL];
        if (d[@"SOPClassRegexString"]) SOPClassRegex=[NSRegularExpression regularExpressionWithPattern:d[@"SOPClassRegexString"] options:0 error:NULL];
        if (d[@"SOPClassOffRegexString"]) SOPClassOffRegex = [NSRegularExpression regularExpressionWithPattern:d[@"SOPClassOffRegexString"] options:0 error:NULL];
    }


   
#pragma mark E from datatables plist
   NSArray *studyPlist=[NSArray arrayWithContentsOfFile:d[@"devOIDPLISTPath"]];

    for (NSArray *study in studyPlist)
    {
#pragma mark loop E
       
      NSMutableData *seriesData=[NSMutableData data];
      if (execUTF8Bash(sqlcredentials,
                        [NSString stringWithFormat:
                         sqlDictionary[@"S"],
                         sqlprolog,
                         study[20],
                         @"",
                         sqlRecordThirteenUnits
                         ],
                        seriesData)
          !=0)
      {
         LOG_ERROR(@"zip series db error");
         continue;
      }
      NSArray *seriesSqlPropertiesArray=[seriesData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:3 decreasing:NO];//NSUTF8StringEncoding
       
       NSArray *seriesSelected=nil;
       if (d[@"SeriesInstanceUIDRegexString"])
       {
           NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF[1] == %@", d[@"SeriesInstanceUIDRegexString"]];
           seriesSelected=[seriesSqlPropertiesArray filteredArrayUsingPredicate:predicate];
       }
       else seriesSelected=seriesSqlPropertiesArray;


       for (NSArray *seriesSqlProperties in seriesSelected)
       {
          //add it? (SOPClass = yes)
         NSString *SOPClass=SOPCLassOfReturnableSeries(
          sqlcredentials,
          sqlDictionary[@"Ici4S"],
          sqlprolog,
          seriesSqlProperties,
          SeriesInstanceUIDRegex,
          SeriesNumberRegex,
          SeriesDescriptionRegex,
          ModalityRegex,
          SOPClassRegex,
          SOPClassOffRegex
         );
         
         if (SOPClass)
         {
            
#pragma mark add path to seriesPaths
                        
            NSMutableData *fileData=[NSMutableData data];
            if (execUTF8Bash(sqlcredentials,
                             [NSString stringWithFormat:
                              sqlDictionary[@"file"],
                              sqlprolog,
                              seriesSqlProperties[0],
                              @"",
                              @""
                              ],
                             fileData)
                !=0)
            {
               LOG_ERROR(@"zip file db error");
               continue;
            }
            
            NSString *originalFilePath=[[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
            
            //filesystem/file string object for key seriesInstanceUID
            //we use the URL style, so that the same code to be used with wado
            if (originalFilePath)
            {
                NSArray *parts=[[originalFilePath substringToIndex:originalFilePath.length -1]componentsSeparatedByString:@"\t"];
                NSString *mountPoint=(d[@"mountPoints"])[parts[0]];
                
               [mutableArray addObject:
                   [mountPoint stringByAppendingPathComponent:[parts[1] stringByDeletingLastPathComponent]]
                ];
            }
         }//end if SOPClass
      }// end for each S
   }
}


+(RSResponse*)dicomzipStreamForSeriesPaths:(NSArray*)array
{
   NSFileManager *fileManager=[NSFileManager defaultManager];

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
   
   /*
    stream
    2* series files
    3  directory
    */
   __block NSError *error=nil;
   __block uint32 entryPointer=0;
   __block uint16 c=0;
   __block NSMutableData *d=[NSMutableData data];
   __block NSMutableArray *paths=[NSMutableArray arrayWithArray:array];

   return [RSStreamedResponse responseWithContentType:@"application/octet-stream" asyncStreamBlock:^(RSBodyReaderCompletionBlock completionBlock)
  {
      if ([paths count])
      {
          NSMutableData *e=[NSMutableData data];
           __block NSString *seriesPath=paths[0];
           //loop the series files
           for (NSString *fileName in [fileManager contentsOfDirectoryAtPath:seriesPath error:&error])
           {
              __block NSString *filePath=[seriesPath stringByAppendingPathComponent:fileName];
              __block NSData *fileData=[NSData dataWithContentsOfFile:filePath];
              if (!fileData) LOG_ERROR(@"could not get %@",filePath);
              else
              {
                 unsigned long fileLength=(unsigned long)[fileData length];
                 NSString *dcmUUID=[[[NSUUID UUID]UUIDString]stringByAppendingPathExtension:@"dcm"];
                 NSData *dcmName=[dcmUUID dataUsingEncoding:NSUTF8StringEncoding];
                 //LOG_INFO(@"dcm (%lu bytes):%@",dcmLength,dcmUUID);
                 
                 [e appendBytes:&zipLocalFileHeader length:4];//0x04034B50
                 [e appendBytes:&zipVersion length:2];//0x000A
                 [e increaseLengthBy:8];//uint32 flagCompression,zipTimeDate
                 uint32 zipCrc32=[fileData crc32];
                 [e appendBytes:&zipCrc32 length:4];
                 [e appendBytes:&fileLength length:4];//zipCompressedSize
                 [e appendBytes:&fileLength length:4];//zipUncompressedSize
                 [e appendBytes:&zipNameLength length:4];//0x28
                 [e appendData:dcmName];
                 //extra param
                 [e appendData:fileData];
                 
                 
                 [d appendBytes:&zipFileHeader length:4];//0x02014B50
                 [d appendBytes:&zipVersion length:2];//0x000A
                 [d appendBytes:&zipVersion length:2];//0x000A
                 [d increaseLengthBy:8];//uint32 flagCompression,zipTimeDate
                 [d appendBytes:&zipCrc32 length:4];
                 [d appendBytes:&fileLength length:4];//zipCompressedSize
                 [d appendBytes:&fileLength length:4];//zipUncompressedSize
                 [d appendBytes:&zipNameLength length:4];//0x28
                 /*
                  uint16 zipFileCommLength=0x0;
                  uint16 zipDiskStart=0x0;
                  uint16 zipInternalAttr=0x0;
                  uint32 zipExternalAttr=0x0;
                  */
                 [d increaseLengthBy:10];
                 
                 [d appendBytes:&entryPointer length:4];//offsetOfLocalHeader
                 entryPointer+=fileLength+70;
                 c++;
                 [d appendData:dcmName];//extra param
              }
           }
           
#pragma mark send series entry
           completionBlock(e, nil);
          
        [paths removeObjectAtIndex:0];
      }
      else if ([d length])
      {
         //ZIP "end of central directory record"
         
         //uint32 zipEndOfCentralDirectory=0x06054B50;
         [d appendBytes:&zipEndOfCentralDirectory length:4];
         [d increaseLengthBy:4];//zipDiskNumber
         [d appendBytes:&c length:2];//disk zipEntries
         [d appendBytes:&c length:2];//total zipEntries
         uint32 directorySize=86 * c;
         [d appendBytes:&directorySize length:4];
         [d appendBytes:&entryPointer length:4];
         [d increaseLengthBy:2];//zipCommentLength
         completionBlock(d, nil);
         [d setData:[NSData data]];

      }
      else completionBlock([NSData data], nil);//last chunk
   }];
            
}

@end

/*

 #pragma mark cache policy + timeout to correct
            //request, response and error
            NSMutableURLRequest *eRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:wados[0]] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
            //https://developer.apple.com/reference/foundation/nsurlrequestcachepolicy?language=objc
            //NSURLRequestReloadIgnoringCacheData
            [eRequest setHTTPMethod:@"GET"];
            [eRequest setValue:@"multipart/related;type=application/dicom" forHTTPHeaderField:@"Accept"];
            NSHTTPURLResponse *response=nil;
            //URL properties: expectedContentLength, MIMEType, textEncodingName
            //HTTP properties: statusCode, allHeaderFields

 */

