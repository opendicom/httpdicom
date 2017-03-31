#import "RSHandler.h"

@implementation RSHandler

@synthesize matchBlock=_matchBlock, asyncProcessBlock=_asyncProcessBlock;

- (id)initWithMatchBlock:(RSMatchBlock)matchBlock
       asyncProcessBlock:(RSAsyncProcessBlock)processBlock {
    if ((self = [super init])) {
        _matchBlock = [matchBlock copy];
        _asyncProcessBlock = [processBlock copy];
    }
    return self;
}

@end
