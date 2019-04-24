#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RequestStow : NSObject

//multipart/related; type=application/dicom[dicomSubType]; boundary={messageBoundary}

// dicomSubType: @"", @"+xml", @"+json"
+(NSMutableURLRequest*)singleBodyToPacs:(NSDictionary*)pacs
                           dicomSubtype:(NSString*)dicomSubType
                         boundaryString:(NSString*)boundaryString
                               bodyData:(NSData*)bodyData
;

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
;

@end

NS_ASSUME_NONNULL_END
