#import "NSString+PCS.h"
#import <netdb.h>
#import <CommonCrypto/CommonDigest.h>
#import "K.h"
#import "ODLog.h"

@implementation NSString (PCS)


+(NSString*)regexDicomString:(NSString*)dicomString withFormat:(NSString*)formatString
{
    NSString *regex;
    regex = [dicomString stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    regex = [regex stringByReplacingOccurrencesOfString:@"{" withString:@"\\{"];
    regex = [regex stringByReplacingOccurrencesOfString:@"}" withString:@"\\}"];
    regex = [regex stringByReplacingOccurrencesOfString:@"?" withString:@"\\?"];
    regex = [regex stringByReplacingOccurrencesOfString:@"+" withString:@"\\+"];
    regex = [regex stringByReplacingOccurrencesOfString:@"[" withString:@"\\["];
    regex = [regex stringByReplacingOccurrencesOfString:@"(" withString:@"\\("];
    regex = [regex stringByReplacingOccurrencesOfString:@")" withString:@"\\)"];
    regex = [regex stringByReplacingOccurrencesOfString:@"^" withString:@"\\^"];
    regex = [regex stringByReplacingOccurrencesOfString:@"$" withString:@"\\$"];
    regex = [regex stringByReplacingOccurrencesOfString:@"|" withString:@"\\|"];
    regex = [regex stringByReplacingOccurrencesOfString:@"/" withString:@"\\/"];
    regex = [regex stringByReplacingOccurrencesOfString:@"." withString:@"\\."];
    regex = [regex stringByReplacingOccurrencesOfString:@"*" withString:@".*"];
    regex = [regex stringByReplacingOccurrencesOfString:@"_" withString:@"."];
    return [NSString stringWithFormat:formatString,regex];
}


+(NSString*)mysqlEscapedFormat:(NSString*)format fieldString:(NSString*)field valueString:(NSString*)value;
{
    NSString *escapedValue;
    escapedValue = [value stringByReplacingOccurrencesOfString:@"?" withString:@"_"];
    escapedValue = [escapedValue stringByReplacingOccurrencesOfString:@"*" withString:@"%"];
    return [NSString stringWithFormat:format,field,escapedValue];
}

+(NSString*)stringFromSockAddr:(const struct sockaddr*)addr includeService:(BOOL)includeService
{
    NSString* string = nil;
    char hostBuffer[NI_MAXHOST];
    char serviceBuffer[NI_MAXSERV];
    if (getnameinfo(addr, addr->sa_len, hostBuffer, sizeof(hostBuffer), serviceBuffer, sizeof(serviceBuffer), NI_NUMERICHOST | NI_NUMERICSERV | NI_NOFQDN) >= 0) {
        string = includeService ? [NSString stringWithFormat:@"%s:%s", hostBuffer, serviceBuffer] : [NSString stringWithUTF8String:hostBuffer];
    }
    return string;
}

-(NSString*)MD5String
{
   //self data
    const char *cStr = [self UTF8String];
   
   //digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (unsigned int)strlen(cStr), digest );
   
   //digest data to string
   NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
   for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
   return  output;
}

-(NSString*)SHA512String
{
    //self data
    const char *cStr = [self UTF8String];
   
    //digest
    unsigned char digest[CC_SHA512_DIGEST_LENGTH];
    CC_SHA512(cStr, (unsigned int)strlen(cStr), digest);
   
    //digest data to string
   NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA512_DIGEST_LENGTH * 2];
   for(int i = 0; i < CC_SHA512_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
   return  [NSString stringWithString:output];
}

-(NSString*)normalizeHeaderValue
{

    NSRange range = [self rangeOfString:@";"];
    // Assume part before ";" separator is case-insensitive
    if (range.location != NSNotFound)
    {
        return [[[self substringToIndex:range.location] lowercaseString] stringByAppendingString:[self substringFromIndex:range.location]];
    }
    return [self lowercaseString];
}


-(NSString*)valueForName:(NSString*)name
{
    NSString* parameter = nil;
    NSScanner* scanner = [[NSScanner alloc] initWithString:self];
    [scanner setCaseSensitive:NO];
    // Assume parameter names are case-insensitive
    NSString* string = [NSString stringWithFormat:@"%@=", name];
    if ([scanner scanUpToString:string intoString:NULL])
    {
        [scanner scanString:string intoString:NULL];
        if ([scanner scanString:@"\"" intoString:NULL]) {
            [scanner scanUpToString:@"\"" intoString:&parameter];
        } else {
            [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&parameter];
        }
    }
    return parameter;
}

-(NSString*)dcmDaFromDate
{
    if ([self length]==8)return self;
    if ([self length]<10)
    {
        NSLog(@"strange DA: '%@'",self);
        return @"";
    }
    return [NSString stringWithFormat:@"%@%@%@",
            [self substringWithRange:NSMakeRange(0,4)],
            [self substringWithRange:NSMakeRange(5,2)],
            [self substringWithRange:NSMakeRange(8,2)]
            ];
}

-sqlFilterWithStart:(NSString*)start end:(NSString*)end
{
    NSUInteger startLength=[start length];
    NSUInteger endLength=[end length];
    if (!start || !end || startLength+endLength==0) return @"";

    NSString *isoStart=nil;
    switch (startLength) {
        case 0:;
            isoStart=@"";
            break;
        case 8:;
            isoStart=[NSString stringWithFormat:@"%@-%@-%@",
                  [start substringWithRange:NSMakeRange(0, 4)],
                  [start substringWithRange:NSMakeRange(4, 2)],
                  [start substringWithRange:NSMakeRange(6, 2)]
                  ];
        break;
        case 10:;
            isoStart=start;
        
        default:
            return @"";
        break;
    }

    NSString *isoEnd=nil;
    switch (endLength) {
        case 0:;
        isoEnd=@"";
        break;
        case 8:;
        isoEnd=[NSString stringWithFormat:@"%@-%@-%@",
                  [end substringWithRange:NSMakeRange(0, 4)],
                  [end substringWithRange:NSMakeRange(4, 2)],
                  [end substringWithRange:NSMakeRange(6, 2)]
                  ];
        break;
        case 10:;
        isoEnd=end;
        
        default:
        return @"";
        break;
    }

    if (startLength==0) return [NSString stringWithFormat:@" AND DATE(%@) <= '%@'", self, isoEnd];
    else if (endLength==0) return [NSString stringWithFormat:@" AND DATE(%@) >= '%@'", self, isoStart];
    else if ([isoStart isEqualToString:isoEnd]) return [NSString stringWithFormat:@" AND DATE(%@) = '%@'", self, isoStart];
    else return [NSString stringWithFormat:@" AND DATE(%@) >= '%@' AND DATE(%@) <= '%@'", self, isoStart, self, isoEnd];
    
    return @"";
}
    
-(NSString*)spaceNormalize
{
    return [
            [self stringByReplacingOccurrencesOfString:@"[ ]+"
                                            withString:@" "
                                               options:NSRegularExpressionSearch
                                                 range:NSMakeRange(0, self.length)]
            stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]
            ];
}

-(NSArray*)componentsSlashOrBackSlashSeparated
{
   NSArray *array=[[self spaceNormalize]
                   componentsSeparatedByCharactersInSet:
                   [NSCharacterSet characterSetWithCharactersInString:@"/\\"]
                   ];
   NSMutableArray *mutableArray=[NSMutableArray array];
   for (NSString *component in array)
   {
      if ([component length]) [mutableArray addObject:component];
   }
   return [NSArray arrayWithArray:mutableArray];
}

/*
 verifies if this is a valid codified reqProcedure or spsxProtocol
 - returns an array of three elements if a code was discovered
 - returns un array of one element equal to the description it there is no clear correspondence with a code
 - returns nil if the description contains |
 */
-(NSArray*)procedureCodeArrayForContextPacs:(NSString*)pacsUID
{
   if (![self containsString:@"|"])
   {
      NSArray *array=[[self spaceNormalize]componentsSeparatedByString:@"^"];

      switch ([array count]) {
         case 0://impossible
            NSLog(@"componentsSeparatedByString ^error with: %@",self);
         case 1://includes empty string
            return array;
            break;
            
         case 3:
         {
            //verify order meaning scheme
            //scheme is by means of index number and found in array[2] *
            NSString *code=array[0];
            NSString *description;
            NSString *scheme;
            if ([array[1]integerValue]!=0)
            {
               //scheme and description inverted
               description=array[2];
               scheme=array[1];
            }
            else
            {
               description=array[1];
               scheme=array[2];
            }
            
            //verify if it is a known scheme
            NSUInteger schemeIndex=[K.schemeindexes[@"key"] indexOfObject:scheme];
            if (schemeIndex==NSNotFound)
            {
               schemeIndex=[K.schemeindexes[@"oid"] indexOfObject:scheme];
               if (schemeIndex==NSNotFound)
               {
                  schemeIndex=[K.schemeindexes[@"shortname"] indexOfObject:scheme];
                  if (schemeIndex==NSNotFound)
                  {
                     schemeIndex=[K.schemeindexes[@"dcm"] indexOfObject:scheme];
                     if (schemeIndex==NSNotFound) schemeIndex=[K.schemeindexes[@"hl7v2"] indexOfObject:scheme];
                  }
               }
            }
            if (schemeIndex==NSNotFound)
            {
               NSLog(@"scheme '%@' not known",scheme);
               //array with one element
               return @[[self stringByReplacingOccurrencesOfString:@"^"withString:@"_"]];
            }
            
            //scheme found
            
            //verify if it is a known reqProcedure code^*^scheme for the pacs of the context
            if (pacsUID)
            {
               NSDictionary *pacsProcedureDict=K.procedureindexes[pacsUID];
               NSUInteger procedureIndex=[pacsProcedureDict[@"key"] indexOfObject:code];
               
               if (procedureIndex==NSNotFound)
               {
                  NSLog(@"procedure '%@' not known in pacs %@",self, pacsUID);
                  return @[[self stringByReplacingOccurrencesOfString:@"^"withString:@"_"]];
               }
               
               if ([(pacsProcedureDict[@"scheme"])[procedureIndex]integerValue] != schemeIndex)
               {
                  LOG_VERBOSE(@"%@ found in pacs %@, but scheme does not match",self,pacsUID);
                  return @[[self stringByReplacingOccurrencesOfString:@"^"withString:@"_"]];
               }

               if ((pacsProcedureDict[@"shortname"])[procedureIndex] || [(pacsProcedureDict[@"shortname"])[procedureIndex] length])
               return @[
                        (pacsProcedureDict[@"code"])[procedureIndex],
                        (pacsProcedureDict[@"shortname"])[procedureIndex],
                        (pacsProcedureDict[@"scheme"])[procedureIndex]
                        ];
               return @[
                        (pacsProcedureDict[@"code"])[procedureIndex],
                        [[(pacsProcedureDict[@"longname"])[procedureIndex] substringToIndex:32] stringByAppendingString:@"..."],
                        (pacsProcedureDict[@"scheme"])[procedureIndex]
                        ];
            }
            
            //verify if it is a known spsxprotocol code^*^scheme
            NSUInteger codeIndex=[(K.codeindexes[scheme])[@"key"] indexOfObject:code];
            if (codeIndex !=NSNotFound)
            {
               return @[
                        code,
                        (K.codeindexes[scheme])[@"meaning"],
                        scheme
                        ];
            }
            NSLog(@"code '%@' not known",self);
            return @[[self stringByReplacingOccurrencesOfString:@"^"withString:@"_"]];
         }
            break;
         
         default:
            NSLog(@"Not a code^meaning^scheme (%lu ^ in %@)",[array count]-1,self);
            return @[[self stringByReplacingOccurrencesOfString:@"^"withString:@"_"]];
            break;
      }
   }
   NSLog(@"| not authorized in study description");
   return nil;
}

-(NSArray*)protocolCodeArray
{
   return [self procedureCodeArrayForContextPacs:nil];
}


-(NSString*)regexQuoteEscapedString
{
   /*
    NSCaseInsensitiveSearch
    NSLiteralSearch: Exact character-by-character equivalence
    NSBackwardsSearch
    NSAnchoredSearch: Search is limited to start (or end, if NSBackwardsSearch) of source string.
    NSNumericSearch: Numbers within strings are compared using numeric value, that is, Name2.txt < Name7.txt < Name25.txt.
    NSDiacriticInsensitiveSearch
    NSWidthInsensitiveSearch: Search ignores width differences in characters that have full-width and half-width forms, as occurs in East Asian character sets.
    NSForcedOrderingSearch: Comparisons are forced to return either NSOrderedAscending or NSOrderedDescending if the strings are equivalent but not strictly equal.
    NSRegularExpressionSearch: The search string is treated as an ICU-compatible regular expression. If set, no other options can apply except NSCaseInsensitiveSearch and NSAnchoredSearch. You can use this option only with the rangeOfString:… methods and
    stringByReplacingOccurrencesOfString:withString:options:range:
    .
    */
   
   //string delimiters become char joker
   NSMutableString *escapedString=[NSMutableString stringWithString:self];
   NSUInteger escapesPerformed=0;
   escapesPerformed+=[escapedString
    replaceOccurrencesOfString:@"'"
    withString:@"."
    options:0
    range:NSMakeRange(0, escapedString.length)
    ];
   escapesPerformed+=[escapedString
    replaceOccurrencesOfString:@"\""
    withString:@"."
    options:0
    range:NSMakeRange(0, escapedString.length)
    ];
   if (escapesPerformed>0) LOG_DEBUG(@"|%@| -> |%@|", self, escapedString);
   return [NSString stringWithString:escapedString];
}


-(NSString*)sqlLikeEscapedString
{
   /*
    NSCaseInsensitiveSearch
    NSLiteralSearch: Exact character-by-character equivalence
    NSBackwardsSearch
    NSAnchoredSearch: Search is limited to start (or end, if NSBackwardsSearch) of source string.
    NSNumericSearch: Numbers within strings are compared using numeric value, that is, Name2.txt < Name7.txt < Name25.txt.
    NSDiacriticInsensitiveSearch
    NSWidthInsensitiveSearch: Search ignores width differences in characters that have full-width and half-width forms, as occurs in East Asian character sets.
    NSForcedOrderingSearch: Comparisons are forced to return either NSOrderedAscending or NSOrderedDescending if the strings are equivalent but not strictly equal.
    NSRegularExpressionSearch: The search string is treated as an ICU-compatible regular expression. If set, no other options can apply except NSCaseInsensitiveSearch and NSAnchoredSearch. You can use this option only with the rangeOfString:… methods and
    stringByReplacingOccurrencesOfString:withString:options:range:
    .
    */
   
   NSMutableString *escapedString=[NSMutableString stringWithString:self];
   NSUInteger escapesPerformed=0;

   //sql like wild cards escaped
   escapesPerformed+=[escapedString
    replaceOccurrencesOfString:@"_"
    withString:@"\\_"
    options:0
    range:NSMakeRange(0, escapedString.length)
    ];
   escapesPerformed+=[escapedString
    replaceOccurrencesOfString:@"%"
    withString:@"\\%"
    options:0
    range:NSMakeRange(0, escapedString.length)
    ];

   //sql and json string delimiters transformed in char joker
   escapesPerformed+=[escapedString
    replaceOccurrencesOfString:@"'"
    withString:@"_"
    options:0
    range:NSMakeRange(0, escapedString.length)
    ];
   escapesPerformed+=[escapedString
    replaceOccurrencesOfString:@"\""
    withString:@"_"
    options:0
    range:NSMakeRange(0, escapedString.length)
    ];
   
   if (escapesPerformed>0) LOG_DEBUG(@"|%@| -> |%@|", self, escapedString);
   if ((self.length - escapesPerformed > 4) || (escapesPerformed == 0))
   return [NSString stringWithString:escapedString];
   return nil;
}

-(NSString*)sqlEqualEscapedString
{
   /*
    NSCaseInsensitiveSearch
    NSLiteralSearch: Exact character-by-character equivalence
    NSBackwardsSearch
    NSAnchoredSearch: Search is limited to start (or end, if NSBackwardsSearch) of source string.
    NSNumericSearch: Numbers within strings are compared using numeric value, that is, Name2.txt < Name7.txt < Name25.txt.
    NSDiacriticInsensitiveSearch
    NSWidthInsensitiveSearch: Search ignores width differences in characters that have full-width and half-width forms, as occurs in East Asian character sets.
    NSForcedOrderingSearch: Comparisons are forced to return either NSOrderedAscending or NSOrderedDescending if the strings are equivalent but not strictly equal.
    NSRegularExpressionSearch: The search string is treated as an ICU-compatible regular expression. If set, no other options can apply except NSCaseInsensitiveSearch and NSAnchoredSearch. You can use this option only with the rangeOfString:… methods and
    stringByReplacingOccurrencesOfString:withString:options:range:
    .
    */
   
   NSMutableString *escapedString=[NSMutableString stringWithString:self];
   NSUInteger escapesPerformed=0;

   //sql and json string delimiters transformed in char joker
   escapesPerformed+=[escapedString
    replaceOccurrencesOfString:@"'"
    withString:@"_"
    options:0
    range:NSMakeRange(0, escapedString.length)
    ];
   escapesPerformed+=[escapedString
    replaceOccurrencesOfString:@"\""
    withString:@"_"
    options:0
    range:NSMakeRange(0, escapedString.length)
    ];
   
   if (escapesPerformed>0) LOG_DEBUG(@"|%@| -> |%@|", self, escapedString);
   if ((self.length - escapesPerformed > 4) || (escapesPerformed == 0))
   return [NSString stringWithString:escapedString];
   return nil;
}

-(NSString*)removeTrailingCarets
{
    if ([self hasSuffix:@"^"])
    {
        return [[self substringToIndex:self.length - 1] removeTrailingCarets];
    }
    return self;
}

-(NSString*)removeFirstSpaces
{
    if ([self hasPrefix:@" "])
    {
        return [[self substringFromIndex: 1] removeFirstSpaces];
    }
    return self;
}

-(NSString*)removeLastSpaces
{
    if ([self hasSuffix:@" "])
    {
        return [[self substringToIndex:self.length - 1] removeLastSpaces];
    }
    return self;
}

-(NSString*)removeFirstAndLastSpaces
{
    return [[self removeFirstSpaces] removeLastSpaces];
}

@end


