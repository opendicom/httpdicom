#import "DRS+report.h"
#import "DRS+studyToken.h"
#import "ResponseWadouri.h"

@implementation DRS (report)


-(void)addXMLReportHandler
{
   NSRegularExpression *reportRegex = [NSRegularExpression regularExpressionWithPattern:@"^/(OT|DOC)/(DSCD|SCD|CDA|PDF)?$" options:0 error:NULL];
   
   //two params:
   // (1) institution
   // (2)    EKey (first choice if PACS allows sql)
   //     or StudyInstanceUID
   //     or AccessionNumber+issuer?
   
   NSData *XMLPrefixData=[@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>" dataUsingEncoding:NSUTF8StringEncoding];
   NSData *DSCDSuffixData=[@"</dscd>" dataUsingEncoding:NSUTF8StringEncoding];
   NSData *SCDPrefixData=[@"<scd" dataUsingEncoding:NSUTF8StringEncoding];
   NSData *SCDSuffixData=[@"</scd>" dataUsingEncoding:NSUTF8StringEncoding];
   NSData *CDAPrefixData=[@"<ClinicalDocument" dataUsingEncoding:NSUTF8StringEncoding];
   NSData *CDASuffixData=[@"</ClinicalDocument>" dataUsingEncoding:NSUTF8StringEncoding];

   
[self addHandler:@"GET" regex:reportRegex processBlock:
 ^(RSRequest* request, RSCompletionBlock completionBlock){completionBlock(^RSResponse* (RSRequest* request)
   {
#pragma mark - parsing URL
     NSArray *pathParams=[request.URL.absoluteString componentsSeparatedByString:@"?"];
     NSString *docType=[pathParams[0] lastPathComponent];
     NSString *modality=[[pathParams[0] stringByDeletingLastPathComponent] lastPathComponent];

     NSString *params=pathParams[1];
     NSMutableArray *names=[NSMutableArray array];
     NSMutableArray *values=[NSMutableArray array];
     NSArray *paramItems=[params componentsSeparatedByString:@"&"];
    
     for (NSString *param in paramItems)
     {
         NSArray *nameValue=[param componentsSeparatedByString:@"="];
         if ([nameValue[1] length])
         {
             [names addObject:nameValue[0]];
             [values addObject:nameValue[1]];
         }
     }



#pragma mark devOID
    NSUInteger institutionIndex=[names indexOfObject:@"institution"];
    if (institutionIndex==NSNotFound)
       return [RSErrorResponse responseWithClientError:404 message:@"bad URL, no institution"];
    //custodiantitle.aet or oid
    NSDictionary *devDict=nil;
    if ([DICMTypes isSingleUIString:values[institutionIndex]]) devDict=DRS.pacs[values[institutionIndex]];
    else
       devDict=(DRS.pacs[values[institutionIndex]]);//[@"pacsoid"]


    NSUInteger EKeyIndex=[names indexOfObject:@"EKey"];
    NSUInteger StudyInstanceUIDIndex=[names indexOfObject:@"StudyInstanceUID"];
    NSUInteger AccessionNumberIndex=[names indexOfObject:@"AccessionNumber"];
    NSDictionary *sqlcredentials=@{devDict[@"sqlcredentials"]:devDict[@"sqlpassword"]};
    NSString *sqlprolog=devDict[@"sqlprolog"];
    NSDictionary *sqlDictionary=DRS.sqls[devDict[@"sqlmap"]];
    NSMutableData *instanceData=[NSMutableData data];

    
    if (   (EKeyIndex!=NSNotFound)
        && [devDict[@"select"]isEqualToString:@"sql"]
        )
    {
       #pragma mark EKey
       if (execUTF8Bash(sqlcredentials,
                        [NSString stringWithFormat:
                         sqlDictionary[@"RE"],//report EKey
                         sqlprolog,
                         values[EKeyIndex],
                         modality,
                         sqlRecordThreeUnits
                         ],
                        instanceData)
           !=0) return [RSErrorResponse responseWithServerError:500 message:@"DB problem"];
       else
       {

       }
    }
    else if (StudyInstanceUIDIndex!=NSNotFound)
    {
       #pragma mark StudyInstanceUID
       switch ([@[@"sql",@"qido",@"cfind"] indexOfObject:devDict[@"select"]])
       {
           case selectTypeSql:
           {
#pragma mark TODO
           } break;
       }

    }
    else if (AccessionNumberIndex!=NSNotFound)
    {
       #pragma mark AccessionNumber
       #pragma mark TODO

    }
    else return [RSErrorResponse responseWithClientError:404 message:@"bad URL, no study identifier"];
    
#pragma mark report found
    NSArray *instances=[instanceData arrayOfRecordsOfStringUnitsEncoding:NSISOLatin1StringEncoding orderedByUnitIndex:NSNotFound decreasing:NO];//NSUTF8StringEncoding
    if (!instances.count) return [RSErrorResponse responseWithServerError:500 message:@"no report found"];
    
    NSArray *reportProperties=instances[0];
#pragma mark wado download it
    
    NSData *XMLData=
    [ResponseWadouri
     XMLStringFromPacs:devDict
     EUID:reportProperties[0]
     SUID:reportProperties[1]
     IUID:reportProperties[2]
     ];
    
    if ([docType isEqualToString:@"DSCD"])
       return [RSDataResponse
               responseWithData:XMLData
               contentType:@"text/xml"
               ];
    
    NSRange XMLDataRange=NSMakeRange(0,XMLData.length);
    NSMutableData *data=[NSMutableData dataWithData:XMLPrefixData];

    if ([docType isEqualToString:@"SCD"])
    {
       NSRange SCDPrefixRange=
       [XMLData rangeOfData:SCDPrefixData
                    options:0
                      range:XMLDataRange
        ];
       
       NSRange SCDSuffixRange=
       [XMLData rangeOfData:SCDSuffixData
                    options:0
                      range:XMLDataRange
        ];
       
       [data appendData:
        [XMLData subdataWithRange:NSMakeRange(
         SCDPrefixRange.location,
         SCDSuffixRange.location
         - SCDPrefixRange.location
         + SCDSuffixData.length
       )]];
       
       return [RSDataResponse
               responseWithData:data
               contentType:@"text/xml"
               ];
    }
       

   if ([docType isEqualToString:@"CDA"])
   {
    NSRange CDAPrefixRange=
    [XMLData rangeOfData:CDAPrefixData
                 options:0
                   range:XMLDataRange
    ];
    NSRange CDASuffixRange=
    [XMLData rangeOfData:CDASuffixData
                 options:0
                   range:XMLDataRange
    ];
    
    [data appendData:
     [XMLData subdataWithRange:NSMakeRange(
      CDAPrefixRange.location,
      CDASuffixRange.location
      - CDAPrefixRange.location
      + CDASuffixData.length
     )]];
    
    return [RSDataResponse
            responseWithData:data
            contentType:@"text/xml"
           ];
    }
    return [RSErrorResponse responseWithClientError:500 message:@"PDF extraction not ready yet"];;
 }

(request));}];
}


@end


//subsampling with block predicate
// //https://developer.apple.com/reference/foundation/nsmutablearray/1412085-filterusingpredicate?language=objc
// https://stackoverflow.com/questions/13767516/nspredicate-on-array-of-arrays/33779086
// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Predicates/Articles/pBNF.html#//apple_ref/doc/uid/TP40001796-217950
