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
#import <Accelerate/Accelerate.h>
#import "swscale.h"
#import "swresample.h"

@interface SGFFAudioOutput () <SGFFAudioPlayerDelegate>

{
    SwrContext * _swrContext;
    void * _swrBuffer;
    int _swrBufferSize;
}

@property (nonatomic, strong) SGFFAudioPlayer * audioPlayer;
@property (nonatomic, strong) SGFFAudioOutputRender * currentRender;

@end

@implementation SGFFAudioOutput

- (id <SGFFOutputRender>)renderWithFrame:(id <SGFFFrame>)frame
{
    SGFFAudioFrame * audioFrame = frame.audioFrame;
    if (audioFrame)
    {
        if (!_swrContext)
        {
            _swrContext = swr_alloc_set_opts(NULL,
                                              av_get_default_channel_layout(self.audioPlayer.numberOfChannels),
                                              AV_SAMPLE_FMT_S16,
                                              self.audioPlayer.sampleRate,
                                              av_get_default_channel_layout((int)audioFrame.numberOfChannels),
                                              audioFrame.format,
                                              (int)audioFrame.sampleRate,
                                              0,
                                              NULL);
            int result = swr_init(_swrContext);
            NSError * error = SGFFGetError(result);
            if (error || !_swrContext)
            {
                if (_swrContext)
                {
                    swr_free(&_swrContext);
                    _swrContext = nil;
                }
            }
        }
        
        long long numberOfFrames;
        void * audioDataBuffer;
        if (_swrContext)
        {
            const int channel = MAX(1, self.audioPlayer.numberOfChannels / audioFrame.numberOfChannels);
            const int sample = MAX(1, self.audioPlayer.sampleRate / audioFrame.sampleRate);
            const int ratio = sample * channel * 2;
            const int bufferSize = av_samples_get_buffer_size(NULL,
                                                              self.audioPlayer.numberOfChannels,
                                                              (int)audioFrame.numberOfSamples * ratio,
                                                              AV_SAMPLE_FMT_S16,
                                                              1);
            if (!_swrBuffer || _swrBufferSize < bufferSize)
            {
                _swrBufferSize = bufferSize;
                _swrBuffer = realloc(_swrBuffer, _swrBufferSize);
            }
            Byte * outputBuffer[2] = {_swrBuffer, 0};
            numberOfFrames = swr_convert(_swrContext,
                                         outputBuffer,
                                         (int)audioFrame.numberOfSamples * ratio,
                                         (const uint8_t **)audioFrame.data,
                                         (int)audioFrame.numberOfSamples);
            NSError * error = SGFFGetError((int)numberOfFrames);
            if (error)
            {
                NSLog(@"audio codec error : %@", error);
                return nil;
            }
            audioDataBuffer = _swrBuffer;
        }
        else
        {
            if (audioFrame.format != AV_SAMPLE_FMT_S16)
            {
                NSLog(@"audio format error");
                return nil;
            }
            audioDataBuffer = audioFrame.data;
            numberOfFrames = audioFrame.numberOfSamples;
        }
        
        SGFFAudioOutputRender * render = [[SGFFObjectPool sharePool] objectWithClass:[SGFFAudioOutputRender class]];
        const NSUInteger numberOfElements = numberOfFrames * self.audioPlayer.numberOfChannels;
        [render updateLength:numberOfElements * sizeof(float)];
        
        float scale = 1.0 / (float)INT16_MAX ;
        vDSP_vflt16((SInt16 *)audioDataBuffer, 1, render.samples, 1, numberOfElements);
        vDSP_vsmul(render.samples, 1, &scale, render.samples, 1, numberOfElements);
        
        NSLog(@"Frame Position : %f", SGFFTimebaseConvertToSeconds(frame.position, frame.timebase));
        return render;
    }
    return nil;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.audioPlayer = [[SGFFAudioPlayer alloc] initWithDelegate:self];
    }
    return self;
}

- (void)play
{
    [self.audioPlayer play];
}

- (void)pause
{
    [self.audioPlayer pause];
}

- (void)dealloc
{
    if (_swrBuffer)
    {
        free(_swrBuffer);
        _swrBuffer = nil;
        _swrBufferSize = 0;
    }
    if (_swrContext)
    {
        swr_free(&_swrContext);
        _swrContext = nil;
    }
    [self.currentRender unlock];
    self.currentRender = nil;
}


#pragma mark - SGAudioManagerDelegate

- (void)audioManager:(SGFFAudioPlayer *)audioManager outputData:(float *)outputData numberOfFrames:(UInt32)numberOfFrames numberOfChannels:(UInt32)numberOfChannels
{
    @autoreleasepool
    {
        while (numberOfFrames > 0)
        {
            if (!self.currentRender)
            {
                self.currentRender = [self.renderSource outputFecthRender:self];
            }
            if (!self.currentRender)
            {
                memset(outputData, 0, numberOfFrames * numberOfChannels * sizeof(float));
                return;
            }
            
            const Byte * bytes = (Byte *)self.currentRender.samples + self.currentRender.offset;
            const NSUInteger bytesLeft = self.currentRender.length - self.currentRender.offset;
            const NSUInteger frameSizeOf = numberOfChannels * sizeof(float);
            const NSUInteger bytesToCopy = MIN(numberOfFrames * frameSizeOf, bytesLeft);
            const NSUInteger framesToCopy = bytesToCopy / frameSizeOf;
            
            memcpy(outputData, bytes, bytesToCopy);
            numberOfFrames -= framesToCopy;
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
