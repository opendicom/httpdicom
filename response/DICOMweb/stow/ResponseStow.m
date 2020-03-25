#import "ResponseStow.h"
#import "RequestStow.h"
#import "ODLog.h"

#import "NSDictionary+DICM.h"
#import "NSMutableDictionary+DICM.h"
#import "NSMutableData+DICM.h"
#import "NSUUID+DICM.h"

@implementation ResponseStow

//returns @"" when stow was successfull
//returns @"error message" or nil if the server responded with an error
+(NSString*)singleBodyToPacs:(NSDictionary*)pacs
                dicomSubtype:(NSString*)dicomSubType
              boundaryString:(NSString*)boundaryString
                    bodyData:(NSData*)bodyData
{
   return nil;
}

//returns @"" when stow was successfull
//returns @"error message" or nil if the server responded with an error
//caso particular que crea la instancia DICM (binario)
+(NSString*)singleEnclosedDICMToPacs:(NSDictionary*)pacs
                                  CS:(NSString*)CS
                                  DA:(NSString*)DA
                                  TM:(NSString*)TM
                                  TZ:(NSString*)TZ
                            modality:(NSString*)modality
                     accessionNumber:(NSString*)accessionNumber
                     accessionIssuer:(NSString*)accessionIssuer
                       accessionType:(NSString*)accessionType
                    studyDescription:(NSString*)studyDescription
                      procedureCodes:(NSArray*)procedureCodes
                           referring:(NSString*)referring
                             reading:(NSString*)reading
                                name:(NSString*)name
                                 pid:(NSString*)pid
                              issuer:(NSString*)issuer
                           birthdate:(NSString*)birthdate
                                 sex:(NSString*)sex
                         instanceUID:(NSString*)instanceUID
                           seriesUID:(NSString*)seriesUID
                            studyUID:(NSString*)studyUID
                        seriesNumber:(NSString*)seriesNumber
                   seriesDescription:(NSString*)seriesDescription
                      enclosureHL7II:(NSString*)enclosureHL7II
                      enclosureTitle:(NSString*)enclosureTitle
             enclosureTransferSyntax:(NSString*)enclosureTransferSyntax
                       enclosureData:(NSData*)enclosureData
                         contentType:(NSString*)contentType
{
   if ([contentType isEqualToString:@"application/dicom"])
   {
     //request
      NSMutableURLRequest *request=[RequestStow
                                    singleEnclosedDICMToPacs:pacs
                                    CS:CS
                                    DA:DA
                                    TM:TM
                                    TZ:TZ
                                    modality:modality
                                    accessionNumber:accessionNumber
                                    accessionIssuer:accessionIssuer
                                    accessionType:accessionType
                                    studyDescription:studyDescription
                                    procedureCodes:procedureCodes
                                    referring:referring
                                    reading:reading
                                    name:name
                                    pid:pid
                                    issuer:issuer
                                    birthdate:birthdate
                                    sex:sex
                                    instanceUID:instanceUID
                                    seriesUID:seriesUID
                                    studyUID:studyUID
                                    seriesNumber:seriesNumber
                                    seriesDescription:seriesDescription
                                    enclosureHL7II:enclosureHL7II
                                    enclosureTitle:enclosureTitle
                                    enclosureTransferSyntax:enclosureTransferSyntax
                                    enclosureData:enclosureData
                                    contentType:contentType
                                    ];
      if (request==nil) return nil;
      
      NSHTTPURLResponse *response=nil;
      NSError *error=nil;
      NSData *responseData=[NSURLSessionDataTask sendSynchronousRequest:request returningResponse:&response error:&error];
      
      
      NSString *responseString=nil;
      if (!responseData) responseString=@"no response data";
      else if ([responseData length]) responseString=[[NSString alloc]initWithData:responseData encoding:NSUTF8StringEncoding];
      else responseString=@"";
      
      if ([responseString length] || response.statusCode>299)
      {
         //Failure
         //=======
         //400 - Bad Request (bad syntax)
         //401 - Unauthorized
         //403 - Forbidden (insufficient priviledges)
         //409 - Conflict (formed correctly - system unable to store due to a conclict in the request
         //(e.g., unsupported SOP Class or StudyInstance UID mismatch)
         //additional information can be found in teh xml response body
         //415 - unsopported media type (e.g. not supporting JSON)
         //500 (instance already exists in db - delete file)
         //503 - Busy (out of resource)
         
         //Warning
         //=======
         //202 - Accepted (stored some - not all)
         //additional information can be found in teh xml response body
         
         //Success
         //=======
         //200 - OK (successfully stored all the instances)
         
         
         LOG_ERROR(@"stow error: %@\r\n response body: %@",[error description], responseString);
         return [NSString stringWithFormat:@"can not POST CDA. Error: %@ Response body:%@",[error description], responseString];
      }
      LOG_VERBOSE(@"stow <- %ld",response.statusCode);
      return @"";
   }
   
   return [NSString stringWithFormat:@"[%@] not available. application/dicom is the only content-type implemented yet",contentType];
}

@end
