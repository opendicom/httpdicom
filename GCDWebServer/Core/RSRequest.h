#import <Foundation/Foundation.h>

/**
 *  Attribute key asociated to an NSArray containing NSStrings from a RSRequest with the contents of any regular expression captures done on the request path.
    @warning This attribute will only be set on the request if adding a handler using  -addHandlerForMethod:pathRegex:requestClass:processBlock:.
 */
extern NSString* const RSRequestAttribute_RegexCaptures;


/**
 *  This protocol is used by the RSConnection to communicate with
 *  the RSRequest and write the received HTTP body data.
 *
 *  Note that multiple RSBodyWriter objects can be chained together
 *  internally e.g. to automatically decode gzip encoded content before
 *  passing it on to the RSRequest.
 *
 *  @warning These methods can be called on any GCD thread.
 */
@protocol RSBodyWriter <NSObject>
//returns YES on success
//or NO on failure and set the "error" argument which is guaranteed to be non-NULL.

//called before any body data is received.
- (BOOL)open:(NSError**)error;
//called whenever body data has been received.
- (BOOL)writeData:(NSData*)data error:(NSError**)error;
//called after all body data has been received.
- (BOOL)close:(NSError**)error;
@end

/**
 *  The RSRequest class is instantiated by the RSConnection
 *  after the HTTP headers have been received. Each instance wraps a single HTTP
 *  request. If a body is present, the methods from the RSBodyWriter
 *  protocol will be called by the RSConnection to receive it.
 *
 *  The default implementation of the RSBodyWriter protocol on the class  simply ignores the body data.
 *
 *  @warning RSRequest instances can be created and used on any GCD thread.
 */
@interface RSRequest : NSObject <RSBodyWriter>

@property(nonatomic, readonly) NSString* method;
@property(nonatomic, readonly) NSURL* URL;
@property(nonatomic, readonly) NSDictionary* headers;
@property(nonatomic, readonly) NSString* path;
@property(nonatomic, readonly) NSDictionary* query;
@property(nonatomic, readonly) NSString* contentType;
@property(nonatomic, readonly) NSUInteger contentLength;
@property(nonatomic, readonly) NSDate* ifModifiedSince;
@property(nonatomic, readonly) NSString* ifNoneMatch;
@property(nonatomic, readonly) NSRange byteRange;
@property(nonatomic, readonly) BOOL acceptsGzipContentEncoding;

/**
 *  Returns the address of the local peer (i.e. server) for the request
 *  as a raw "struct sockaddr".
 */
@property(nonatomic, readonly) NSData* localAddressData;
@property(nonatomic, readonly) NSString* localAddressString;

/**
 *  Returns the address of the remote peer (i.e. client) for the request
 *  as a raw "struct sockaddr".
 */
@property(nonatomic, readonly) NSData* remoteAddressData;
@property(nonatomic, readonly) NSString* remoteAddressString;
- (BOOL)hasBody;
- (BOOL)hasByteRange;



/**
 *  This method is the designated initializer for the class.
 */
- (instancetype)initWithMethod:(NSString*)method url:(NSURL*)url headers:(NSDictionary*)headers path:(NSString*)path query:(NSDictionary*)query;

/**
 *  Retrieves an attribute associated with this request using the given key.
 *
 *  @return The attribute value for the key.
 */
- (id)attributeForKey:(NSString*)key;

@end

@interface RSRequest ()
@property(nonatomic, readonly) BOOL usesChunkedTransferEncoding;
@property(nonatomic, readwrite) NSData* localAddressData;
@property(nonatomic, readwrite) NSData* remoteAddressData;
- (void)prepareForWriting;
- (BOOL)performOpen:(NSError**)error;
- (BOOL)performWriteData:(NSData*)data error:(NSError**)error;
- (BOOL)performClose:(NSError**)error;
- (void)setAttribute:(id)attribute forKey:(NSString*)key;
@end
