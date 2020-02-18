#import <Foundation/Foundation.h>

//NS_ASSUME_NONNULL_BEGIN

/*
 <xsd:attribute name="SOPInstanceUID" type="dicomVrUI"
    use="required" />
 <xsd:attribute name="InstanceNumber" type="dicomVrIS" />
 <xsd:attribute name="DirectDownloadFile" type="xsd:string" />
 */

@interface WeasisInstance : NSXMLElement

+(NSXMLElement*)key:(NSString*)key
weasisInstanceNumber:(NSString*)weasisInstanceNumber
NumberOfFrames:(NSString*)NumberOfFrames
weasisSOPClassUID:(NSString*)weasisSOPClassUID
weasisSOPInstanceUID:(NSString*)weasisSOPInstanceUID
weasisDirectDownloadFile:(NSString*)weasisDirectDownloadFile
;

@end

//NS_ASSUME_NONNULL_END
