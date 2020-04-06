#import <Foundation/Foundation.h>

//? = optional (nil accepted)
NS_ASSUME_NONNULL_BEGIN

//https://dcm4chee-arc-hl7cs.readthedocs.io/en/latest/orm/inbound.html#tab-zds-orm-omg

@interface NSString(ZDS)

+(NSString*)
   isrStudyIUID:(NSString*)ZDS_1 //?
;

@end

NS_ASSUME_NONNULL_END
