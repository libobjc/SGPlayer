//
//  SGFFVideoOutput.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFVideoOutput.h"
#import "SGFFVideoOutputRender.h"
#import "SGPlatform.h"

@interface SGFFVideoOutput ()

@property (nonatomic, strong) SGPLFDisplayLink * displayLink;
@property (nonatomic, strong) SGFFVideoOutputRender * currentRender;

@end

@implementation SGFFVideoOutput

- (id <SGFFOutputRender>)renderWithFrame:(id <SGFFFrame>)frame
{
    SGFFVideoOutputRender * render = [[SGFFObjectPool sharePool] objectWithClass:[SGFFVideoOutputRender class]];
    [render updateVideoFrame:frame.videoFrame];
    return render;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.displayLink = [SGPLFDisplayLink displayLinkWithTarget:self selector:@selector(displayLinkAction)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        self.displayLink.paused = NO;
    }
    return self;
}

- (void)displayLinkAction
{
    self.currentRender = [self.renderSource outputFecthRender:self];
    if (self.currentRender)
    {
        NSLog(@"%s, %d, %d", __func__, self.currentRender.videoFrame.width, self.currentRender.videoFrame.height);
        [self.currentRender unlock];
        self.currentRender = nil;
    }
}

@end
