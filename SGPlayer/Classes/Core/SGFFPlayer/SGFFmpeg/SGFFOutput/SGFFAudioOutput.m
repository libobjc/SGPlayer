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

@property (nonatomic, strong) SGFFAudioPlayer * audioPlayer;
@property (nonatomic, strong) SGFFAudioOutputRender * currentRender;

@property (nonatomic, assign) enum AVSampleFormat inputFormat;
@property (nonatomic, assign) int inputSampleRate;
@property (nonatomic, assign) int inputNumberOfChannels;
@property (nonatomic, assign) int outputSampleRate;
@property (nonatomic, assign) int outputNumberOfChannels;

@property (nonatomic, assign) SwrContext * swrContext;
@property (nonatomic, assign) float * swrContextBuffer;
@property (nonatomic, assign) int swrContextBufferSize;
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
    if (!self.swrContext)
    {
        return nil;
    }
    const int numberOfChannelsRatio = MAX(1, self.audioPlayer.numberOfChannels / audioFrame.numberOfChannels);
    const int sampleRateRatio = MAX(1, self.audioPlayer.sampleRate / audioFrame.sampleRate);
    const int ratio = sampleRateRatio * numberOfChannelsRatio * 2;
    const int bufferSize = av_samples_get_buffer_size(NULL,
                                                      self.outputNumberOfChannels,
                                                      audioFrame.numberOfSamples * ratio,
                                                      AV_SAMPLE_FMT_FLT,
                                                      1);
    [self setupSwrContextBufferIfNeed:bufferSize];
    Byte * outputBuffer[2] = {(void *)self.swrContextBuffer, 0};
    int numberOfSamples = swr_convert(self.swrContext,
                                      outputBuffer,
                                      audioFrame.numberOfSamples * ratio,
                                      (const uint8_t **)audioFrame.data,
                                      audioFrame.numberOfSamples);
    
    SGFFAudioOutputRender * render = [[SGFFObjectPool sharePool] objectWithClass:[SGFFAudioOutputRender class]];
    long long length = numberOfSamples * self.outputNumberOfChannels * sizeof(float);
    [render updateSamples:self.swrContextBuffer length:length];
    render.numberOfSamples = numberOfSamples;
    render.numberOfChannels = self.outputNumberOfChannels;
    
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
    if (self.swrContextError || self.swrContext)
    {
        return;
    }
    self.swrContext = swr_alloc_set_opts(NULL,
                                         av_get_default_channel_layout(self.outputNumberOfChannels),
                                         AV_SAMPLE_FMT_FLT,
                                         self.outputSampleRate,
                                         av_get_default_channel_layout(self.inputNumberOfChannels),
                                         self.inputFormat,
                                         self.inputSampleRate,
                                         0, NULL);
    int result = swr_init(_swrContext);
    self.swrContextError = SGFFGetErrorCode(result, SGFFErrorCodeAuidoSwrInit);
    if (self.swrContextError)
    {
        if (self.swrContext)
        {
            swr_free(&_swrContext);
            self.swrContext = nil;
        }
    }
}

- (void)setupSwrContextBufferIfNeed:(int)size
{
    if (!self.swrContextBuffer || self.swrContextBufferSize < size)
    {
        self.swrContextBufferSize = size;
        self.swrContextBuffer = realloc(self.swrContextBuffer, self.swrContextBufferSize);
    }
}

- (void)clearSwrContext
{
    if (self.swrContextBuffer)
    {
        free(self.swrContextBuffer);
        self.swrContextBuffer = nil;
        self.swrContextBufferSize = 0;
    }
    if (self.swrContext)
    {
        swr_free(&_swrContext);
        self.swrContext = nil;
    }
}


#pragma mark - SGAudioManagerDelegate

- (void)audioPlayer:(SGFFAudioPlayer *)audioPlayer
         outputData:(float *)outputData
    numberOfSamples:(UInt32)numberOfSamples
   numberOfChannels:(UInt32)numberOfChannels
{
    @autoreleasepool
    {
        while (numberOfSamples > 0)
        {
            if (!self.currentRender)
            {
                self.currentRender = [self.renderSource outputFecthRender:self];
            }
            if (!self.currentRender)
            {
                memset(outputData, 0, numberOfSamples * numberOfChannels * sizeof(float));
                return;
            }
            
            const Byte * bytes = (Byte *)self.currentRender.samples + self.currentRender.offset;
            const NSUInteger bytesLeft = self.currentRender.length - self.currentRender.offset;
            const NSUInteger frameSize = numberOfChannels * sizeof(float);
            const NSUInteger bytesToCopy = MIN(numberOfSamples * frameSize, bytesLeft);
            const NSUInteger framesToCopy = bytesToCopy / frameSize;
            
            memcpy(outputData, bytes, bytesToCopy);
            numberOfSamples -= framesToCopy;
            outputData += framesToCopy * numberOfChannels;
            
            if (bytesToCopy < bytesLeft) {
                self.currentRender.offset += bytesToCopy;
            } else {
                [self.currentRender unlock];
                self.currentRender = nil;
            }
        }
    }
}

@end
