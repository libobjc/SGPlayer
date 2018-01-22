//
//  SGFFAudioOutputRender.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAudioOutputRender.h"

@interface SGFFAudioOutputRender ()

@property (nonatomic, assign) float * samples;
@property (nonatomic, assign) long long length;
@property (nonatomic, assign) long long bufferLength;

@end

@implementation SGFFAudioOutputRender

- (SGFFOutputRenderType)type
{
    return SGFFOutputRenderTypeAudio;
}

- (instancetype)init
{
    if (self = [super init])
    {
        
    }
    return self;
}

- (void)dealloc
{
    if (self.samples)
    {
        free(self.samples);
        self.samples = nil;
    }
}

- (void)updateLength:(long long)length
{
    self.length = length;
    if (self.bufferLength < self.length)
    {
        if (self.bufferLength > 0 && self.samples != nil)
        {
            free(self.samples);
        }
        self.bufferLength = length;
        self.samples = malloc((unsigned long)self.bufferLength);
    }
    self.offset = 0;
}

- (void)clear
{
    [super clear];
    memset(self.samples, 0, self.bufferLength);
    self.length = 0;
    self.offset = 0;
}

@end
