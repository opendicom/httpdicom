#import "RequestStow.h"
#import "NSMutableURLRequest+DRS.h"

#import "NSDictionary+DICM.h"
#import "NSMutableDictionary+DICM.h"
#import "NSMutableData+DICM.h"
#import "NSUUID+DICM.h"


@implementation RequestStow

const UInt32        tag00020000mwl     = 0x02;
const UInt32        vrULmonovaluedmwl  = 0x044C55;

+(NSMutableURLRequest*)singleBodyToPacs:(NSDictionary*)pacs
                           dicomSubtype:(NSString*)dicomSubType
                         boundaryString:(NSString*)boundaryString
                               bodyData:(NSData*)bodyData
{
   if (!pacs[@"stow"] || ![pacs[@"stow"] length]) return nil;
   return [NSMutableURLRequest
           DRSRequestPacs:pacs
           URLString:[NSMutableString
                      stringWithFormat:@"%@/studies",
                      pacs[@"stow"]
                      ]
           method:POST
           contentType:[NSString stringWithFormat:@"multipart/related; type=application/dicom%@; boundary=%@",dicomSubType,boundaryString]
           bodyData:bodyData
           ];
}

+(NSMutableURLRequest*)singleEnclosedDimseToPacs:(NSDictionary*)pacs
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
   //aet empty
   //enclosure HL7II
   //enclosureTitle
   //procScheme change to independient
   
   if (!pid || ![pid length]) return nil;
   if (!issuer || ![issuer length]) return nil;
   if ([contentType isEqualToString:@"application/dicom"])
   {
      //minimal format, one step with accessionNumber=procid=stepid=studyiuid
      NSMutableDictionary *metainfo=[NSMutableDictionary dictionary];
      [metainfo addEntriesFromDictionary:[NSDictionary
                                          DICM0002ForMediaStorageSOPClassUID:@"1.2.840.10008.5.1.4.1.1.104.2"
                                          mediaStorageSOPInstanceUID:instanceUID
                                          implementationClassUID:@""
                                          implementationVersionName:@""
                                          sourceApplicationEntityTitle:@""
                                          privateInformationCreatorUID:@""
                                          privateInformation:nil]];
      NSMutableData *metainfoData=[NSMutableData DICMDataGroup2WithDICMDictionary:metainfo];
      
      NSMutableDictionary *dicm=[NSMutableDictionary dictionary];
      
      //DICMC120100    SOP Common
      [dicm addEntriesFromDictionary:[NSDictionary
                                      DICMC120100ForSOPClassUID1:@"1.2.840.10008.5.1.4.1.1.104.2"
                                      SOPInstanceUID1:instanceUID
                                      charset1:CS
                                      DA1:DA
                                      TM1:TM
                                      TZ:TZ]];
      
      //DICMC070101    Patient
      [dicm addEntriesFromDictionary:[NSDictionary
                                      DICMC070101PatientWithName:name
                                      pid:pid
                                      issuer:issuer
                                      birthdate:birthdate
                                      sex:sex]];
      
      //DICMC070201    General Study
      [dicm addEntriesFromDictionary:[NSDictionary
                                      DICMC070201StudyWithUID:studyUID
                                      DA:DA
                                      TM:TM
                                      ID:@""
                                      AN:accessionNumber
                                      ANLocal:nil
                                      ANUniversal:nil
                                      ANUniversalType:nil
                                      description:studyDescription
                                      procedureCodes:procedureCodes
                                      referring:referring
                                      reading:reading]];
      
      
      //DICMC240100    Encapsulated Series
      [dicm addEntriesFromDictionary:[NSDictionary
                                      DICMC240100ForModality1:@"OT"
                                      seriesUID1:seriesUID
                                      seriesNumber2:@"-32"
                                      seriesDA3:DA
                                      seriesTM3:TM
                                      seriesDescription3:seriesDescription]];
      
      //DICMC070501    General Equipment
      [dicm addEntriesFromDictionary:[NSDictionary DICMC070501ForInstitution:accessionIssuer]];
      
      //DICMC080601    SC Equipment
      [dicm addEntriesFromDictionary:[NSDictionary
                                      DICMC080601ForConversionType1:@"WSD"]];
      
      //DICMC240200    Encapsulated Document
      [dicm addEntriesFromDictionary:[NSDictionary
                                      DICMC240200EncapsulatedCDAWithDA:DA
                                      TM:TM
                                      title:enclosureTitle
                                      HL7II:enclosureHL7II
                                      data:enclosureData]];
      
      
      //MutableDictionary -> NSMutableData
      
      NSString *boundaryString=[[NSUUID UUID]UUIDString];
      
      NSMutableData *stowData=[NSMutableData data];
      
      [stowData appendData:[[NSString stringWithFormat:@"\r\n--%@\r\nContent-Type:application/dicom\r\n\r\n",boundaryString] dataUsingEncoding:NSASCIIStringEncoding]];
      
      [stowData increaseLengthBy:128];
      [stowData appendDICMSignature];
      
      UInt32 count00020000 = (UInt32)[metainfoData length];
      [stowData appendBytes:&tag00020000mwl    length:4];
      [stowData appendBytes:&vrULmonovaluedmwl length:4];
      [stowData appendBytes:&count00020000  length:4];
      [stowData appendData:metainfoData];
      
      [stowData appendData:[NSMutableData DICMDataWithDICMDictionary:dicm bulkdataBaseURI:nil]];
      
      [stowData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundaryString] dataUsingEncoding:NSASCIIStringEncoding]];
      
      return [RequestStow singleBodyToPacs:pacs
                              dicomSubtype:@""
                            boundaryString:boundaryString
                                  bodyData:stowData
              ];
   }
   return nil;
}

@end
