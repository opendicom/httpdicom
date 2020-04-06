#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface mllpSend : NSObject

+(bool)sendIP:ipString
         port:portString
      message:(NSString*)message
stringEncoding:(NSStringEncoding)stringEncoding
      payload:(NSMutableString*)payload
;


+(bool)sendIP:ipString
         port:portString
  messageData:(NSData*)messageData
  payloadData:(NSMutableData*)payloadData
;


@end

NS_ASSUME_NONNULL_END
