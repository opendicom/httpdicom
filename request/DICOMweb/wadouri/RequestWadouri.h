#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RequestWadouri : NSObject


/*
//part 18 B.2 DICOM SR in HTML
+(NSMutableURLRequest*)requestSRFromPacs:(NSDictionary*)pacs
                        StudyInstanceUID:(NSString*)euid
                       SeriesInstanceUID:(NSString*)suid
                          SOPInstanceUID:(NSString*)iuid
                                 charset:(NSString*)charset
;//charset=UTF-8
*/

/*
//part 18 B.3 Rendered Region of a DICOM Image
+(NSMutableURLRequest*)requestCROPFromPacs:(NSDictionary*)pacs
                          StudyInstanceUID:(NSString*)euid
                         SeriesInstanceUID:(NSString*)suid
                            SOPInstanceUID:(NSString*)iuid
                           acceptMediaType:(NSString*)mediaType
                                annotation:(NSArray*)annotation
                                   columns:(NSUInteger*)columns
                                      rows:(NSUInteger*)rows
                                    region:(NSRect)region
                              windowCenter:(NSInteger*)windowCenter
                               windowWidth:(NSInteger*)windowWidth
;
*/

//part 18 B.4 DICOM Media Type
//&contentType=application%2Fdicom
+(NSMutableURLRequest*)requestDICMFromPacs:(NSDictionary*)pacs
                                      EUID:(NSString*)euid
                                      SUID:(NSString*)suid
                                      IUID:(NSString*)iuid
;//&&anonymize=no&amp;transferSyntax=* (pacs storage default syntax)


+(NSMutableURLRequest*)requestDICMFromPacs:(NSDictionary*)pacs
                                      EUID:(NSString*)euid
                                      SUID:(NSString*)suid
                                      IUID:(NSString*)iuid
                                 anonymize:(BOOL)anonymize
                            transferSyntax:(NSString*)transferSyntax
;


//part 18 B.1 Simple DICOM image in JPEG
+(NSMutableURLRequest*)requestDefaultJPEGFromPacs:(NSDictionary*)pacs
                                             EUID:(NSString*)euid
                                             SUID:(NSString*)suid
                                             IUID:(NSString*)iuid
;


+(NSMutableURLRequest*)requestMIMEFromPacs:(NSDictionary*)pacs
                                      EUID:(NSString*)euid
                                      SUID:(NSString*)suid
                                      IUID:(NSString*)iuid
                           acceptMediaType:(NSString*)mediaType
;

/*
 mediaTypes accepted
 ===================
 
 image/jpeg (default)
 image/gif (single or multi frame)
 image/png
 image/jp2
 
 video/mpeg
 video/mp4
 video/H265
 
 text/html
 text/plain
 text/xml
 text/rtf
 
 application/pdf
 
 
 Opendicom additions for encapsulated
 ------------------------------------
 
 text/x-dscd+xml
 text/x-scd+xml
 text/x-cda+xml
 */

@end

NS_ASSUME_NONNULL_END
