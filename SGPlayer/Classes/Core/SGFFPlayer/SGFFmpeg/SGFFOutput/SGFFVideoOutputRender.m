//
//  SGFFVideoOutputRender.m
//  SGPlayer
//
//  Created by Single on 2018/1/21.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFVideoOutputRender.h"

@interface SGFFVideoOutputRender ()

@property (nonatomic, strong) SGFFVideoFrame * coreVideoFrame;

SGFFObjectPoolItemInterface

@end

@implementation SGFFVideoOutputRender

SGFFObjectPoolItemLockingImplementation

- (SGFFOutputRenderType)type
{
    return SGFFOutputRenderTypeVideo;
}

- (instancetype)init
{
    if (self = [super init])
    {
        NSLog(@"%s", __func__);
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    [self clear];
}

- (void)updateCoreVideoFrame:(SGFFVideoFrame *)coreVideoFrame
{
    if (coreVideoFrame)
    {
        [coreVideoFrame lock];
    }
    if (self.coreVideoFrame)
    {
        [self.coreVideoFrame unlock];
    }
    self.coreVideoFrame = coreVideoFrame;
    self.timebase = self.coreVideoFrame.timebase;
    self.position = self.coreVideoFrame.position;
    self.duration = self.coreVideoFrame.duration;
    self.size = self.coreVideoFrame.size;
}

- (void)clear
{
    if (self.coreVideoFrame)
    {
        [self.coreVideoFrame unlock];
        self.coreVideoFrame = nil;
    }
    self.timebase = SGFFTimebaseIdentity();
    self.position = 0;
    self.duration = 0;
    self.size = 0;
}

@end
