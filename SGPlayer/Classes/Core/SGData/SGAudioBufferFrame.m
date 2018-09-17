//
//  SGAudioBufferFrame.m
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioBufferFrame.h"

@interface SGAudioBufferFrame ()

{
    uint8_t * internalData[SGAudioFrameMaxChannelCount];
    int internalLinesize[SGAudioFrameMaxChannelCount];
    int internalDataMallocSize[SGAudioFrameMaxChannelCount];
}

@end

@implementation SGAudioBufferFrame

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
    for (int i = 0; i < SGAudioFrameMaxChannelCount; i++)
    {
        if (internalData[i])
        {
            free(internalData[i]);
            internalData[i] = NULL;
        }
        internalLinesize[i] = 0;
        internalDataMallocSize[i] = 0;
    }
}

- (void)clear
{
    [super clear];
    for (int i = 0; i < SGAudioFrameMaxChannelCount; i++)
    {
        internalLinesize[i] = 0;
    }
}

- (void)updateData:(void **)data linesize:(int *)linesize
{
    for (int i = 0; i < SGAudioFrameMaxChannelCount; i++)
    {
        internalLinesize[i] = linesize[i];
        if (internalDataMallocSize[i] < linesize[i])
        {
            internalDataMallocSize[i] = linesize[i];
            internalData[i] = realloc(internalData[i], linesize[i]);
        }
        if (linesize[i] > 0)
        {
            memcpy(internalData[i], data[i], linesize[i]);
        }
    }
}

- (void)fillWithAudioFrame:(SGAudioFrame *)audioFrame
{
    self.timebase = audioFrame.timebase;
    self.scale = audioFrame.scale;
    self.startTime = audioFrame.startTime;
    self.timeRange = audioFrame.timeRange;
    self.originalTimeStamp = audioFrame.originalTimeStamp;
    self.originalDecodeTimeStamp = audioFrame.originalDecodeTimeStamp;
    self.originalDuration = audioFrame.originalDuration;
    self.timeStamp = audioFrame.timeStamp;
    self.decodeTimeStamp = audioFrame.decodeTimeStamp;
    self.duration = audioFrame.duration;
    self.size = audioFrame.size;
    
    self.format = audioFrame.format;
    self.numberOfSamples = audioFrame.numberOfSamples;
    self.sampleRate = audioFrame.sampleRate;
    self.numberOfChannels = audioFrame.numberOfSamples;
    self.channelLayout = audioFrame.channelLayout;
    self.bestEffortTimestamp = audioFrame.bestEffortTimestamp;
    self.packetPosition = audioFrame.packetPosition;
    self.packetDuration = audioFrame.packetDuration;
    self.packetSize = audioFrame.packetSize;
}

- (uint8_t **)data
{
    return internalData;
}

- (int *)linesize
{
    return internalLinesize;
}

@end
