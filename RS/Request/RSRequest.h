#import "RSBodyWriterProtocol.h"

/**
 *  The RSRequest class is instantiated by the RSConnection
 *  after the HTTP headers have been received. Each instance wraps a single HTTP
 *  request. If a body is present, the methods from the RSBodyWriter
 *  protocol will be called by the RSConnection to receive it.
 *
 *  The default implementation of the RSBodyWriter protocol on the class  simply ignores the body data.
 *
 *  RSRequest instances can be created and used on any GCD thread.
 */

@interface RSRequest : NSObject <RSBodyWriter>
{
    NSString* _method;
    NSURL* _url;
    NSDictionary* _headers;
    NSString* _path;
    NSDictionary* _query;
    NSString* _type;
    BOOL _chunked;
    NSUInteger _length;
    NSDate* _modifiedSince;
    NSString* _noneMatch;
    NSRange _range;
    BOOL _gzipAccepted;
    NSString* _localAddressString;
    NSString* _remoteAddressString;
    
    BOOL _opened;
    NSMutableArray* _decoders;
    NSMutableDictionary* _attributes;
    id<RSBodyWriter> __unsafe_unretained _writer;
}

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
@property(nonatomic, readonly) BOOL usesChunkedTransferEncoding;

//request keeps the string form and connection the data
//the string is available for request block
@property(nonatomic, readwrite) NSString* localAddressString;
@property(nonatomic, readwrite) NSString* remoteAddressString;

- (BOOL)hasBody;
- (BOOL)hasByteRange;

//designated initializer
- (instancetype)initWithMethod:(NSString*)method
                           url:(NSURL*)url
                       headers:(NSDictionary*)headers
                          path:(NSString*)path
                         query:(NSDictionary*)query
                         local:(NSString*)localAddressString
                        remote:(NSString*)remoteAddressString;
- (id)attributeForKey:(NSString*)key;
- (void)prepareForWriting;
- (BOOL)performOpen:(NSError**)error;
- (BOOL)performWriteData:(NSData*)data error:(NSError**)error;
- (BOOL)performClose:(NSError**)error;
- (void)setAttribute:(id)attribute forKey:(NSString*)key;

@end
