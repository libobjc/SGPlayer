//
//  SGAudioFrame.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGAudioFrame.h"
#import "SGFrame+Internal.h"
#import "SGMapping.h"

@implementation SGAudioFrame

- (SGMediaType)type
{
    return SGMediaTypeAudio;
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
}

- (void)clear
{
    [super clear];
    
    _format = AV_SAMPLE_FMT_NONE;
    _is_planar = 0;
    _nb_samples = 0;
    _sample_rate = 0;
    _channels = 0;
    _channel_layout = 0;
    for (int i = 0; i < SGFramePlaneCount; i++) {
        self->_data[i] = nil;
        self->_linesize[i] = 0;
    }
}

- (void)setTimebase:(AVRational)timebase
{
    [super setTimebase:timebase];
    
    _format = self.core->format;
    _is_planar = av_sample_fmt_is_planar(self.core->format);
    _nb_samples = self.core->nb_samples;
    _sample_rate = self.core->sample_rate;
    _channels = self.core->channels;
    _channel_layout = self.core->channel_layout;
    for (int i = 0; i < SGFramePlaneCount; i++) {
        self->_data[i] = self.core->data[i];
        self->_linesize[i] = self.core->linesize[i];
    }
}

@end
