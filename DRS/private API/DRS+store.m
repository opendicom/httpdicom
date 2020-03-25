#import "DRS+store.h"
#import "NSURLComponents+PCS.h"

enum stowContentType{
   stowContentTypeDICM,
   stowContentTypeJSON,
   stowContentTypeXML
};

@implementation DRS (store)

-(void)addPOSTstudiesHandler
{
   NSRegularExpression *stowRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\/stow(\\/[1-2](\\d)*(\\.0|\\.[1-9](\\d)*)*)\\/studies(\\/[1-2](\\d)*(\\.0|\\.[1-9](\\d)*)*)?$" options:NSRegularExpressionCaseInsensitive error:NULL];
    
   NSArray *stowContentTypeArray=
   @[
    @"multipart/related; type=application/dicom",
    @"multipart/related; type=application/dicom+json",
    @"multipart/related; type=application/dicom+xml"
    ];
   
   NSData *rnrnData=[@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
    
   [self addHandler:@"POST" regex:stowRegex processBlock:
     ^(RSRequest* request, RSCompletionBlock completionBlock){completionBlock(^RSResponse* (RSRequest* request)
   {
      NSURLComponents *urlComponents=[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
      NSString *pacsOID=[urlComponents.path componentsSeparatedByString:@"/"][2];
      
      
      if ([DRS.wan indexOfObject:pacsOID] != NSNotFound)
      {
          return [RSErrorResponse responseWithClientError:404 message:@"%@ [{pacs} needs to be forwarded]",pacsOID];
      }
        
      //find entityDict
      NSDictionary *entityDict=DRS.pacs[pacsOID];
      if (!entityDict) return [RSErrorResponse responseWithClientError:404 message:@"%@ [{pacs} not found]",pacsOID];
        
//known destination PACS
        
        
      NSUInteger stowContentType=[stowContentTypeArray indexOfObject:request.contentType];
      if (stowContentType==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"%@ [{content-type} not found]",request.contentType];
 
        
        //format
        
        // \r\n--%@
        // \r\nContent-Type:application/dicom
        // \r\n\r\n
        // data
        // \r\n--%@
        // --\r\n

        
      NSData *boundaryData=[[@"\r\n--" stringByAppendingString:request.headers[@"boundary"]] dataUsingEncoding:NSASCIIStringEncoding];

       NSRange remainingRange=NSMakeRange(0,request.data.length);
        NSUInteger contentsOffset=0;//offset of the contents of a part
      
        while (remainingRange.length > 0)
        {
           NSRange boundaryBeginRange=
           [request.data
            rangeOfData:boundaryData
            options:0
            range:remainingRange
            ];
           if (boundaryBeginRange.location==NSNotFound) remainingRange.length=0;//past last boundary
           else
           {
              //if there was an offset, process the content
              if (contentsOffset!=0)
              {
                 NSData *contents=[request.data subdataWithRange:NSMakeRange(contentsOffset, boundaryBeginRange.location - 1)];
                 switch (stowContentType) {
                       
                    case stowContentTypeXML:{
                       //convert
                    } break;
                    case stowContentTypeJSON:{
                       //convert
                    } break;
                       
                    case stowContentTypeDICM:
                    default:{
                    } break;
                 }
                 //send
                 //@"pacsaet"
                 //@"DICMip"
                 //@"DICMport"

              }
              
              //find the offset
              NSRange boundaryEndRange=
              [request.data
               rangeOfData:rnrnData
               options:0
               range:remainingRange
               ];
              //contentsOffset=
        
           }
       }

         


      return [RSErrorResponse responseWithClientError:404 message:@"[wadors] pacs %@ not available",pacsOID];
      
  }(request));}];

}

@end
