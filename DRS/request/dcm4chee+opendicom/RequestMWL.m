#import "RequestMWL.h"
#import "NSMutableURLRequest+DRS.h"

@implementation RequestMWL

+(id)postToPacs:(NSDictionary*)pacs
             CS:(NSString*)CS
            aet:(NSString*)aet
             DA:(NSString*)DA
             TM:(NSString*)TM
             TZ:(NSString*)TZ
       modality:(NSString*)modality
accessionNumber:(NSString*)accessionNumber
      referring:(NSString*)referring
         status:(NSString*)status
studyDescription:(NSString*)studyDescription
       priority:(NSString*)priority
           name:(NSString*)name
            pid:(NSString*)pid
         issuer:(NSString*)issuer
      birthdate:(NSString*)birthdate
            sex:(NSString*)sex
    contentType:(NSString*)contentType
{
   if (!pacs[@"dcm4cheelocaluri"] || ![pacs[@"dcm4cheelocaluri"] length]) return nil;
   if (!pid || ![pid length]) return nil;
   if (!issuer || ![issuer length]) return nil;
   if ([contentType isEqualToString:@"application/json"])
   {
      NSMutableString *URLString=[NSMutableString stringWithFormat:@"%@/rs/mwlitems",pacs[@"dcm4cheelocaluri"]];
      
      //crear json for workitem http://dicom.nema.org/medical/Dicom/2015a/output/chtml/part03/sect_C.4.10.html
      //doesn´t indicate optional, nor mandatory metadata...
      
      //minimal format, one step with accessionNumber=procid=stepid=studyiuid
      NSMutableString *json=[NSMutableString string];
      [json appendFormat:@"{\"00080005\": {\"vr\":\"CS\",\"Value\":[\"%@\"]},",CS];
      [json appendString:@"\"00400100\": {\"vr\":\"SQ\",\"Value\":[{"];
      if ([aet length]) [json appendFormat:@"\"00400001\":{\"vr\":\"AE\",\"Value\":[\"%@\"]},",aet];
      [json appendFormat:@"\"00400002\":{\"vr\":\"DA\",\"Value\":[\"%@\"]},",DA];
      [json appendFormat:@"\"00400003\":{\"vr\":\"TM\",\"Value\":[\"%@\"]},",TM];
      [json appendFormat:@"\"00080060\":{\"vr\":\"CS\",\"Value\":[\"%@\"]},",modality];
      [json appendFormat:@"\"00400009\":{\"vr\":\"SH\",\"Value\":[\"%@\"]},",accessionNumber];//<STEPID> (=Accession Number)
      [json appendFormat:@"\"00400020\":{\"vr\":\"CS\",\"Value\":[\"%@\"]}}]},",status];
      [json appendFormat:@"\"00401001\":{\"vr\":\"SH\",\"Value\":[\"%@\"]},",accessionNumber];//<PROCID> (=Accession Number)
      if (referring)[json appendFormat:@"\"00080090\":{\"vr\":\"PN\",\"Value\":[{\"Alphabetic\":\"%@\"}]},",referring];
      [json appendFormat:@"\"00321060\":{\"vr\":\"LO\",\"Value\":[\"%@\"]},",studyDescription];
      [json appendFormat:@"\"0020000D\":{\"vr\":\"UI\",\"Value\":[\"%@\"]},",accessionNumber];//<STUDYUID>
      [json appendFormat:@"\"00401003\":{\"vr\":\"SH\",\"Value\":[\"%@\"]},",priority];
      [json appendFormat:@"\"00080050\":{\"vr\":\"SH\",\"Value\":[\"%@\"]},",accessionNumber];
      [json appendFormat:@"\"00100010\":{\"vr\":\"PN\",\"Value\":[{\"Alphabetic\":\"%@\"}]},",name];
      [json appendFormat:@"\"00100020\":{\"vr\":\"LO\",\"Value\":[\"%@\"]},",pid];
      [json appendFormat:@"\"00100021\":{\"vr\":\"LO\",\"Value\":[\"%@\"]},",issuer];
      [json appendFormat:@"\"00100030\":{\"vr\":\"DA\",\"Value\":[\"%@\"]},",birthdate];
      [json appendFormat:@"\"00100040\":{\"vr\":\"CS\",\"Value\":[\"%@\"]}}",sex];
      
      
      return [NSMutableURLRequest
              DRSRequestPacs:pacs
              URLString:[NSMutableString
                         stringWithFormat:@"%@/rs/mwlitems",
                         pacs[@"dcm4cheelocaluri"]
                         ]
              method:POST
              contentType:contentType
              bodyData:[json dataUsingEncoding:NSUTF8StringEncoding]
              ];
   }
   return nil;

}
@end
