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

- (void)fillWithFrame:(SGFrame *)frame
{
    self.timebase = frame.timebase;
    self.offset = frame.offset;
    self.scale = frame.scale;
    self.originalTimeStamp = frame.originalTimeStamp;
    self.originalDuration = frame.originalDuration;
    self.timeStamp = frame.timeStamp;
    self.duration = frame.duration;
    self.decodeTimeStamp = frame.decodeTimeStamp;
    self.size = frame.size;
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
