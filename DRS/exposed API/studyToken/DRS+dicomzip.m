#import "DRS+dicomzip.h"
#import "DRS+studyToken.h"

//#import "DRS+datatablesStudy.h"
#import "ResponseWadouri.h"

@implementation DRS (dicomzip)

+(void)dicomzipSql4d:(NSDictionary*)d
{
#pragma mark init
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

   
   //get
   NSUInteger getTypeIndex=[@[@"file",@"folder",@"wado",@"wadors",@"cget",@"cmove"] indexOfObject:devDict[@"get"]];

   
   //prepare regex level series
    NSRegularExpression *SeriesInstanceUIDRegex = nil;
    NSRegularExpression *SeriesNumberRegex = nil;
    NSRegularExpression *SeriesDescriptionRegex = nil;
    NSRegularExpression *ModalityRegex = nil;
    NSRegularExpression *SOPClassRegex = nil;
    NSRegularExpression *SOPClassOffRegex = nil;
    if (d[@"hasSeriesRestriction"])
    {
        if (d[@"SeriesInstanceUIDRegexString"]) SeriesInstanceUIDRegex=[NSRegularExpression regularExpressionWithPattern:d[@"SeriesInstanceUIDRegexString"] options:0 error:NULL];
        if (d[@"SeriesNumberRegexString"]) SeriesNumberRegex=[NSRegularExpression regularExpressionWithPattern:d[@"SeriesNumberRegexString"] options:0 error:NULL];
        if (d[@"SeriesDescriptionRegexString"]) SeriesDescriptionRegex=[NSRegularExpression regularExpressionWithPattern:d[@"SeriesDescriptionRegexString"] options:0  error:NULL];
        if (d[@"ModalityRegexString"]) ModalityRegex=[NSRegularExpression regularExpressionWithPattern:d[@"ModalityRegexString"] options:0 error:NULL];
        if (d[@"SOPClassRegexString"]) SOPClassRegex=[NSRegularExpression regularExpressionWithPattern:d[@"SOPClassRegexString"] options:0 error:NULL];
        if (d[@"SOPClassOffRegexString"]) SOPClassOffRegex = [NSRegularExpression regularExpressionWithPattern:d[@"SOPClassOffRegexString"] options:0 error:NULL];
    }

   
#pragma mark E from datatables plist
   NSArray *studyPlist=[NSArray arrayWithContentsOfFile:[d[@"devOIDPath"]stringByAppendingPathExtension:@"plist"]];
    
    NSArray *studiesSelected=nil;
    if (d[@"StudyInstanceUIDRegexpString"])
    {
        NSPredicate *studyPredicate = [NSPredicate predicateWithFormat:@"SELF[16] == %@", d[@"StudyInstanceUIDRegexpString"]];
        studiesSelected=[studyPlist filteredArrayUsingPredicate:studyPredicate];
    }
    else studiesSelected=studyPlist;
    for (NSArray *study in studiesSelected)
    {
#pragma mark loop E
       
       NSString *EPath=[d[@"devOIDPath"] stringByAppendingPathComponent:study[16]];//E
      
#pragma mark series loop
      NSMutableData *seriesData=[NSMutableData data];
      if (execUTF8Bash(sqlcredentials,
                        [NSString stringWithFormat:
                         sqlDictionary[@"S"],
                         sqlprolog,
                         [study[20] stringValue],
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
              NSString *SPath=[EPath stringByAppendingPathComponent:seriesSqlProperties[1]];
             NSError *error=nil;
             if (![defaultManager fileExistsAtPath:SPath])
             {
                 if (![defaultManager createDirectoryAtPath:SPath withIntermediateDirectories:YES attributes:nil error:&error]) LOG_ERROR(@"can not create series folder for zip. %@",[error description]);
             }

                        
   #pragma mark instances depending on the SOP Class
   /*
   pk, SOPInstanceUID and instance number are common to allo SOP Class

   In relation to Cornerstone, the number of frames is also important
   NumFrames=[NSNumber numberWithInt:[instanceSqlProperties[3] intValue]];

   This information is not available in non multiframe objects. Those shall have the value 0 if they are not frame based and 1 if they are always single frame.

   In the case of multiframe SOP Classes:
   Since number of frames may belong to some binary blog of dicom attrs, we allow postprocessing on sql raw data, and then on table-organized results.
   We reserve the value -1 to state that the info is not available at all in the DB.

   As seen some casuistics can be resolved before any query to the instance table, based on the SOP Class already obtained for series filters, we use specific query depending on the case:
   - I0 corresponde to a non frame based object where number of frames is forced to 0
   - I1 corresponds to a monoframe object where number of frames is forced to 1
   - I corresponds to an enhanced SOP Class potentially containing multiframes.
   */

            NSMutableData *instanceData=[NSMutableData data];
            if ([DRS.InstanceUniqueFrameSOPClass indexOfObject:SOPClass]!=NSNotFound)//I1
            {
               if (execUTF8Bash(sqlcredentials,
                                [NSString stringWithFormat:
                                 sqlDictionary[@"I1"],
                                 sqlprolog,
                                 seriesSqlProperties[0],
                                 instanceANDSOPClass,
                                 instanceANDSOPClassOff,
                                 @"",
                                 sqlRecordFiveUnits
                                 ],
                                instanceData)
                   !=0)
               {
                  LOG_ERROR(@"zip study db error");
                  continue;
               }
            }
            else if ([DRS.InstanceMultiFrameSOPClass indexOfObject:SOPClass]!=NSNotFound)//I
            {
               // watch optional IpostprocessingCommandsSh
               if (execUTF8Bash(sqlcredentials,
                                [NSString stringWithFormat:
                                 sqlDictionary[@"I"],
                                 sqlprolog,
                                 seriesSqlProperties[0],
                                 instanceANDSOPClass,
                                 instanceANDSOPClassOff,
                                 @"",
                              [sqlDictionary[@"IpostprocessingCommandsSh"]length]
                               ?sqlDictionary[@"IpostprocessingCommandsSh"]
                               :sqlRecordFiveUnits
                                 ],
                                instanceData)
                   !=0)
               {
                  LOG_ERROR(@"zip study db error");
                  continue;
               }
            }
            else //I0
            {
               if (execUTF8Bash(sqlcredentials,
                                [NSString stringWithFormat:
                                 sqlDictionary[@"I0"],
                                 sqlprolog,
                                 seriesSqlProperties[0],
                                 instanceANDSOPClass,
                                 instanceANDSOPClassOff,
                                 @"",
                                 sqlRecordFiveUnits
                                 ],
                                instanceData)
                   !=0)
               {
                  LOG_ERROR(@"zip study db error");
                  continue;
               }
            }
            NSArray *instanceSqlPropertiesArray=[instanceData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding stringUnitsPostProcessTitle:sqlDictionary[@"IpostprocessingTitleMain"] orderedByUnitIndex:2 decreasing:NO];//NSUTF8StringEncoding

                        
                     
#pragma mark instance loop
            for (NSArray *instanceSqlProperties in instanceSqlPropertiesArray)
            {
               NSString *instancePath=[[SPath stringByAppendingPathComponent:instanceSqlProperties[2]]stringByAppendingPathExtension:@"dcm"];
               if (![[NSFileManager defaultManager] fileExistsAtPath:instancePath])
               {
                  switch (getTypeIndex)
                  {
                     case getTypeWado:
                     {
                        NSData *DICMData=
                        [ResponseWadouri
                         DICMFromPacs:devDict
                         EUID:study[DEUID]
                         SUID:seriesSqlProperties[1]
                         IUID:instanceSqlProperties[2]
                         ];
                        if (DICMData)
                           [DICMData writeToFile:instancePath atomically:NO];
                     } break;//end of WADO
                  }//end of GET switch
               }
            }//end for each I
         }//end if SOPClass
      }// end for each S
   }
}
/*
   #pragma mark stream zipped response
       
      __block NSMutableData *CENTRAL=[NSMutableData data];
      __block BOOL needsEpilog=(accessType!=accessTypeWadoRSDicom);
      __block BOOL needsProlog=(accessType==accessTypeWadoRSDicom);
   #pragma mark TODO Time and Date
      __block uint16 zipTime=0x7534;
      __block uint16 zipDate=0x4F3B;
      __block uint32 LOCALPointer=0;
      __block uint16 LOCALIndex=0;
      
      // The RSAsyncStreamBlock works like the RSStreamBlock
      // The block must call "completionBlock" passing the new chunk of data when ready, an empty NSData when done, or nil on error and pass a NSError.
      // The block cannot call "completionBlock" more than once per invocation.
      
      
      
      
   #pragma mark handler
      return [RSStreamedResponse responseWithContentType:@"application/octet-stream" asyncStreamBlock:^(RSBodyReaderCompletionBlock completionBlock)
      {
    
    
    */
         /*
          5 steps:
          - prolog
          - entry data (LOCAL) for each entry
          - entry directory (if CENTRAL data exists)
          - epilog
          - end of stream
          
          wadors has prolog and data
          zip has data, directory, and epilog
          ... pdf...
          */
   
   /*
   #pragma mark 1. PROLOG
         if (needsProlog)
         {
            needsProlog=false;
         }
   #pragma mark 2. DATA
         else if (LOCALIndex < wados.count)
         {
   #pragma mark prepare crc32, compressed, uncompressed, entryData
           NSData *entryData=nil;
           NSString *entryPath=nil;
           uint32 zipCRC32=0x00000000;
           uint16 zipCompression=zipCompression0;
           uint32 zipCompressedSize=0x00000000;
           uint32 zipUncompressedSize=0x00000000;

           if (fromCache) entryPath=[DIR stringByAppendingPathComponent:filenames[LOCALIndex]];
           //if exists, get it from caché, else perform qido
           if (fromCache && [fileManager fileExistsAtPath:entryPath])
           {
               entryData=[NSData dataWithContentsOfFile:entryPath];
               zipCompressedSize=(uint32)entryData.length;
               zipCRC32=(uint32)[[[[entryPath stringByDeletingPathExtension]stringByDeletingPathExtension]pathExtension]intValue];
               zipUncompressedSize=(uint32)[[[entryPath stringByDeletingPathExtension]pathExtension]intValue];
           }
           else if (wados[LOCALIndex])
           {
              NSData *uncompressedData=[NSData dataWithContentsOfURL:[NSURL URLWithString:wados[LOCALIndex]]];
              zipCRC32=[uncompressedData crc32];
              [crc32s addObject:[NSNumber numberWithUnsignedInteger:zipCRC32]];
              zipUncompressedSize=(uint32)uncompressedData.length;
              [lengths addObject:[NSNumber numberWithUnsignedInteger:zipUncompressedSize]];
              [filenames addObject:
               [NSString stringWithFormat:
                @"%010u.%010u.%010u.dcm",
                LOCALIndex,
                zipCRC32,
                zipUncompressedSize
                ]
               ];
              switch (accessType) {
                 case accessTypeIsoDicomZip:
                 case accessTypeWadoRSDicom:
                    entryData=uncompressedData;
                    break;
                    
                 case accessTypeDicomzip:
                 case accessTypeDeflateIsoDicomZip:
                    entryData=[uncompressedData rawzip];
                    break;
                    
                 case accessTypeMaxDeflateIsoDicomZip:
                    entryData=[uncompressedData maxrawzip];
                    break;
              }
              zipCompressedSize=(uint32)entryData.length;
              if (entryData)[entryData writeToFile:[DIR stringByAppendingPathComponent: filenames[LOCALIndex]] atomically:NO];
           }

           
           if (!entryData)
           {
              NSLog(@"could not retrive: %@",wados[LOCALIndex]);
              completionBlock([NSData data], nil);
           }
           else
           {
              
   #pragma mark streamings

              switch (accessType) {
                 case accessTypeDicomzip:
                 case accessTypeIsoDicomZip:
                 case accessTypeDeflateIsoDicomZip:
                 case accessTypeMaxDeflateIsoDicomZip:
                 {
                    if (zipCompressedSize != zipUncompressedSize) zipCompression=zipCompression8;
                    NSData *nameData=[filenames[LOCALIndex] dataUsingEncoding:NSASCIIStringEncoding];
                    NSMutableData *LOCAL=[NSMutableData data];

                    [LOCAL appendBytes:&zipLOCAL length:4];
                    [LOCAL appendBytes:&zipVersion length:2];
                    [LOCAL appendBytes:&zipBitFlagsNone length:2];
                    [LOCAL appendBytes:&zipCompression length:2];
                    [LOCAL appendBytes:&zipTime length:2];
                    [LOCAL appendBytes:&zipDate length:2];
                    [LOCAL appendBytes:&zipCRC32 length:4];
                    [LOCAL appendBytes:&zipUncompressedSize length:4];
                    [LOCAL appendBytes:&zipCompressedSize length:4];
                    [LOCAL appendBytes:&zipNameLength length:2];
                    [LOCAL appendBytes:&zipExtraLength length:2];
                    [LOCAL appendData:nameData];
                    //noExtra
                    [LOCAL appendData:entryData];
                    completionBlock(LOCAL, nil);

                    //CENTRAL 46
                    [CENTRAL appendBytes:&zipCENTRAL length:4];
                    [CENTRAL appendBytes:&zipMadeBy length:2];//made by
                    [CENTRAL appendBytes:&zipVersion length:2];//needed
                    [CENTRAL appendBytes:&zipBitFlagsNone length:2];
                    [CENTRAL appendBytes:&zipCompression length:2];
                    [CENTRAL appendBytes:&zipTime length:2];
                    [CENTRAL appendBytes:&zipDate length:2];
                    [CENTRAL appendBytes:&zipCRC32 length:4];
                    [CENTRAL appendBytes:&zipCompressedSize length:4];
                    [CENTRAL appendBytes:&zipUncompressedSize length:4];
                    [CENTRAL appendBytes:&zipNameLength length:2];
                    [CENTRAL appendBytes:&zipExtraLength length:2];
                    [CENTRAL appendBytes:&zipExtraLength length:2];//comment
                    [CENTRAL appendBytes:&zipExtraLength length:2];//disk number start
                    [CENTRAL appendBytes:&zipExtraLength length:2];//internal file attribute
                    [CENTRAL appendBytes:&zipExternalFileAttributes length:4];
                    [CENTRAL appendBytes:&LOCALPointer length:4];//offsetOfLocalHeader
                    [CENTRAL appendData:nameData];
                    //noExtra
                    //noComment

                    LOCALPointer+=entryData.length+66;//30 entry + 36 name
                 } break;
                    
                 case accessTypeWadoRSDicom:
   #pragma mark TODO WADORSDICOM for each file
                    completionBlock([NSData data], nil);
                    break;

                 case accessTypeZip64IsoDicomZip:
   #pragma mark TODO zip64 for each file
                 {
                    NSData *nameData=[filenames[LOCALIndex] dataUsingEncoding:NSASCIIStringEncoding];
                    NSMutableData *LOCAL=[NSMutableData data];
                    [LOCAL appendBytes:&zipLOCAL length:4];
                    [LOCAL appendBytes:&zipVersion length:2];
                    [LOCAL appendBytes:&zipBitFlagsDescriptor length:2];
                    [LOCAL appendBytes:&zipCompression length:2];
                    [LOCAL appendBytes:&zipTime length:2];
                    [LOCAL appendBytes:&zipDate length:2];
                    [LOCAL increaseLengthBy:12];
                    [LOCAL appendBytes:&zipNameLength length:2];
                    [LOCAL appendBytes:&zipExtraLength length:2];
                    [LOCAL appendData:nameData];
                    //noExtra
                    [LOCAL appendData:entryData];
                    
                    [LOCAL appendBytes:&zipDESCRIPTOR length:4];
                    [LOCAL appendBytes:&zipCRC32 length:4];
                    [LOCAL appendBytes:&zipCompressedSize length:4];
                    [LOCAL appendBytes:&zipUncompressedSize length:4];

                    
                    completionBlock(LOCAL, nil);

                    //CENTRAL 46
                    [CENTRAL appendBytes:&zipCENTRAL length:4];
                    [CENTRAL appendBytes:&zipMadeBy length:2];//made by
                    [CENTRAL appendBytes:&zipVersion length:2];//needed
                    [CENTRAL appendBytes:&zipBitFlagsDescriptor length:2];
                    [CENTRAL appendBytes:&zipCompression length:2];
                    [CENTRAL appendBytes:&zipTime length:2];
                    [CENTRAL appendBytes:&zipDate length:2];
                    [CENTRAL appendBytes:&zipCRC32 length:4];
                    [CENTRAL appendBytes:&zipCompressedSize length:4];
                    [CENTRAL appendBytes:&zipUncompressedSize length:4];
                    [CENTRAL appendBytes:&zipNameLength length:2];
                    [CENTRAL appendBytes:&zipExtraLength length:2];
                    [CENTRAL appendBytes:&zipExtraLength length:2];//comment
                    [CENTRAL appendBytes:&zipExtraLength length:2];//disk number start
                    [CENTRAL appendBytes:&zipExtraLength length:2];//internal file attribute
                    [CENTRAL appendBytes:&zipExternalFileAttributes length:4];
                    [CENTRAL appendBytes:&LOCALPointer length:4];//offsetOfLocalHeader
                    [CENTRAL appendData:nameData];
                    //noExtra
                    //noComment

                    LOCALPointer+=entryData.length+66+16;//30 entry + 36 name + 16 descriptor
                    } break;

               }
            }
            LOCALIndex++;
         }
   #pragma mark 3. DIRECTORY
         else if (CENTRAL.length) //chunk with directory
         {
           completionBlock(CENTRAL, nil);
           [CENTRAL setData:[NSData data]];
         }
   #pragma mark 4. EPILOG
         else if (needsEpilog)
         {
            [CENTRAL appendBytes:&zipEND length:4];
            [CENTRAL appendBytes:&zipDiskNumber length:2];
            [CENTRAL appendBytes:&zipDiskCentralStarts length:2];
            [CENTRAL appendBytes:&LOCALIndex length:2];//disk zipEntries
            [CENTRAL appendBytes:&LOCALIndex length:2];//total zipEntries
            uint32 CENTRALSize=82 * LOCALIndex;
            [CENTRAL appendBytes:&CENTRALSize length:4];
            [CENTRAL appendBytes:&LOCALPointer length:4];
            [CENTRAL appendBytes:&zipExtraLength length:2];//comment
            
            completionBlock(CENTRAL, nil);
            [CENTRAL setData:[NSData data]];
            needsEpilog=false;
        }
   #pragma mark 5. END OF STREAM
         else
         {
           completionBlock(CENTRAL, nil);//empty last chunck
 */
   /*        //write JSON
           NSError *error;
           if (![[NSString
                  stringWithFormat:@"[[\"%@\"],[\"%@\"],[%@],[%@]]",
                  [filenames componentsJoinedByString:@"\",\""],
                  [wados componentsJoinedByString:@"\",\""],
                  [crc32s componentsJoinedByString:@","],
                  [lengths componentsJoinedByString:@","]
                  ]
                 writeToFile:JSON
                 atomically:NO
                 encoding:NSUTF8StringEncoding
                 error:&error
               ])
              LOG_WARNING(@"studyToken could not save dicomzip json");
    */
/*
        }
      }];
   }
 */


/*
#pragma mark - constants (ZIP)

// ZIP ISO structure

const uint32 zipLOCAL=0x04034B50;

const uint16 zipVersion=0x000A;//1.0 default value

const uint16 zipBitFlagsNone=0x0000;
const uint16 zipBitFlagsMaxCompression=0x0002;
const uint16 zipBitFlagsDescriptor=0x0008;//post data descriptor
*/
/*
 Bit 2  Bit 1
   0      0    Normal (-en) compression option was used.
   0      1    Maximum (-exx/-ex) compression option was used.
   1      0    Fast (-ef) compression option was used.
   1      1    Super Fast (-es) compression option was used.

 Bit 3: If this bit is set, the fields crc-32, compressed
        size and uncompressed size are set to zero in the
        local header.  The correct values are put in the
        data descriptor immediately following the compressed
        data.  (Note: PKZIP version 2.04g for DOS only
        recognizes this bit for method 8 compression, newer
        versions of PKZIP recognize this bit for any
        compression method.)

 Bit 4: Reserved for use with method 8, for enhanced
        deflating.

 Bit 11: Language encoding flag (EFS).  If this bit is set,
         the filename and comment fields for this file
         MUST be encoded using UTF-8. (see APPENDIX D)
         (we don´t need it since all the names are pure ASCII)
 */
/*
const uint16 zipCompression0=0x0000;
const uint16 zipCompression8=0x0008;
 */
//uint16 zipTime;
//uint16 zipDate;
//uint32 zipCRC32=0x00000000;
//uint32 zipCompressedSize=0x00000000;
//uint32 zipUncompressedSize=0x00000000;
/*
const uint16 zipNameLength=0x0024;//UUID.dcm
const uint16 zipExtraLength=0x0000;
 */
//zipName
//noExtra
//zipData


//const uint32 zipDESCRIPTOR=0x08074B50;
//zipCRC32
//zipCompressedSize
//zipUncompressedSize


//const uint32 zipCENTRAL=0x02014B50;
//const uint16 zipMadeBy=0x13;
//zipVersion
//zipBitFlags
//zipCompression8
//zipTime
//zipDate
//zipCRC32
//zipCompressedSize
//zipUncompressedSize
//zipNameLength
//zipExtraLength
//zipExtraLength comment
//zipExtraLength disk number start
//zipExtraLength internal file attribute
//const uint32 zipExternalFileAttributes=0x81A40000;
//uint32 zipRelativeOffsetOfLocal
//zipName
//noExtra
//noComment


//const uint32 zipEND=0x06054B50;
//const uint16 zipDiskNumber=0x0000;
//const uint16 zipDiskCentralStarts=0x0000;
//uint16 zipRecordTotal thisDisk
//zipRecordTotal
//uint32 zipCentralSize;
//uint32 zipCentralOffset;
//zipExtraLength
//noComment



/*
+(RSResponse*)dicomzipChunks4dictionary:(NSDictionary*)d
{
      //information model for getting and pulling the information, either from source or from cache
      __block NSMutableArray *filenames=[NSMutableArray array];
      __block NSMutableArray *wados=    [NSMutableArray array];
      __block NSMutableArray *crc32s=   [NSMutableArray array];
      __block NSMutableArray *lengths=  [NSMutableArray array];

      //cache made of a session.json manifest file and a corresponding session/ directory
      __block NSFileManager *fileManager=[NSFileManager defaultManager];
      __block NSString *DIR=
        [DRS.tokentmpDir
         stringByAppendingPathComponent:tokenString
         ];
       NSError *error=nil;
       if (![fileManager fileExistsAtPath:DIR])
       {
          if (![fileManager
                createDirectoryAtPath:DIR
                withIntermediateDirectories:YES
                attributes:nil
                error:&error]
              ) return [RSErrorResponse responseWithClientError:404 message:@"studyToken no access to token cache: %@",[error description]];
       }

       __block BOOL fromCache=false;
 */
   /*
       __block NSString *JSON=[DIR stringByAppendingPathExtension:@"json"];
       if ([fileManager fileExistsAtPath:JSON])
       {
           matchRoot=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:JSON] options:NSJSONReadingMutableContainers error:&error];
           if (! matchRoot) LOG_WARNING(@"studyToken dicomzip json unreadable at %@. %@",JSON, [error description]);
           else
           {
               if (matchRoot.count!=4) LOG_WARNING(@"studyToken dicomzip json bad");
               else
               {
                   NSArray *jsonFilenames=matchRoot[0];
                   if (!jsonFilenames || !jsonFilenames.count) LOG_WARNING(@"studyToken dicomzip json no filenames");
                   else
                   {
                       [filenames addObjectsFromArray:jsonFilenames];
                       NSArray *jsonWados=matchRoot[1];
                       if (!jsonWados || (jsonFilenames.count!=jsonWados.count)) LOG_WARNING(@"studyToken dicomzip json no inconsistent wados");
                       else
                       {
                           [wados addObjectsFromArray:jsonWados];
                           NSArray *jsonCrc32s=matchRoot[2];
                           if (!jsonCrc32s || (jsonFilenames.count!=jsonCrc32s.count)) LOG_WARNING(@"studyToken dicomzip json no inconsistent crc32s");
                           else
                           {
                               [crc32s addObjectsFromArray:jsonCrc32s];
                               NSArray *jsonLengths=matchRoot[3];
                               if (!jsonLengths || (jsonFilenames.count!=jsonLengths.count)) LOG_WARNING(@"studyToken dicomzip json no inconsistent lengths");
                               else
                               {
                                   [lengths addObjectsFromArray:jsonLengths];
                                   fromCache=true;
                               }
                           }
                       }
                   }
               }
               
           }
           
           if (!fromCache) [fileManager moveItemAtPath:JSON toPath:[JSON stringByAppendingPathExtension:@"bad"] error:nil];
       }
   */
  /*
       if (!fromCache)
       {
          if (lanArray.count > 1)
          {
             //add nodes and start corresponding processes
          }

          if (wanArray.count > 0)
          {
             //add nodes and start corresponding processes
          }

          if (lanArray.count == 0)
          {
             //add nodes and start corresponding processes
          }
          else
          {
             while (1)
             {
                NSString *devOID=lanArray[0];
                NSDictionary *devDict=DRS.pacs[devOID];

   #pragma mark · GET type index
                NSUInteger getTypeIndex=[@[@"file",@"folder",@"wado",@"wadors",@"cget",@"cmove"] indexOfObject:devDict[@"get"]];

   #pragma mark · SELECT switch
                switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:devDict[@"select"]]) {
                   
                   case NSNotFound:{
                      LOG_WARNING(@"studyToken pacs %@ lacks \"select\" type property",devOID);
                   } break;
                      
                   case selectTypeSql:{
   #pragma mark · SQL SELECT (unique option for now)
                      NSDictionary *sqlcredentials=@{devDict[@"sqlcredentials"]:devDict[@"sqlpassword"]};
                      NSString *sqlprolog=devDict[@"sqlprolog"];
                      NSDictionary *sqlDictionary=DRS.sqls[devDict[@"sqlmap"]];

                      

   #pragma mark · apply EuiE (Study Patient) filters
                      NSMutableDictionary *EuiEDict=[NSMutableDictionary dictionary];
                      RSResponse *sqlEuiEErrorReturned=sqlEP(
                       EuiEDict,
                       sqlcredentials,
                       sqlDictionary,
                       sqlprolog,
                       true,
                       StudyInstanceUIDRegexpString,
                       AccessionNumberEqualString,
                       refInstitutionLikeString,
                       refServiceLikeString,
                       refUserLikeString,
                       refIDLikeString,
                       refIDTypeLikeString,
                       readInstitutionSqlLikeString,
                       readServiceSqlLikeString,
                       readUserSqlLikeString,
                       readIDSqlLikeString,
                       readIDTypeSqlLikeString,
                       StudyIDLikeString,
                       PatientIDLikeString,
                       patientFamilyLikeString,
                       patientGivenLikeString,
                       patientMiddleLikeString,
                       patientPrefixLikeString,
                       patientSuffixLikeString,
                       issuerArray,
                       StudyDateArray,
                       SOPClassInStudyRegexpString,
                       ModalityInStudyRegexpString,
                       StudyDescriptionRegexpString
                      );
                      if (sqlEuiEErrorReturned) return sqlEuiEErrorReturned;
                    

   #pragma mark ·· GET switch
                      switch (getTypeIndex) {
                            
                         case NSNotFound:{
                            LOG_WARNING(@"studyToken pacs %@ lacks \"get\" property",devOID);
                         } break;

                         case getTypeWado:{
   #pragma mark ·· WADO (unique option for now)
                            
                            NSMutableData *mutableData=[NSMutableData data];
                            for (NSString *Eui in EuiEDict)
                            {
   //#pragma mark study loop
                               [mutableData setData:[NSData data]];
                               if (execUTF8Bash(sqlcredentials,
                                              [NSString stringWithFormat:
                                               sqlDictionary[@"S"],
                                               sqlprolog,
                                               EuiEDict[Eui],
                                               @"",
                                               sqlRecordFiveUnits
                                               ],
                                              mutableData)
                                   !=0)
                               {
                                  LOG_ERROR(@"studyToken study db error");
                                  continue;
                               }
                               NSArray *SPropertiesArray=[mutableData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:3 decreasing:NO];//NSUTF8StringEncoding
                               for (NSArray *SProperties in SPropertiesArray)
                               {
   //#pragma mark series loop
                                  NSString *SOPClass=SOPCLassOfReturnableSeries(
                                   sqlcredentials,
                                   sqlDictionary[@"Ici4S"],
                                   sqlprolog,
                                   SProperties,
                                   SeriesInstanceUIDRegex,
                                   SeriesNumberRegex,
                                   SeriesDescriptionRegex,
                                   ModalityRegex,
                                   SOPClassRegex,
                                   SOPClassOffRegex
                                  );
                                  if (SOPClass)
                                  {
                                     //instances
                                     [mutableData setData:[NSData data]];
                                     if (execUTF8Bash(sqlcredentials,
                                                    [NSString stringWithFormat:
                                                     sqlDictionary[@"Iui4S"],
                                                     sqlprolog,
                                                     SProperties[0],
                                                     @"",
                                                     sqlsingleslash
                                                     ],
                                                    mutableData)
                                      !=0)
                                     {
                                        LOG_ERROR(@"studyToken study db error");
                                        continue;
                                     }
                                     NSString *sopuids=[[NSString alloc]initWithData:mutableData encoding:NSUTF8StringEncoding];
                                     for (NSString *sopuid in sopuids.pathComponents)
                                     {
                                        //remove the / empty component at the end
                                        if (sopuid.length > 1)
                                        {
                                           [wados addObject:[NSString stringWithFormat:@"%@?requestType=WADO&studyUID=%@&seriesUID=%@&objectUID=%@&contentType=application/dicom%@",devDict[@"wadouri"],Eui,SProperties[1],sopuid,devDict[@"wadodicomdicparameters"]]];
                                        }
                                     }// end for each I
                                  }//end if SOPClass
                               }//end for each S
                            } break;//end of E and WADO
                         }// end of GET switch
                      } break;//end of sql
                   } //end of SELECT switch
                }
                break;
             }//end while 1

          }//end at least one dev
       }

   #pragma mark stream zipped response
       
      __block NSMutableData *CENTRAL=[NSMutableData data];
      __block BOOL needsEpilog=(accessType!=accessTypeWadoRSDicom);
      __block BOOL needsProlog=(accessType==accessTypeWadoRSDicom);
   #pragma mark TODO Time and Date
      __block uint16 zipTime=0x7534;
      __block uint16 zipDate=0x4F3B;
      __block uint32 LOCALPointer=0;
      __block uint16 LOCALIndex=0;
      
      // The RSAsyncStreamBlock works like the RSStreamBlock
      // The block must call "completionBlock" passing the new chunk of data when ready, an empty NSData when done, or nil on error and pass a NSError.
      // The block cannot call "completionBlock" more than once per invocation.
      
      
      
      
   #pragma mark handler
      return [RSStreamedResponse responseWithContentType:@"application/octet-stream" asyncStreamBlock:^(RSBodyReaderCompletionBlock completionBlock)
      {
   */
         /*
          5 steps:
          - prolog
          - entry data (LOCAL) for each entry
          - entry directory (if CENTRAL data exists)
          - epilog
          - end of stream
          
          wadors has prolog and data
          zip has data, directory, and epilog
          ... pdf...
          */
/*
   #pragma mark 1. PROLOG
         if (needsProlog)
         {
            needsProlog=false;
         }
   #pragma mark 2. DATA
         else if (LOCALIndex < wados.count)
         {
   #pragma mark prepare crc32, compressed, uncompressed, entryData
           NSData *entryData=nil;
           NSString *entryPath=nil;
           uint32 zipCRC32=0x00000000;
           uint16 zipCompression=zipCompression0;
           uint32 zipCompressedSize=0x00000000;
           uint32 zipUncompressedSize=0x00000000;

           if (fromCache) entryPath=[DIR stringByAppendingPathComponent:filenames[LOCALIndex]];
           //if exists, get it from caché, else perform qido
           if (fromCache && [fileManager fileExistsAtPath:entryPath])
           {
               entryData=[NSData dataWithContentsOfFile:entryPath];
               zipCompressedSize=(uint32)entryData.length;
               zipCRC32=(uint32)[[[[entryPath stringByDeletingPathExtension]stringByDeletingPathExtension]pathExtension]intValue];
               zipUncompressedSize=(uint32)[[[entryPath stringByDeletingPathExtension]pathExtension]intValue];
           }
           else if (wados[LOCALIndex])
           {
              NSData *uncompressedData=[NSData dataWithContentsOfURL:[NSURL URLWithString:wados[LOCALIndex]]];
              zipCRC32=[uncompressedData crc32];
              [crc32s addObject:[NSNumber numberWithUnsignedInteger:zipCRC32]];
              zipUncompressedSize=(uint32)uncompressedData.length;
              [lengths addObject:[NSNumber numberWithUnsignedInteger:zipUncompressedSize]];
              [filenames addObject:
               [NSString stringWithFormat:
                @"%010u.%010u.%010u.dcm",
                LOCALIndex,
                zipCRC32,
                zipUncompressedSize
                ]
               ];
              switch (accessType) {
                 case accessTypeIsoDicomZip:
                 case accessTypeWadoRSDicom:
                    entryData=uncompressedData;
                    break;
                    
                 case accessTypeDicomzip:
                 case accessTypeDeflateIsoDicomZip:
                    entryData=[uncompressedData rawzip];
                    break;
                    
                 case accessTypeMaxDeflateIsoDicomZip:
                    entryData=[uncompressedData maxrawzip];
                    break;
              }
              zipCompressedSize=(uint32)entryData.length;
              if (entryData)[entryData writeToFile:[DIR stringByAppendingPathComponent: filenames[LOCALIndex]] atomically:NO];
           }

           
           if (!entryData)
           {
              NSLog(@"could not retrive: %@",wados[LOCALIndex]);
              completionBlock([NSData data], nil);
           }
           else
           {
              
   #pragma mark streamings

              switch (accessType) {
                 case accessTypeDicomzip:
                 case accessTypeIsoDicomZip:
                 case accessTypeDeflateIsoDicomZip:
                 case accessTypeMaxDeflateIsoDicomZip:
                 {
                    if (zipCompressedSize != zipUncompressedSize) zipCompression=zipCompression8;
                    NSData *nameData=[filenames[LOCALIndex] dataUsingEncoding:NSASCIIStringEncoding];
                    NSMutableData *LOCAL=[NSMutableData data];

                    [LOCAL appendBytes:&zipLOCAL length:4];
                    [LOCAL appendBytes:&zipVersion length:2];
                    [LOCAL appendBytes:&zipBitFlagsNone length:2];
                    [LOCAL appendBytes:&zipCompression length:2];
                    [LOCAL appendBytes:&zipTime length:2];
                    [LOCAL appendBytes:&zipDate length:2];
                    [LOCAL appendBytes:&zipCRC32 length:4];
                    [LOCAL appendBytes:&zipUncompressedSize length:4];
                    [LOCAL appendBytes:&zipCompressedSize length:4];
                    [LOCAL appendBytes:&zipNameLength length:2];
                    [LOCAL appendBytes:&zipExtraLength length:2];
                    [LOCAL appendData:nameData];
                    //noExtra
                    [LOCAL appendData:entryData];
                    completionBlock(LOCAL, nil);

                    //CENTRAL 46
                    [CENTRAL appendBytes:&zipCENTRAL length:4];
                    [CENTRAL appendBytes:&zipMadeBy length:2];//made by
                    [CENTRAL appendBytes:&zipVersion length:2];//needed
                    [CENTRAL appendBytes:&zipBitFlagsNone length:2];
                    [CENTRAL appendBytes:&zipCompression length:2];
                    [CENTRAL appendBytes:&zipTime length:2];
                    [CENTRAL appendBytes:&zipDate length:2];
                    [CENTRAL appendBytes:&zipCRC32 length:4];
                    [CENTRAL appendBytes:&zipCompressedSize length:4];
                    [CENTRAL appendBytes:&zipUncompressedSize length:4];
                    [CENTRAL appendBytes:&zipNameLength length:2];
                    [CENTRAL appendBytes:&zipExtraLength length:2];
                    [CENTRAL appendBytes:&zipExtraLength length:2];//comment
                    [CENTRAL appendBytes:&zipExtraLength length:2];//disk number start
                    [CENTRAL appendBytes:&zipExtraLength length:2];//internal file attribute
                    [CENTRAL appendBytes:&zipExternalFileAttributes length:4];
                    [CENTRAL appendBytes:&LOCALPointer length:4];//offsetOfLocalHeader
                    [CENTRAL appendData:nameData];
                    //noExtra
                    //noComment

                    LOCALPointer+=entryData.length+66;//30 entry + 36 name
                 } break;
                    
                 case accessTypeWadoRSDicom:
   #pragma mark TODO WADORSDICOM for each file
                    completionBlock([NSData data], nil);
                    break;

                 case accessTypeZip64IsoDicomZip:
   #pragma mark TODO zip64 for each file
                 {
                    NSData *nameData=[filenames[LOCALIndex] dataUsingEncoding:NSASCIIStringEncoding];
                    NSMutableData *LOCAL=[NSMutableData data];
                    [LOCAL appendBytes:&zipLOCAL length:4];
                    [LOCAL appendBytes:&zipVersion length:2];
                    [LOCAL appendBytes:&zipBitFlagsDescriptor length:2];
                    [LOCAL appendBytes:&zipCompression length:2];
                    [LOCAL appendBytes:&zipTime length:2];
                    [LOCAL appendBytes:&zipDate length:2];
                    [LOCAL increaseLengthBy:12];
                    [LOCAL appendBytes:&zipNameLength length:2];
                    [LOCAL appendBytes:&zipExtraLength length:2];
                    [LOCAL appendData:nameData];
                    //noExtra
                    [LOCAL appendData:entryData];
                    
                    [LOCAL appendBytes:&zipDESCRIPTOR length:4];
                    [LOCAL appendBytes:&zipCRC32 length:4];
                    [LOCAL appendBytes:&zipCompressedSize length:4];
                    [LOCAL appendBytes:&zipUncompressedSize length:4];

                    
                    completionBlock(LOCAL, nil);

                    //CENTRAL 46
                    [CENTRAL appendBytes:&zipCENTRAL length:4];
                    [CENTRAL appendBytes:&zipMadeBy length:2];//made by
                    [CENTRAL appendBytes:&zipVersion length:2];//needed
                    [CENTRAL appendBytes:&zipBitFlagsDescriptor length:2];
                    [CENTRAL appendBytes:&zipCompression length:2];
                    [CENTRAL appendBytes:&zipTime length:2];
                    [CENTRAL appendBytes:&zipDate length:2];
                    [CENTRAL appendBytes:&zipCRC32 length:4];
                    [CENTRAL appendBytes:&zipCompressedSize length:4];
                    [CENTRAL appendBytes:&zipUncompressedSize length:4];
                    [CENTRAL appendBytes:&zipNameLength length:2];
                    [CENTRAL appendBytes:&zipExtraLength length:2];
                    [CENTRAL appendBytes:&zipExtraLength length:2];//comment
                    [CENTRAL appendBytes:&zipExtraLength length:2];//disk number start
                    [CENTRAL appendBytes:&zipExtraLength length:2];//internal file attribute
                    [CENTRAL appendBytes:&zipExternalFileAttributes length:4];
                    [CENTRAL appendBytes:&LOCALPointer length:4];//offsetOfLocalHeader
                    [CENTRAL appendData:nameData];
                    //noExtra
                    //noComment

                    LOCALPointer+=entryData.length+66+16;//30 entry + 36 name + 16 descriptor
                    } break;

               }
            }
            LOCALIndex++;
         }
   #pragma mark 3. DIRECTORY
         else if (CENTRAL.length) //chunk with directory
         {
           completionBlock(CENTRAL, nil);
           [CENTRAL setData:[NSData data]];
         }
   #pragma mark 4. EPILOG
         else if (needsEpilog)
         {
            [CENTRAL appendBytes:&zipEND length:4];
            [CENTRAL appendBytes:&zipDiskNumber length:2];
            [CENTRAL appendBytes:&zipDiskCentralStarts length:2];
            [CENTRAL appendBytes:&LOCALIndex length:2];//disk zipEntries
            [CENTRAL appendBytes:&LOCALIndex length:2];//total zipEntries
            uint32 CENTRALSize=82 * LOCALIndex;
            [CENTRAL appendBytes:&CENTRALSize length:4];
            [CENTRAL appendBytes:&LOCALPointer length:4];
            [CENTRAL appendBytes:&zipExtraLength length:2];//comment
            
            completionBlock(CENTRAL, nil);
            [CENTRAL setData:[NSData data]];
            needsEpilog=false;
        }
   #pragma mark 5. END OF STREAM
         else
         {
           completionBlock(CENTRAL, nil);//empty last chunck
     */
   /*        //write JSON
           NSError *error;
           if (![[NSString
                  stringWithFormat:@"[[\"%@\"],[\"%@\"],[%@],[%@]]",
                  [filenames componentsJoinedByString:@"\",\""],
                  [wados componentsJoinedByString:@"\",\""],
                  [crc32s componentsJoinedByString:@","],
                  [lengths componentsJoinedByString:@","]
                  ]
                 writeToFile:JSON
                 atomically:NO
                 encoding:NSUTF8StringEncoding
                 error:&error
               ])
              LOG_WARNING(@"studyToken could not save dicomzip json");
    */

@end
