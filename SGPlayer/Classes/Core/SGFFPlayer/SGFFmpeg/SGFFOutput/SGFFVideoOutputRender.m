//
//  SGFFVideoOutputRender.m
//  SGPlayer
//
//  Created by Single on 2018/1/21.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFVideoOutputRender.h"

@interface SGFFVideoOutputRender ()

@property (nonatomic, strong) SGFFVideoFrame * videoFrame;

@end

@implementation SGFFVideoOutputRender

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

- (void)updateVideoFrame:(SGFFVideoFrame *)videoFrame
{
    [videoFrame lock];
    [self clear];
    self.videoFrame = videoFrame;
}

- (void)clear
{
    [super clear];
    if (self.videoFrame)
    {
        [self.videoFrame unlock];
        self.videoFrame = nil;
    }
}

@end
