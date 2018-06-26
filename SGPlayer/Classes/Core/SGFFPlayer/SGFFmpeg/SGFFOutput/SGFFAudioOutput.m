//
//  SGFFAudioOutput.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAudioOutput.h"
#import "SGFFAudioPlayer.h"
#import "SGFFAudioBufferFrame.h"
#import "SGFFTime.h"
#import "SGFFError.h"
#import "swscale.h"
#import "swresample.h"

@interface SGFFAudioOutput () <SGFFAudioPlayerDelegate>

{
    SwrContext * _swrContext;
    void * _swrContextBufferData[SGFFAudioFrameMaxChannelCount];
    int _swrContextBufferLinesize[SGFFAudioFrameMaxChannelCount];
    int _swrContextBufferMallocSize[SGFFAudioFrameMaxChannelCount];
}

@property (nonatomic, strong) SGFFAudioPlayer * audioPlayer;
@property (nonatomic, strong) SGFFObjectQueue * frameQueue;
@property (nonatomic, strong) SGFFAudioFrame * currentFrame;
@property (nonatomic, assign) long long currentRenderReadOffset;
@property (nonatomic, assign) CMTime currentPreparePosition;
@property (nonatomic, assign) CMTime currentPrepareDuration;

@property (nonatomic, assign) enum AVSampleFormat inputFormat;
@property (nonatomic, assign) int inputSampleRate;
@property (nonatomic, assign) int inputNumberOfChannels;
@property (nonatomic, assign) int outputSampleRate;
@property (nonatomic, assign) int outputNumberOfChannels;

@property (nonatomic, assign) NSError * swrContextError;

@end

@implementation SGFFAudioOutput

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
        self.frameQueue = [[SGFFObjectQueue alloc] init];
        self.audioPlayer = [[SGFFAudioPlayer alloc] initWithDelegate:self];
        self.currentPreparePosition = kCMTimeZero;
        self.currentPrepareDuration = kCMTimeZero;
    }
    return self;
}

- (void)dealloc
{
    [self.audioPlayer pause];
    [self stop];
}

#pragma mark - Interface

- (void)start
{
    
}

- (void)stop
{
    [self.frameQueue destroy];
    [self.currentFrame unlock];
    self.currentFrame = nil;
    self.currentRenderReadOffset = 0;
    [self clearSwrContext];
}

- (void)putFrame:(__kindof SGFFFrame *)frame
{
    if (![frame isKindOfClass:[SGFFAudioFrame class]])
    {
        return;
    }
    SGFFAudioFrame * audioFrame = frame;
    
    self.inputFormat = audioFrame.format;
    self.inputSampleRate = audioFrame.sampleRate;
    self.inputNumberOfChannels = audioFrame.numberOfChannels;
    self.outputSampleRate = self.audioPlayer.sampleRate;
    self.outputNumberOfChannels = self.audioPlayer.numberOfChannels;
    
    [self setupSwrContextIfNeeded];
    if (!_swrContext)
    {
        return;
    }
    const int numberOfChannelsRatio = MAX(1, self.audioPlayer.numberOfChannels / audioFrame.numberOfChannels);
    const int sampleRateRatio = MAX(1, self.audioPlayer.sampleRate / audioFrame.sampleRate);
    const int ratio = sampleRateRatio * numberOfChannelsRatio;
    const int bufferSize = av_samples_get_buffer_size(NULL, 1,
                                                      audioFrame.numberOfSamples * ratio,
                                                      AV_SAMPLE_FMT_FLTP, 1);
    [self setupSwrContextBufferIfNeeded:bufferSize];
    int numberOfSamples = swr_convert(_swrContext,
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
    [self.frameQueue putObjectSync:result];
    [self.delegate outputDidChangeCapacity:self];
    [result unlock];
}

- (void)flush
{
    [self.currentFrame unlock];
    self.currentFrame = nil;
    self.currentRenderReadOffset = 0;
    [self.frameQueue flush];
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

#pragma mark - swr

- (void)setupSwrContextIfNeeded
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

- (void)clearSwrContext
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
        if (!self.currentFrame)
        {
            self.currentFrame = [self.frameQueue getObjectAsync];
            [self.delegate outputDidChangeCapacity:self];
        }
        if (!self.currentFrame)
        {
            return;
        }
        
        long long residueLinesize = self.currentFrame.linesize[0] - self.currentRenderReadOffset;
        long long bytesToCopy = MIN(numberOfSamples * sizeof(float), residueLinesize);
        long long framesToCopy = bytesToCopy / sizeof(float);
        
        for (int i = 0; i < ioData->mNumberBuffers && i < numberOfChannels; i++)
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
            CMTime duration = SGFFTimeMultiplyByRatio(self.currentFrame.duration, self.currentRenderReadOffset, self.currentFrame.linesize[0]);
            self.currentPreparePosition = CMTimeAdd(self.currentFrame.position, duration);
        }
        CMTime duration = SGFFTimeMultiplyByRatio(self.currentFrame.duration, bytesToCopy, self.currentFrame.linesize[0]);
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
}

- (void)audioPlayerDidRenderSample:(SGFFAudioPlayer *)audioPlayer sampleTimestamp:(const AudioTimeStamp *)sampleTimestamp
{
    [self.timeSynchronizer postPosition:self.currentPreparePosition duration:self.currentPrepareDuration];
}

@end
