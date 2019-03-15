#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface mllpSend : NSObject

+(bool)sendIP:ipString
         port:portString
      message:(NSString*)message
stringEncoding:(NSStringEncoding)stringEncoding
      payload:(NSMutableString*)payload
;


@end

NS_ASSUME_NONNULL_END
