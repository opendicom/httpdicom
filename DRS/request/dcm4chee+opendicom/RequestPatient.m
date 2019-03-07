#import "RequestPatient.h"

#import "NSMutableURLRequest+DRS.h"

@implementation RequestPatient

+(NSMutableURLRequest*)existsInPacs:(NSDictionary*)pacs
                                pid:(NSString*)pid
                             issuer:(NSString*)issuer
                   returnAttributes:(BOOL)returnAttributes

{
   NSMutableString *URLString=nil;   
   if (issuer)
      URLString=[NSMutableString stringWithFormat:@"%@/rs/patients?PatientID=%@&IssuerOfPatientID=%@&includefield=00100021&includefield=00080090",
         pacs[@"dcm4cheelocaluri"],
         pid,
         issuer
         ];
   else
      URLString=[NSMutableString stringWithFormat:@"%@/rs/patients?PatientID=%@&IssuerOfPatientID=%@&includefield=00100021&includefield=00080090",
         pacs[@"dcm4cheelocaluri"],
         pid
         ];
   
   //GET or HEAD?
   if ((returnAttributes==false) && [pacs[@"headavailable"]boolValue])
      return [NSMutableURLRequest DRSRequestPacs:pacs
                                       URLString:URLString
                                          method:@"HEAD"
                                     contentType:nil
                                        bodyData:nil
                                          accept:@""
              ];


   return [NSMutableURLRequest DRSRequestPacs:pacs
                                    URLString:URLString
                                       method:@"GET"
                                  contentType:nil
                                     bodyData:nil
                                       accept:@""
           ];

}
@end
