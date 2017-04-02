#import "RSBodyEncoder.h"

@interface RSBodyEncoder () 
@end

@implementation RSBodyEncoder

- (id)initWithResponse:(RSResponse*)response reader:(id<RSBodyReader>)reader {
    if ((self = [super init])) {
        _response = response;
        _reader = reader;
    }
    return self;
}

- (BOOL)open:(NSError**)error {
    return [_reader open:error];
}

- (NSData*)readData:(NSError**)error {
    return [_reader readData:error];
}

- (void)close {
    [_reader close];
}

@end
