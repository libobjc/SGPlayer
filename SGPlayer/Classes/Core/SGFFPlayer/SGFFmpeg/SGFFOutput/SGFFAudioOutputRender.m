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

- (enum AVSampleFormat)format
{
    return AV_SAMPLE_FMT_FLT;
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
    if (self.samples)
    {
        free(self.samples);
        self.samples = nil;
    }
}

- (void)updateSamples:(float *)samples length:(long long)length
{
    self.length = length;
    if (self.bufferLength < self.length)
    {
        if (self.samples != nil)
        {
            free(self.samples);
        }
        self.bufferLength = self.length;
        self.samples = malloc(self.bufferLength);
    }
    memcpy(self.samples, samples, self.length);
}

- (void)clear
{
    [super clear];
    memset(self.samples, 0, self.bufferLength);
    self.length = 0;
    self.numberOfSamples = 0;
    self.numberOfChannels = 0;
    self.offset = 0;
    self.position = 0;
    self.duration = 0;
    self.size = 0;
}

@end
