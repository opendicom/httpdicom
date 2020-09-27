#import "RequestPatients.h"
#import "NSMutableURLRequest+DRS.h"

@implementation RequestPatients

+(NSMutableURLRequest*)getFromPacs:(NSDictionary*)pacs
                             patID:(NSString*)patID
                            issuer:(NSString*)issuer
{
   if (!pacs[@"dcm4cheelocaluri"] || ![pacs[@"dcm4cheelocaluri"] length]) return nil;
   if (!patID || ![patID length]) return nil;

   NSMutableString *URLString=nil;
   if (issuer && [issuer length])
      URLString=[NSMutableString stringWithFormat:@"%@/rs/patients?PatientID=%@&IssuerOfPatientID=%@&includefield=00100021&includefield=00080090",
         pacs[@"dcm4cheelocaluri"],
         patID,
         issuer
         ];
   else
      URLString=[NSMutableString stringWithFormat:@"%@/rs/patients?PatientID=%@&includefield=00100021&includefield=00080090",
         pacs[@"dcm4cheelocaluri"],
         patID
         ];
   
   return [NSMutableURLRequest DRSRequestPacs:pacs
                                    URLString:URLString
                                       method:GET
           ];
}

//DO NOT USE because dcm4chee-arc rest patient API doesn´t support latin1 encoding
//USE instead HL7 MLLP ADT
+(NSMutableURLRequest*)putToPacs:(NSDictionary*)pacs
                         family1:(NSString*)family1
                         family2:(NSString*)family2
                           given:(NSString*)given
                           patID:(NSString*)patID
                          issuer:(NSString*)issuer
                       birthdate:(NSString*)birthdate
                             sex:(NSString*)sex
                     contentType:(NSString*)contentType
{
   if (!pacs[@"dcm4cheelocaluri"] || !pacs[@"dcm4cheelocaluri"]) return nil;
   if (!patID || ![patID length]) return nil;
   if (!issuer || ![issuer length]) return nil;

   NSMutableString *URLString=[NSMutableString
    stringWithFormat:@"%@/rs/patients/%@%%5E%%5E%%5E%@",
    pacs[@"dcm4cheelocaluri"],
    patID,
    issuer
    ];

   if ([contentType isEqualToString:@"application/json"])
   {
      NSMutableString *json=[NSMutableString string];
      [json appendString:@"{\"00080005\": {\"vr\":\"CS\",\"Value\":[\"ISO_IR 192\"]},"];//utf8
      NSMutableString *name=[NSMutableString stringWithString:family1];
      if ([family2 length]) [name appendFormat:@">%@",family2];
      if ([given length]) [name appendFormat:@"^%@",given];
      [json appendFormat:@"\"00100010\":{\"vr\":\"PN\",\"Value\":[{\"Alphabetic\":\"%@\"}]},",name];
      [json appendFormat:@"\"00100020\":{\"vr\":\"SH\",\"Value\":[\"%@\"]},",patID];
      [json appendFormat:@"\"00100021\":{\"vr\":\"LO\",\"Value\":[\"%@\"]},",issuer];
      [json appendFormat:@"\"00100030\":{\"vr\":\"DA\",\"Value\":[\"%@\"]},",birthdate];
      [json appendFormat:@"\"00100040\":{\"vr\":\"CS\",\"Value\":[\"%@\"]}}",sex];
      if ([family2 length])
         [json appendFormat:@"\"00101060\":{\"vr\":\"PN\",\"Value\":[{\"Alphabetic\":\"%@\"}]},",family2];

      return [NSMutableURLRequest
              DRSRequestPacs:pacs
              URLString:URLString
              method:PUT
              contentType:contentType
              bodyData:[json dataUsingEncoding:NSUTF8StringEncoding]
              ];
   }
   return nil;
}

/*
+(NSMutableURLRequest*)postHtml5dicomuserForPacs:(NSDictionary*)pacs
                                     institution:(NSString*)institution
                                        username:(NSString*)username
                                        password:(NSString*)password
                                       firstname:(NSString*)firstname
                                        lastname:(NSString*)lastname
                                        isactive:(BOOL)isactive
{
   
   if (!pacs[@"html5dicomuserserviceuri"] || ![pacs[@"html5dicomuserserviceuri"] length]) return nil;
   
   NSMutableString *json=[NSMutableString stringWithString:@"{"];
   [json appendFormat:@"\"institution\":\"%@\",",institution];
   [json appendFormat:@"\"username\":\"%@\",",username];
   if (password)[json appendFormat:@"\"password\":\"%@\",",password];
   [json appendFormat:@"\"first_name\":\"%@\",",firstname];
   [json appendFormat:@"\"last_name\":\"%@\",",lastname];
   if (isactive) [json appendString:@"\"is_active\":true}"];
   else [json appendString:@"\"is_active\":false}"];

   

   return [NSMutableURLRequest
           DRSRequestPacs:pacs
           URLString:pacs[@"html5dicomuserserviceuri"]
           method:POST
           contentType:@"application/json"
           bodyData:[json dataUsingEncoding:NSUTF8StringEncoding]
           ];
}
*/
@end
