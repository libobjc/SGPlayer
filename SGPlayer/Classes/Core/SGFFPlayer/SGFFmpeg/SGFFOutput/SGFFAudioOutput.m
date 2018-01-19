//
//  SGFFAudioOutput.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAudioOutput.h"
#import "SGFFAudioOutputRender.h"

@interface SGFFAudioOutput ()

@property (nonatomic, strong) NSTimer * timer;

@end

@implementation SGFFAudioOutput

- (id <SGFFOutputRender>)renderWithFrame:(id <SGFFFrame>)frame
{
    if (frame.audioFrame)
    {
        NSLog(@"Frame Position : %lld", frame.position);
        return [[SGFFAudioOutputRender alloc] initWithAudioFrame:frame.audioFrame];
    }
    return nil;
}

- (instancetype)init
{
    if (self = [super init])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
            self.timer.fireDate = [NSDate distantPast];
        });
    }
    return self;
}

- (void)timerAction
{
    id <SGFFOutputRender> render = [self.renderSource outputFecthRender:self];
    NSLog(@"%@", render);
}

@end
