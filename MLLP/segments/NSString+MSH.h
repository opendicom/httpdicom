#import <Foundation/Foundation.h>

//? = optional (nil accepted)
//NS_ASSUME_NONNULL_BEGIN
@interface NSString(MSH)

//reference
//https://dcm4chee-arc-hl7cs.readthedocs.io/en/latest/hl7-impl-notes.html#hl7-v2-3-1-message-implementation-requirements

+(NSString*)
   SendingApplication  :(NSString*)MSH_3 //?
   SendingFacility     :(NSString*)MSH_4 //?
   ReceivingApplication:(NSString*)MSH_5 //?
   ReceivingFacility   :(NSString*)MSH_6 //?
   MessageType         :(NSString*)MSH_9
   MessageControlID    :(NSString*)MSH_10 //?
   VersionID           :(NSString*)MSH_12 //?
   CountryCode         :(NSString*)MSH_17 //?
   CharacterSet        :(NSStringEncoding)stringEncoding //?
   PrincipalLanguage   :(NSString*)MSH_19 //?
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
