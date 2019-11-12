#import "DRS+studyToken+enfoke.h"
#import "NSURLComponents+PCS.h"


@implementation DRS (enfoke)

-(void)addPOSTenfokePatientHandler
{
   
}


-(void)addPOSTenfokeReferringHandler
{
   NSRegularExpression *enfokeRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\/enfoke$" options:NSRegularExpressionCaseInsensitive error:NULL];
    
   [self addHandler:@"POST" regex:enfokeRegex processBlock:
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
        

      return [RSErrorResponse responseWithClientError:404 message:@"[wadors] pacs %@ not available",pacsOID];
      
  }(request));}];

}

@end
