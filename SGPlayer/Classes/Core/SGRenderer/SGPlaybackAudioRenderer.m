//
//  SGPlaybackAudioRenderer.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPlaybackAudioRenderer.h"
#import "SGAudioStreamPlayer.h"
#import "SGFrame+Private.h"
#import "SGAudioFrame.h"
#import "SGMapping.h"
#import "swresample.h"
#import "swscale.h"
#import "SGError.h"
#import "SGMacro.h"

@interface SGPlaybackAudioRenderer () <NSLocking, SGAudioStreamPlayerDelegate>

{
    SGRenderableState _state;
    void * _swrContextBufferData[AV_NUM_DATA_POINTERS];
    int _swrContextBufferLinesize[AV_NUM_DATA_POINTERS];
    int _swrContextBufferMallocSize[AV_NUM_DATA_POINTERS];
}

@property (nonatomic, assign) CMTime finalRate;
@property (nonatomic, assign) CMTime frameRate;
@property (nonatomic, assign) BOOL receivedFrame;
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;
@property (nonatomic, strong) SGObjectQueue * frameQueue;
@property (nonatomic, strong) SGAudioStreamPlayer * audioPlayer;
@property (nonatomic, strong) SGAudioFrame * currentFrame;
@property (nonatomic, assign) int32_t currentFrameReadOffset;
@property (nonatomic, assign) CMTime currentFrameScale;
@property (nonatomic, assign) CMTime currentPostPosition;
@property (nonatomic, assign) CMTime currentPostDuration;
@property (nonatomic, assign) SwrContext * swrContext;
@property (nonatomic, strong) NSError * swrContextError;
@property (nonatomic, assign) enum AVSampleFormat inputFormat;
@property (nonatomic, assign) int inputSampleRate;
@property (nonatomic, assign) int inputNumberOfChannels;
@property (nonatomic, assign) int64_t inputChannelLayout;
@property (nonatomic, assign) enum AVSampleFormat outputFormat;
@property (nonatomic, assign) int outputSampleRate;
@property (nonatomic, assign) int outputNumberOfChannels;
@property (nonatomic, assign) int64_t outputChannelLayout;

@end

@implementation SGPlaybackAudioRenderer

@synthesize object = _object;
@synthesize delegate = _delegate;
@synthesize enable = _enable;
@synthesize key = _key;

- (instancetype)init
{
    if (self = [super init])
    {
        _enable = NO;
        _key = NO;
        _rate = CMTimeMake(1, 1);
        _deviceDelay = CMTimeMake(0, 1);
        _finalRate = CMTimeMake(1, 1);
        _frameRate = CMTimeMake(1, 1);
        _currentFrameScale = CMTimeMake(1, 1);
        self.frameQueue = [[SGObjectQueue alloc] init];
        self.currentFrameReadOffset = 0;
        self.currentPostPosition = kCMTimeZero;
        self.currentPostDuration = kCMTimeZero;
        self.audioPlayer = [[SGAudioStreamPlayer alloc] init];
        self.audioPlayer.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

#pragma mark - Interface

- (BOOL)open
{
    [self lock];
    if (self.state != SGRenderableStateNone)
    {
        [self unlock];
        return NO;
    }
    SGBasicBlock callback = [self setState:SGRenderableStatePaused];
    [self unlock];
    callback();
    return YES;
}

- (BOOL)close
{
    [self lock];
    if (self.state == SGRenderableStateClosed)
    {
        [self unlock];
        return NO;
    }
    SGBasicBlock callback = [self setState:SGRenderableStateClosed];
    [self.audioPlayer pause];
    [self.currentFrame unlock];
    self.currentFrame = nil;
    self.currentFrameReadOffset = 0;
    self.currentPostPosition = kCMTimeZero;
    self.currentPostDuration = kCMTimeZero;
    self.receivedFrame = NO;
    [self unlock];
    callback();
    [self.frameQueue destroy];
    [self destorySwrContextBuffer];
    [self destorySwrContext];
    return YES;
}

- (BOOL)pause
{
    [self lock];
    if (self.state != SGRenderableStateRendering)
    {
        [self unlock];
        return NO;
    }
    SGBasicBlock callback = [self setState:SGRenderableStatePaused];
    [self.audioPlayer pause];
    [self unlock];
    callback();
    return YES;
}

- (BOOL)resume
{
    [self lock];
    if (self.state != SGRenderableStatePaused)
    {
        [self unlock];
        return NO;
    }
    SGBasicBlock callback = [self setState:SGRenderableStateRendering];
    [self.audioPlayer play];
    [self unlock];
    callback();
    return YES;
}

- (BOOL)putFrame:(__kindof SGFrame *)frame
{
    [self lock];
    if (self.state != SGRenderableStatePaused &&
        self.state != SGRenderableStateRendering)
    {
        [self unlock];
        return NO;
    }
    [self unlock];
    
    if (![frame isKindOfClass:[SGAudioFrame class]])
    {
        return NO;
    }
    SGAudioFrame * audioFrame = frame;
    
    enum AVSampleFormat inputFormat = audioFrame.format;
    int inputSampleRate = audioFrame.sample_rate;
    int inputNumberOfChannels = audioFrame.channels;
    int64_t inputChannelLayout = audioFrame.channel_layout;
    
    enum AVSampleFormat outputFormat = AV_SAMPLE_FMT_FLTP;
    int outputSampleRate = self.audioPlayer.asbd.mSampleRate;
    int outputNumberOfChannels = self.audioPlayer.asbd.mChannelsPerFrame;
    int64_t outputChannelLayout = av_get_default_channel_layout(outputNumberOfChannels);
    
    if (self.inputFormat != inputFormat ||
        self.inputSampleRate != inputSampleRate ||
        self.inputNumberOfChannels != inputNumberOfChannels ||
        self.inputChannelLayout != inputChannelLayout ||
        self.outputFormat != outputFormat ||
        self.outputSampleRate != outputSampleRate ||
        self.outputNumberOfChannels != outputNumberOfChannels ||
        self.outputChannelLayout != outputChannelLayout)
    {
        self.inputFormat = inputFormat;
        self.inputSampleRate = inputSampleRate;
        self.inputNumberOfChannels = inputNumberOfChannels;
        self.inputChannelLayout = inputChannelLayout;
        
        self.outputFormat = outputFormat;
        self.outputSampleRate = outputSampleRate;
        self.outputNumberOfChannels = outputNumberOfChannels;
        self.outputChannelLayout = outputChannelLayout;
        
        [self destorySwrContext];
        [self setupSwrContext];
    }
    
    if (!self.swrContext)
    {
        return NO;
    }

    int preferNumberOfSamples = swr_get_out_samples(self.swrContext, audioFrame.nb_samples);
    if (preferNumberOfSamples <= 0 && audioFrame.nb_samples > 0)
    {
        float numberOfChannelsRatio = self.outputNumberOfChannels / self.inputNumberOfChannels;
        float sampleRateRatio = self.outputSampleRate / self.inputSampleRate;
        float ratio = sampleRateRatio * numberOfChannelsRatio;
        preferNumberOfSamples = audioFrame.nb_samples * ratio;
    }
    int bufferSize = av_samples_get_buffer_size(NULL,
                                                self.outputNumberOfChannels,
                                                preferNumberOfSamples,
                                                self.outputFormat,
                                                0);
    [self setupSwrContextBufferIfNeeded:bufferSize];
    int numberOfSamples = swr_convert(self.swrContext,
                                      (uint8_t **)_swrContextBufferData,
                                      preferNumberOfSamples,
                                      (const uint8_t **)audioFrame->data,
                                      audioFrame.nb_samples);
    [self updateSwrContextBufferLinsize:numberOfSamples * sizeof(float)];

    SGAudioFrame * result = [[SGObjectPool sharePool] objectWithClass:[SGAudioFrame class]];
    result.core->format = self.outputFormat;
    result.core->channels = self.outputNumberOfChannels;
    result.core->channel_layout = self.outputChannelLayout;
    result.core->nb_samples = numberOfSamples;
    av_frame_copy_props(result.core, audioFrame.core);
    for (int i = 0; i < AV_NUM_DATA_POINTERS; i++)
    {
        int size = _swrContextBufferLinesize[i];
        uint8_t * data = av_mallocz(size);
        memcpy(data, _swrContextBufferData[i], size);
        AVBufferRef * buffer = av_buffer_create(data, size, av_buffer_default_free, NULL, 0);
        result.core->buf[i] = buffer;
        result.core->data[i] = buffer->data;
        result.core->linesize[i] = buffer->size;
    }
    [result configurateWithStream:audioFrame.stream];
    
    if (!self.receivedFrame)
    {
        [self.timeSync updateKeyTime:result.timeStamp duration:kCMTimeZero rate:CMTimeMake(1, 1)];
    }
    self.receivedFrame = YES;
    [self.frameQueue putObjectSync:result];
    [self.delegate renderable:self didChangeDuration:kCMTimeZero size:0 count:0];
    [result unlock];
    return YES;
}

- (BOOL)flush
{
    [self lock];
    if (self.state != SGRenderableStatePaused &&
        self.state != SGRenderableStateRendering)
    {
        [self unlock];
        return NO;
    }
    [self.currentFrame unlock];
    self.currentFrame = nil;
    self.currentFrameReadOffset = 0;
    self.currentPostPosition = kCMTimeZero;
    self.currentPostDuration = kCMTimeZero;
    self.receivedFrame = NO;
    [self unlock];
    [self.frameQueue flush];
    [self.delegate renderable:self didChangeDuration:kCMTimeZero size:0 count:0];
    return YES;
}

#pragma mark - Setter & Getter

- (SGBasicBlock)setState:(SGRenderableState)state
{
    if (_state != state)
    {
        _state = state;
        return ^{
            [self.delegate renderable:self didChangeState:state];
        };
    }
    return ^{};
}

- (SGRenderableState)state
{
    return _state;
}

- (NSError *)error
{
    if (self.audioPlayer.error)
    {
        return self.audioPlayer.error;
    }
    return self.swrContextError;
}

- (BOOL)enough
{
    NSUInteger count = 0;
    [self duratioin:NULL size:NULL count:&count];
    return count >= 5;
}

- (BOOL)duratioin:(CMTime *)duration size:(int64_t *)size count:(NSUInteger *)count
{
    return [self.frameQueue duratioin:duration size:size count:count];
}

- (void)setVolume:(float)volume
{
    [self.audioPlayer setVolume:volume error:nil];
}

- (float)volume
{
    return self.audioPlayer.volume;
}

- (void)setRate:(CMTime)rate
{
    if (CMTimeCompare(_rate, rate) != 0)
    {
        _rate = rate;
        [self updatePlayerRate];
    }
}

- (void)setFrameRate:(CMTime)frameRate
{
    if (CMTimeCompare(_frameRate, frameRate) != 0)
    {
        _frameRate = frameRate;
        [self updatePlayerRate];
    }
}

- (void)updatePlayerRate
{
    CMTime rate = SGCMTimeMultiply(self.rate, self.frameRate);
    NSError * error = nil;
    [self.audioPlayer setRate:CMTimeGetSeconds(rate) error:&error];
}

#pragma mark - swr

- (void)setupSwrContext
{
    if (self.swrContextError || self.swrContext)
    {
        return;
    }
    self.swrContext = swr_alloc_set_opts(NULL,
                                         self.outputChannelLayout,
                                         self.outputFormat,
                                         self.outputSampleRate,
                                         self.inputChannelLayout,
                                         self.inputFormat,
                                         self.inputSampleRate,
                                         0, NULL);
    int result = swr_init(self.swrContext);
    self.swrContextError = SGEGetError(result, SGOperationCodeAuidoSwrInit);
    if (self.swrContextError)
    {
        [self destorySwrContext];
    }
}

- (void)destorySwrContext
{
    if (self.swrContext)
    {
        swr_free(&_swrContext);
        self.swrContext = nil;
    }
}

- (void)setupSwrContextBufferIfNeeded:(int)bufferSize
{
    for (int i = 0; i < AV_NUM_DATA_POINTERS; i++)
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
    for (int i = 0; i < AV_NUM_DATA_POINTERS; i++)
    {
        _swrContextBufferLinesize[i] = (i < self.outputNumberOfChannels) ? linesize : 0;
    }
}

- (void)destorySwrContextBuffer
{
    for (int i = 0; i < AV_NUM_DATA_POINTERS; i++)
    {
        if (_swrContextBufferData[i])
        {
            free(_swrContextBufferData[i]);
            _swrContextBufferData[i] = NULL;
        }
        _swrContextBufferLinesize[i] = 0;
        _swrContextBufferMallocSize[i] = 0;
    }
}

#pragma mark - SGAudioStreamPlayerDelegate

- (void)audioPlayer:(SGAudioStreamPlayer *)audioPlayer inputSample:(const AudioTimeStamp *)timestamp ioData:(AudioBufferList *)ioData numberOfSamples:(UInt32)numberOfSamples
{
    BOOL hasNewFrame = NO;
    [self lock];
    NSUInteger ioDataWriteOffset = 0;
    while (numberOfSamples > 0)
    {
        if (!self.currentFrame)
        {
            self.currentFrame = [self.frameQueue getObjectAsync];
            hasNewFrame = YES;
        }
        if (!self.currentFrame)
        {
            break;
        }
        self.currentFrameScale = CMTimeMake(1, 1);
        
        int32_t residueLinesize = self.currentFrame->linesize[0] - self.currentFrameReadOffset;
        int32_t bytesToCopy = MIN(numberOfSamples * (int32_t)sizeof(float), residueLinesize);
        int32_t framesToCopy = bytesToCopy / sizeof(float);
        
        for (int i = 0; i < ioData->mNumberBuffers && i < self.currentFrame.nb_samples; i++)
        {
            if (self.currentFrame->linesize[i] - self.currentFrameReadOffset >= bytesToCopy)
            {
                Byte * bytes = (Byte *)self.currentFrame->data[i] + self.currentFrameReadOffset;
                memcpy(ioData->mBuffers[i].mData + ioDataWriteOffset, bytes, bytesToCopy);
            }
        }
        
        if (ioDataWriteOffset == 0)
        {
            self.currentPostDuration = kCMTimeZero;
            CMTime duration = CMTimeMultiplyByRatio(self.currentFrame.duration, self.currentFrameReadOffset, self.currentFrame->linesize[0]);
            self.currentPostPosition = CMTimeAdd(self.currentFrame.timeStamp, duration);
        }
        CMTime duration = CMTimeMultiplyByRatio(self.currentFrame.duration, bytesToCopy, self.currentFrame->linesize[0]);
        duration = SGCMTimeMultiply(duration, CMTimeMake(1, 1));
        self.currentPostDuration = CMTimeAdd(self.currentPostDuration, duration);
        
        numberOfSamples -= framesToCopy;
        ioDataWriteOffset += bytesToCopy;
        
        if (bytesToCopy < residueLinesize)
        {
            self.currentFrameReadOffset += bytesToCopy;
        }
        else
        {
            [self.currentFrame unlock];
            self.currentFrame = nil;
            self.currentFrameReadOffset = 0;
        }
    }
    [self unlock];
    if (hasNewFrame)
    {
        [self.delegate renderable:self didChangeDuration:kCMTimeZero size:0 count:0];
    }
}

- (void)audioStreamPlayer:(SGAudioStreamPlayer *)audioDataPlayer postSample:(const AudioTimeStamp *)timestamp
{
    [self lock];
    CMTime frameRate = SGCMTimeDivide(CMTimeMake(1, 1), self.currentFrameScale);
    CMTime currentPostPosition = self.currentPostPosition;
    CMTime currentPostDuration = self.currentPostDuration;
    CMTime rate = self.rate;
    CMTime deviceDelay = self.deviceDelay;
    dispatch_block_t block = ^{
        self.frameRate = frameRate;
        [self.timeSync updateKeyTime:currentPostPosition duration:currentPostDuration rate:rate];
    };
    if (CMTimeCompare(deviceDelay, kCMTimeZero) > 0)
    {
        if (!self.delegateQueue)
        {
            self.delegateQueue = dispatch_queue_create("SGPlaybackAudioRenderer-DelegateQueue", DISPATCH_QUEUE_SERIAL);
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CMTimeGetSeconds(deviceDelay) * NSEC_PER_SEC)), self.delegateQueue, block);
    }
    else
    {
        block();
    }
    [self unlock];
}

#pragma mark - NSLocking

- (void)lock
{
    if (!self.coreLock)
    {
        self.coreLock = [[NSLock alloc] init];
    }
    [self.coreLock lock];
}

- (void)unlock
{
    [self.coreLock unlock];
}

@end
