//
//  SGFFAudioPlaybackOutput.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAudioPlaybackOutput.h"
#import "SGAudioStreamPlayer.h"
#import "SGFFAudioBufferFrame.h"
#import "SGTime.h"
#import "SGFFError.h"
#import "swscale.h"
#import "swresample.h"

@interface SGFFAudioPlaybackOutput () <SGAudioStreamPlayerDelegate, NSLocking>

{
    void * _swrContextBufferData[SGFFAudioFrameMaxChannelCount];
    int _swrContextBufferLinesize[SGFFAudioFrameMaxChannelCount];
    int _swrContextBufferMallocSize[SGFFAudioFrameMaxChannelCount];
}

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) SGAudioStreamPlayer * audioPlayer;
@property (nonatomic, strong) SGFFObjectQueue * frameQueue;

@property (nonatomic, strong) SGFFAudioFrame * currentFrame;
@property (nonatomic, assign) long long currentRenderReadOffset;
@property (nonatomic, assign) CMTime currentPreparePosition;
@property (nonatomic, assign) CMTime currentPrepareDuration;
@property (nonatomic, assign) BOOL didUpdateTimeSynchronizer;

@property (nonatomic, assign) SwrContext * swrContext;
@property (nonatomic, assign) NSError * swrContextError;

@property (nonatomic, assign) enum AVSampleFormat inputFormat;
@property (nonatomic, assign) enum AVSampleFormat outputFormat;
@property (nonatomic, assign) int inputSampleRate;
@property (nonatomic, assign) int inputNumberOfChannels;
@property (nonatomic, assign) int outputSampleRate;
@property (nonatomic, assign) int outputNumberOfChannels;

@end

@implementation SGFFAudioPlaybackOutput

@synthesize delegate = _delegate;
@synthesize timeSynchronizer = _timeSynchronizer;

- (SGMediaType)mediaType
{
    return SGMediaTypeAudio;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.audioPlayer = [[SGAudioStreamPlayer alloc] init];
        self.audioPlayer.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    [self stop];
}

#pragma mark - Interface

- (void)start
{
    self.frameQueue = [[SGFFObjectQueue alloc] init];
    self.currentRenderReadOffset = 0;
    self.currentPreparePosition = kCMTimeZero;
    self.currentPrepareDuration = kCMTimeZero;
    self.didUpdateTimeSynchronizer = NO;
}

- (void)stop
{
    [self.audioPlayer pause];
    [self lock];
    [self.currentFrame unlock];
    self.currentFrame = nil;
    self.currentRenderReadOffset = 0;
    self.currentPreparePosition = kCMTimeZero;
    self.currentPrepareDuration = kCMTimeZero;
    self.didUpdateTimeSynchronizer = NO;
    [self unlock];
    [self.frameQueue destroy];
    [self destorySwrContextBuffer];
    [self destorySwrContext];
}

- (void)putFrame:(__kindof SGFFFrame *)frame
{
    if (![frame isKindOfClass:[SGFFAudioFrame class]])
    {
        return;
    }
    SGFFAudioFrame * audioFrame = frame;
    
    enum AVSampleFormat inputFormat = audioFrame.format;
    enum AVSampleFormat outputFormat = AV_SAMPLE_FMT_FLTP;
    int inputSampleRate = audioFrame.sampleRate;
    int inputNumberOfChannels = audioFrame.numberOfChannels;
    int outputSampleRate = self.audioPlayer.asbd.mSampleRate;
    int outputNumberOfChannels = self.audioPlayer.asbd.mChannelsPerFrame;
    
    if (self.inputFormat != inputFormat ||
        self.outputFormat != outputFormat ||
        self.inputSampleRate != inputSampleRate ||
        self.outputSampleRate != outputSampleRate ||
        self.inputNumberOfChannels != inputNumberOfChannels ||
        self.outputNumberOfChannels != outputNumberOfChannels)
    {
        self.inputFormat = inputFormat;
        self.outputFormat = outputFormat;
        self.inputSampleRate = inputSampleRate;
        self.outputSampleRate = outputSampleRate;
        self.inputNumberOfChannels = inputNumberOfChannels;
        self.outputNumberOfChannels = outputNumberOfChannels;
        
        [self destorySwrContext];
        [self setupSwrContext];
    }
    
    if (!self.swrContext)
    {
        return;
    }
    const int numberOfChannelsRatio = MAX(1, self.outputNumberOfChannels / self.inputNumberOfChannels);
    const int sampleRateRatio = MAX(1, self.outputSampleRate / self.inputSampleRate);
    const int ratio = sampleRateRatio * numberOfChannelsRatio;
    const int bufferSize = av_samples_get_buffer_size(NULL, 1, audioFrame.numberOfSamples * ratio, self.outputFormat, 1);
    [self setupSwrContextBufferIfNeeded:bufferSize];
    int numberOfSamples = swr_convert(self.swrContext,
                                      (uint8_t **)_swrContextBufferData,
                                      audioFrame.numberOfSamples * ratio,
                                      (const uint8_t **)audioFrame.data,
                                      audioFrame.numberOfSamples);
    [self updateSwrContextBufferLinsize:numberOfSamples * sizeof(float)];
    
    SGFFAudioBufferFrame * result = [[SGFFObjectPool sharePool] objectWithClass:[SGFFAudioBufferFrame class]];
    result.position = audioFrame.position;
    result.duration = audioFrame.duration;
    result.size = audioFrame.size;
    result.format = AV_SAMPLE_FMT_FLTP;
    result.numberOfSamples = numberOfSamples;
    result.sampleRate = self.outputSampleRate;
    result.numberOfChannels = self.outputNumberOfChannels;
    result.channelLayout = audioFrame.channelLayout;
    result.bestEffortTimestamp = audioFrame.bestEffortTimestamp;
    result.packetPosition = audioFrame.packetPosition;
    result.packetDuration = audioFrame.packetDuration;
    result.packetSize = audioFrame.packetSize;
    [result updateData:_swrContextBufferData linesize:_swrContextBufferLinesize];
    if (!self.didUpdateTimeSynchronizer && self.frameQueue.count == 0)
    {
        [self.timeSynchronizer updatePosition:result.position duration:kCMTimeZero rate:CMTimeMake(1, 1)];
    }
    [self.frameQueue putObjectSync:result];
    [self.delegate outputDidChangeCapacity:self];
    [result unlock];
}

- (void)flush
{
    [self lock];
    [self.currentFrame unlock];
    self.currentFrame = nil;
    self.currentRenderReadOffset = 0;
    self.currentPreparePosition = kCMTimeZero;
    self.currentPrepareDuration = kCMTimeZero;
    self.didUpdateTimeSynchronizer = NO;
    [self unlock];
    [self.frameQueue flush];
    [self.timeSynchronizer flush];
    [self.delegate outputDidChangeCapacity:self];
}

- (void)play
{
    [self.audioPlayer play];
}

- (void)pause
{
    [self.audioPlayer pause];
}

#pragma mark - Setter/Getter

- (CMTime)duration
{
    return self.frameQueue.duration;
}

- (long long)size
{
    return self.frameQueue.size;
}

- (NSUInteger)count
{
    return self.frameQueue.count;
}

- (NSUInteger)maxCount
{
    return 5;
}

- (NSError *)error
{
    if (self.audioPlayer.error)
    {
        return self.audioPlayer.error;
    }
    return self.swrContextError;
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
    [self.audioPlayer setRate:CMTimeGetSeconds(rate) error:nil];
}

- (CMTime)rate
{
    return SGTimeMakeWithSeconds(self.audioPlayer.rate);
}

#pragma mark - swr

- (void)setupSwrContext
{
    if (self.swrContextError || self.swrContext)
    {
        return;
    }
    self.swrContext = swr_alloc_set_opts(NULL,
                                         av_get_default_channel_layout(self.outputNumberOfChannels),
                                         self.outputFormat,
                                         self.outputSampleRate,
                                         av_get_default_channel_layout(self.inputNumberOfChannels),
                                         self.inputFormat,
                                         self.inputSampleRate,
                                         0, NULL);
    int result = swr_init(self.swrContext);
    self.swrContextError = SGFFGetErrorCode(result, SGFFErrorCodeAuidoSwrInit);
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
    for (int i = 0; i < SGFFAudioFrameMaxChannelCount; i++)
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
    for (int i = 0; i < SGFFAudioFrameMaxChannelCount; i++)
    {
        _swrContextBufferLinesize[i] = (i < self.outputNumberOfChannels) ? linesize : 0;
    }
}

- (void)destorySwrContextBuffer
{
    for (int i = 0; i < SGFFAudioFrameMaxChannelCount; i++)
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
        
        long long residueLinesize = self.currentFrame.linesize[0] - self.currentRenderReadOffset;
        long long bytesToCopy = MIN(numberOfSamples * sizeof(float), residueLinesize);
        long long framesToCopy = bytesToCopy / sizeof(float);
        
        for (int i = 0; i < ioData->mNumberBuffers && i < self.currentFrame.numberOfChannels; i++)
        {
            if (self.currentFrame.linesize[i] - self.currentRenderReadOffset >= bytesToCopy)
            {
                Byte * bytes = (Byte *)self.currentFrame.data[i] + self.currentRenderReadOffset;
                memcpy(ioData->mBuffers[i].mData + ioDataWriteOffset, bytes, bytesToCopy);
            }
        }
        
        if (ioDataWriteOffset == 0)
        {
            self.currentPrepareDuration = kCMTimeZero;
            CMTime duration = SGTimeMultiplyByRatio(self.currentFrame.duration, self.currentRenderReadOffset, self.currentFrame.linesize[0]);
            self.currentPreparePosition = CMTimeAdd(self.currentFrame.position, duration);
        }
        CMTime duration = SGTimeMultiplyByRatio(self.currentFrame.duration, bytesToCopy, self.currentFrame.linesize[0]);
        self.currentPrepareDuration = CMTimeAdd(self.currentPrepareDuration, duration);
        
        numberOfSamples -= framesToCopy;
        ioDataWriteOffset += bytesToCopy;
        
        if (bytesToCopy < residueLinesize)
        {
            self.currentRenderReadOffset += bytesToCopy;
        }
        else
        {
            [self.currentFrame unlock];
            self.currentFrame = nil;
            self.currentRenderReadOffset = 0;
        }
    }
    [self unlock];
    if (hasNewFrame)
    {
        [self.delegate outputDidChangeCapacity:self];
    }
}

- (void)audioStreamPlayer:(SGAudioStreamPlayer *)audioDataPlayer postSample:(const AudioTimeStamp *)timestamp
{
    [self lock];
    self.didUpdateTimeSynchronizer = YES;
    [self.timeSynchronizer updatePosition:self.currentPreparePosition duration:self.currentPrepareDuration rate:self.rate];
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
