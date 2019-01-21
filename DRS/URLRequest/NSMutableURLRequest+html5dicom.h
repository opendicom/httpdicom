#import <Foundation/Foundation.h>

@interface NSMutableURLRequest (html5dicom)

+(id)POSThtml5dicomuserRequest:(NSString*)URLString
                   institution:(NSString*)institution
                      username:(NSString*)username
                      password:(NSString*)password
                     firstname:(NSString*)firstname
                      lastname:(NSString*)lastname
                      isactive:(BOOL)isactive
                       timeout:(NSTimeInterval)timeout
;

@end
