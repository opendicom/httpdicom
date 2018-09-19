#import "DRSOperation.h"
#import "ODLog.h"


@implementation DRSOperation

@synthesize ready = _ready;
@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.ready = YES;
    }
    return self;
}


- (void)setReady:(BOOL)ready
{
    if (_ready != ready)
    {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isReady))];
        _ready = ready;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isReady))];
    }
}

- (BOOL)isReady
{
    return _ready;
}

#pragma mark -

- (void)setExecuting:(BOOL)executing
{
    if (_executing != executing)
    {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
        _executing = executing;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
    }
}

- (BOOL)isExecuting
{
    return _executing;
}

#pragma mark -

- (void)setFinished:(BOOL)finished
{
    if (_finished != finished)
    {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
        _finished = finished;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
    }
}

- (BOOL)isFinished
{
    return _finished;
}

#pragma mark -

- (BOOL)isAsynchronous
{
    return YES;
}

#pragma mark -

- (void)start
{
    if (!self.isExecuting)
    {
        self.ready = NO;
        self.executing = YES;
        self.finished = NO;
        
        LOG_DEBUG(@"%@ started", self.name);
    }
}

- (void)finish
{
    if (self.executing)
    {
        LOG_DEBUG(@"%@ finished", self.name);
        
        self.executing = NO;
        self.finished = YES;
    }
}

@end
