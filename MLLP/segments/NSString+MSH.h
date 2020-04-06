#import <Foundation/Foundation.h>

//? = optional (nil accepted)
//NS_ASSUME_NONNULL_BEGIN
@interface NSString(MSH)

//reference
//https://dcm4chee-arc-hl7cs.readthedocs.io/en/latest/hl7-impl-notes.html#hl7-v2-3-1-message-implementation-requirements

+(NSString*)
   sendingApplication  :(NSString*)MSH_3
   sendingFacility     :(NSString*)MSH_4
   receivingApplication:(NSString*)MSH_5
   receivingFacility   :(NSString*)MSH_6
   messageType         :(NSString*)MSH_9
   messageControlID    :(NSString*)MSH_10
   versionID           :(NSString*)MSH_12
   countryCode         :(NSString*)MSH_17
   stringEncoding      :(NSStringEncoding)stringEncoding
   principalLanguage   :(NSString*)MSH_19
;

/*
stringEncoding
 case 1: @"ASCII";
 case 4: @"UNICODE UTF-8";
 case 5:
 default:@"8859/1";
 */

@end
//NS_ASSUME_NONNULL_END
