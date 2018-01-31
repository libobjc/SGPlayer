//
//  SGFFAudioOutputRender.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAudioOutputRender.h"

@interface SGFFAudioOutputRender ()

{
    void * internalData[SGFFAudioOutputRenderMaxChannelCount];
    int internalLinesize[SGFFAudioOutputRenderMaxChannelCount];
    int internalDataMallocSize[SGFFAudioOutputRenderMaxChannelCount];
}

SGFFObjectPoolItemInterface

@end

@implementation SGFFAudioOutputRender

SGFFObjectPoolItemLockingImplementation

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
    for (int i = 0; i < SGFFAudioOutputRenderMaxChannelCount; i++)
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
    for (int i = 0; i < SGFFAudioOutputRenderMaxChannelCount; i++)
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
    for (int i = 0; i < SGFFAudioOutputRenderMaxChannelCount; i++)
    {
        internalLinesize[i] = 0;
    }
    self.numberOfSamples = 0;
    self.numberOfChannels = 0;
    self.position = 0;
    self.duration = 0;
    self.size = 0;
}

- (void **)data
{
    return internalData;
}

- (int *)linesize
{
    return internalLinesize;
}

@end
