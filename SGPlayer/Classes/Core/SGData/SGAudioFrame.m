//
//  SGAudioFrame.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGAudioFrame.h"
#import "SGFrame+Private.h"
#import "SGMapping.h"

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
    
    _format = AV_SAMPLE_FMT_NONE;
    _nb_samples = 0;
    _sample_rate = 0;
    _channels = 0;
    _channel_layout = 0;
    for (int i = 0; i < SGFramePlaneCount; i++)
    {
        self->data[i] = nil;
        self->linesize[i] = 0;
    }
}

- (void)configurateWithStream:(SGStream *)stream
{
    [super configurateWithStream:stream];
    
    _format = self.core->format;
    _nb_samples = self.core->nb_samples;
    _sample_rate = self.core->sample_rate;
    _channels = self.core->channels;
    _channel_layout = self.core->channel_layout;
    for (int i = 0; i < SGFramePlaneCount; i++)
    {
        self->data[i] = self.core->data[i];
        self->linesize[i] = self.core->linesize[i];
    }
}

@end
