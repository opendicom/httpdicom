#import "GCDWebServerHandler.h"

@implementation GCDWebServerHandler

@synthesize matchBlock=_matchBlock, asyncProcessBlock=_asyncProcessBlock;

- (id)initWithMatchBlock:(GCDWebServerMatchBlock)matchBlock
       asyncProcessBlock:(GCDWebServerAsyncProcessBlock)processBlock {
    if ((self = [super init])) {
        _matchBlock = [matchBlock copy];
        _asyncProcessBlock = [processBlock copy];
    }
    return self;
}

@end
