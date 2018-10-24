//
//  SGAudioFrame.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGAudioFrame.h"
#import "SGFrame+Private.h"
#import "SGFFDefinesMapping.h"

@implementation SGAudioFrame

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
}

- (void)clear
{
    [super clear];
    
    _format = SG_AV_SAMPLE_FMT_NONE;
    _numberOfSamples = 0;
    _sampleRate = 0;
    _numberOfChannels = 0;
    _channelLayout = 0;
    for (int i = 0; i < SGFramePlaneCount; i++)
    {
        self->data[i] = nil;
        self->linesize[i] = 0;
    }
}

- (void)configurateWithStream:(SGStream *)stream
{
    [super configurateWithStream:stream];
    
    _format = SGDMSampleFormatFF2SG(self.core->format);
    _numberOfSamples = self.core->nb_samples;
    _sampleRate = self.core->sample_rate;
    _numberOfChannels = self.core->channels;
    _channelLayout = self.core->channel_layout;
    for (int i = 0; i < SGFramePlaneCount; i++)
    {
        self->data[i] = self.core->data[i];
        self->linesize[i] = self.core->linesize[i];
    }
}

@end
