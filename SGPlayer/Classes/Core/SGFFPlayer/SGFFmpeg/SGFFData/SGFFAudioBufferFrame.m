//
//  SGFFAudioBufferFrame.m
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFFAudioBufferFrame.h"

@interface SGFFAudioBufferFrame ()

{
    uint8_t * internalData[SGFFAudioFrameMaxChannelCount];
    int internalLinesize[SGFFAudioFrameMaxChannelCount];
    int internalDataMallocSize[SGFFAudioFrameMaxChannelCount];
}

@end

@implementation SGFFAudioBufferFrame

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
    for (int i = 0; i < SGFFAudioFrameMaxChannelCount; i++)
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

- (void)updateData:(void **)data linesize:(int *)linesize
{
    for (int i = 0; i < SGFFAudioFrameMaxChannelCount; i++)
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

- (void)clear
{
    [super clear];
    
    for (int i = 0; i < SGFFAudioFrameMaxChannelCount; i++)
    {
        internalLinesize[i] = 0;
    }
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
