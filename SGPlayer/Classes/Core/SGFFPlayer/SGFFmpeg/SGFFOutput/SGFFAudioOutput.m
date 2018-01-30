//
//  SGFFAudioOutput.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAudioOutput.h"
#import "SGFFAudioOutputRender.h"
#import "SGFFAudioPlayer.h"
#import "SGFFError.h"
#import "swscale.h"
#import "swresample.h"

@interface SGFFAudioOutput () <SGFFAudioPlayerDelegate>

{
    SwrContext * _swrContext;
    void * _swrContextBufferData[SGFFAudioOutputRenderMaxChannelCount];
    int _swrContextBufferLinesize[SGFFAudioOutputRenderMaxChannelCount];
    int _swrContextBufferMallocSize[SGFFAudioOutputRenderMaxChannelCount];
}

@property (nonatomic, strong) SGFFAudioPlayer * audioPlayer;
@property (nonatomic, strong) SGFFAudioOutputRender * currentRender;
@property (nonatomic, assign) long long currentRenderReadOffset;

@property (nonatomic, assign) enum AVSampleFormat inputFormat;
@property (nonatomic, assign) int inputSampleRate;
@property (nonatomic, assign) int inputNumberOfChannels;
@property (nonatomic, assign) int outputSampleRate;
@property (nonatomic, assign) int outputNumberOfChannels;

@property (nonatomic, assign) NSError * swrContextError;

@end

@implementation SGFFAudioOutput

- (id <SGFFOutputRender>)renderWithFrame:(id <SGFFFrame>)frame
{
    SGFFAudioFrame * audioFrame = frame.audioFrame;
    if (!audioFrame)
    {
        return nil;
    }
    
    self.inputFormat = audioFrame.format;
    self.inputSampleRate = audioFrame.sampleRate;
    self.inputNumberOfChannels = audioFrame.numberOfChannels;
    self.outputSampleRate = self.audioPlayer.sampleRate;
    self.outputNumberOfChannels = self.audioPlayer.numberOfChannels;
    
    [self setupSwrContextIfNeed];
    if (!_swrContext)
    {
        return nil;
    }
    const int numberOfChannelsRatio = MAX(1, self.audioPlayer.numberOfChannels / audioFrame.numberOfChannels);
    const int sampleRateRatio = MAX(1, self.audioPlayer.sampleRate / audioFrame.sampleRate);
    const int ratio = sampleRateRatio * numberOfChannelsRatio;
    const int bufferSize = av_samples_get_buffer_size(NULL, 1,
                                                      audioFrame.numberOfSamples * ratio,
                                                      AV_SAMPLE_FMT_FLTP, 1);
    [self setupSwrContextBufferIfNeed:bufferSize];
    int numberOfSamples = swr_convert(_swrContext,
                                      (uint8_t **)_swrContextBufferData,
                                      audioFrame.numberOfSamples * ratio,
                                      (const uint8_t **)audioFrame.data,
                                      audioFrame.numberOfSamples);
    [self updateSwrContextBufferLinsize:numberOfSamples * sizeof(float)];
    
    SGFFAudioOutputRender * render = [[SGFFObjectPool sharePool] objectWithClass:[SGFFAudioOutputRender class]];
    render.format = AV_SAMPLE_FMT_FLTP;
    render.numberOfSamples = numberOfSamples;
    render.numberOfChannels = self.outputNumberOfChannels;
    render.position = frame.position;
    render.duration = frame.duration;
    render.size = frame.size;
    [render updateData:_swrContextBufferData linesize:_swrContextBufferLinesize];
    
    return render;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.audioPlayer = [[SGFFAudioPlayer alloc] initWithDelegate:self];
    }
    return self;
}

- (void)dealloc
{
    [self.audioPlayer pause];
    [self clearSwrContext];
    [self.currentRender unlock];
    self.currentRender = nil;
    self.currentRenderReadOffset = 0;
}

- (void)play
{
    [self.audioPlayer play];
}

- (void)pause
{
    [self.audioPlayer pause];
}

- (void)setupSwrContextIfNeed
{
    if (self.swrContextError || _swrContext)
    {
        return;
    }
    _swrContext = swr_alloc_set_opts(NULL,
                                     av_get_default_channel_layout(self.outputNumberOfChannels),
                                     AV_SAMPLE_FMT_FLTP,
                                     self.outputSampleRate,
                                     av_get_default_channel_layout(self.inputNumberOfChannels),
                                     self.inputFormat,
                                     self.inputSampleRate,
                                     0, NULL);
    int result = swr_init(_swrContext);
    self.swrContextError = SGFFGetErrorCode(result, SGFFErrorCodeAuidoSwrInit);
    if (self.swrContextError)
    {
        if (_swrContext)
        {
            swr_free(&_swrContext);
            _swrContext = nil;
        }
    }
}

- (void)setupSwrContextBufferIfNeed:(int)bufferSize
{
    for (int i = 0; i < SGFFAudioOutputRenderMaxChannelCount; i++)
    {
        if (_swrContextBufferMallocSize[i] < bufferSize)
        {
            _swrContextBufferMallocSize[i] = bufferSize;
            _swrContextBufferData[i] = realloc(_swrContextBufferData[i], bufferSize);
        }
    }
}

- (void)updateSwrContextBufferLinsize:(int)linesize
{
    for (int i = 0; i < SGFFAudioOutputRenderMaxChannelCount; i++)
    {
        _swrContextBufferLinesize[i] = (i < self.outputNumberOfChannels) ? linesize : 0;
    }
}

- (void)clearSwrContext
{
    for (int i = 0; i < SGFFAudioOutputRenderMaxChannelCount; i++)
    {
        if (_swrContextBufferData[i])
        {
            free(_swrContextBufferData[i]);
            _swrContextBufferData[i] = NULL;
        }
        _swrContextBufferLinesize[i] = 0;
        _swrContextBufferMallocSize[i] = 0;
    }
    if (_swrContext)
    {
        swr_free(&_swrContext);
        _swrContext = nil;
    }
}


#pragma mark - SGAudioManagerDelegate

- (void)audioPlayerShouldInputData:(SGFFAudioPlayer *)audioPlayer ioData:(AudioBufferList *)ioData numberOfSamples:(UInt32)numberOfSamples numberOfChannels:(UInt32)numberOfChannels
{
    NSUInteger ioDataWriteOffset = 0;
    while (numberOfSamples > 0)
    {
        if (!self.currentRender)
        {
            self.currentRender = [self.renderSource outputFecthRender:self];
        }
        if (!self.currentRender)
        {
            return;
        }
        
        long long residueLinesize = self.currentRender.linesize[0] - self.currentRenderReadOffset;
        long long bytesToCopy = MIN(numberOfSamples * sizeof(float), residueLinesize);
        long long framesToCopy = bytesToCopy / sizeof(float);
        
        for (int i = 0; i < ioData->mNumberBuffers && i < numberOfChannels; i++)
        {
            if (self.currentRender.linesize[i] - self.currentRenderReadOffset >= bytesToCopy)
            {
                Byte * bytes = (Byte *)self.currentRender.data[i] + self.currentRenderReadOffset;
                memcpy(ioData->mBuffers[i].mData + ioDataWriteOffset, bytes, bytesToCopy);
            }
        }
        
        numberOfSamples -= framesToCopy;
        ioDataWriteOffset += bytesToCopy;
        
        if (bytesToCopy < residueLinesize) {
            self.currentRenderReadOffset += bytesToCopy;
        } else {
            [self.currentRender unlock];
            self.currentRender = nil;
            self.currentRenderReadOffset = 0;
        }
    }
}

@end
