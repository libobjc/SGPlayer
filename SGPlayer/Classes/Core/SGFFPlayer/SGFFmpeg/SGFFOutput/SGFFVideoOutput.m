//
//  SGFFVideoOutput.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFVideoOutput.h"
#import "SGFFVideoOutputRender.h"
#import "SGPlayerMacro.h"
#import "SGGLDisplayLink.h"


@interface SGFFVideoOutput ()

@property (nonatomic, strong) SGGLDisplayLink * displayLink;
@property (nonatomic, strong) SGFFVideoOutputRender * currentRender;

@end

@implementation SGFFVideoOutput

@synthesize timeSynchronizer = _timeSynchronizer;
@synthesize delegate = _delegate;
@synthesize renderSource = _renderSource;

- (SGFFOutputType)type
{
    return SGFFOutputTypeVideo;
}

- (id <SGFFOutputRender>)renderWithFrame:(id <SGFFFrame>)frame
{
    SGFFVideoOutputRender * render = [[SGFFObjectPool sharePool] objectWithClass:[SGFFVideoOutputRender class]];
    [render updateCoreVideoFrame:frame.videoFrame];
    return render;
}

- (instancetype)init
{
    if (self = [super init])
    {
        [self flush];
        SGWeakSelf
        self.displayLink = [SGGLDisplayLink displayLinkWithCallback:^{
            SGStrongSelf
            [strongSelf displayLinkHandler];
        }];
    }
    return self;
}

- (void)dealloc
{
    [self.displayLink invalidate];
    [self flush];
}

- (CMTime)currentTime
{
    return self.currentRender.position;
}

- (void)flush
{
    [self.currentRender unlock];
    self.currentRender = nil;
}

- (void)displayLinkHandler
{
    SGFFVideoOutputRender * render = nil;
    if (self.currentRender)
    {
        SGWeakSelf
        render = [self.renderSource outputFecthRender:self positionHandler:^BOOL(CMTime * current, CMTime * expect) {
            SGStrongSelf
            CMTime time = strongSelf.timeSynchronizer.position;
            NSAssert(CMTIME_IS_VALID(time), @"Key time is invalid.");
            NSTimeInterval interval = MAX(strongSelf.displayLink.nextVSyncTimestamp - CACurrentMediaTime(), 0);
            * expect = CMTimeAdd(time, SGFFTimeMakeWithSeconds(interval));
            * current = strongSelf.currentTime;
            return YES;
        }];
    }
    else
    {
        render = [self.renderSource outputFecthRender:self];
    }
    if (render != self.currentRender)
    {
        [self.currentRender unlock];
        self.currentRender = render;
        if ([self.delegate respondsToSelector:@selector(output:hasNewRneder:)]) {
            [self.delegate output:self hasNewRneder:self.currentRender];
        }
    }
}

@end
