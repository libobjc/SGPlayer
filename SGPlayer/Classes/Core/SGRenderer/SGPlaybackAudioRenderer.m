//
//  SGPlaybackAudioRenderer.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPlaybackAudioRenderer.h"
#import "SGAudioStreamPlayer.h"
#import "SGAudioFrame.h"
#import "SGLock.h"

@interface SGPlaybackAudioRenderer () <SGAudioStreamPlayerDelegate>

{
    SGRenderableState _state;
}

@property (nonatomic, strong) SGPlaybackClock * clock;
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) SGCapacity * capacity;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;
@property (nonatomic, strong) SGAudioStreamPlayer * audioPlayer;

@property (nonatomic, strong) SGAudioFrame * currentFrame;
@property (nonatomic, assign) int32_t currentFrameReadOffset;
@property (nonatomic, assign) CMTime currentPostPosition;
@property (nonatomic, assign) CMTime currentPostDuration;

@end

@implementation SGPlaybackAudioRenderer

@synthesize object = _object;
@synthesize delegate = _delegate;
@synthesize key = _key;

- (instancetype)initWithClock:(SGPlaybackClock *)clock
{
    if (self = [super init]) {
        self.clock = clock;
        self.rate = CMTimeMake(1, 1);
        self.delay = CMTimeMake(0, 1);
        self.coreLock = [[NSLock alloc] init];
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

#pragma mark - Setter & Getter

- (SGBlock)setState:(SGRenderableState)state
{
    if (_state == state) {
        return ^{};
    }
    _state = state;
    return ^{
        [self.delegate renderable:self didChangeState:state];
    };
}

- (SGRenderableState)state
{
    __block SGRenderableState ret = SGRenderableStateNone;
    SGLockEXE00(self.coreLock, ^{
        ret = self->_state;
    });
    return ret;
}

- (SGCapacity *)capacity
{
    __block SGCapacity * ret = nil;
    SGLockEXE00(self.coreLock, ^{
        ret = [self->_capacity copy];
    });
    return ret ? ret : [[SGCapacity alloc] init];
}

- (void)setVolume:(float)volume
{
    if (_volume != volume) {
        _volume = volume;
        [self.audioPlayer setVolume:volume error:nil];
    }
}

- (void)setRate:(CMTime)rate
{
    if (CMTimeCompare(_rate, rate) != 0) {
        _rate = rate;
        [self.audioPlayer setRate:CMTimeGetSeconds(rate) error:nil];
    }
}

#pragma mark - Interface

- (BOOL)open
{
    return SGLockCondEXE10(self.coreLock, ^BOOL {
        return self->_state == SGRenderableStateNone;
    }, ^SGBlock {
        return [self setState:SGRenderableStatePaused];
    });
}

- (BOOL)close
{
    return SGLockCondEXE11(self.coreLock, ^BOOL {
        return self->_state != SGRenderableStateClosed;
    }, ^SGBlock {
        [self.currentFrame unlock];
        self.currentFrame = nil;
        self.currentFrameReadOffset = 0;
        self.currentPostPosition = kCMTimeZero;
        self.currentPostDuration = kCMTimeZero;
        return [self setState:SGRenderableStateClosed];
    }, ^BOOL(SGBlock block) {
        [self.audioPlayer pause];
        block();
        return YES;
    });
}

- (BOOL)pause
{
    return SGLockCondEXE11(self.coreLock, ^BOOL {
        return self->_state == SGRenderableStateRendering;
    }, ^SGBlock {
        return [self setState:SGRenderableStatePaused];
    }, ^BOOL(SGBlock block) {
        [self.audioPlayer pause];
        block();
        return YES;
    });
}

- (BOOL)resume
{
    return SGLockCondEXE11(self.coreLock, ^BOOL {
        return self->_state == SGRenderableStatePaused;
    }, ^SGBlock {
        return [self setState:SGRenderableStateRendering];
    }, ^BOOL(SGBlock block) {
        [self.audioPlayer play];
        block();
        return YES;
    });
}

- (BOOL)flush
{
    SGLockCondEXE00(self.coreLock, ^BOOL {
        return self->_state == SGRenderableStatePaused || self->_state == SGRenderableStateRendering;
    }, ^{
        [self.currentFrame unlock];
        self.currentFrame = nil;
        self.currentFrameReadOffset = 0;
        self.currentPostPosition = kCMTimeZero;
        self.currentPostDuration = kCMTimeZero;
    });
    return YES;
}

#pragma mark - SGAudioStreamPlayerDelegate

- (void)audioStreamPlayer:(SGAudioStreamPlayer *)player render:(const AudioTimeStamp *)timeStamp data:(AudioBufferList *)data nb_samples:(uint32_t)nb_samples
{
    [self.coreLock lock];
    NSUInteger ioDataWriteOffset = 0;
    while (nb_samples > 0) {
        if (!self.currentFrame) {
            [self.coreLock unlock];
            SGAudioFrame * frame = [self.delegate renderable:self fetchFrame:nil];
            [self.coreLock lock];
            self.currentFrame = frame;
        }
        if (!self.currentFrame) {
            break;
        }
        
        int32_t residueLinesize = self.currentFrame->_linesize[0] - self.currentFrameReadOffset;
        int32_t bytesToCopy = MIN(nb_samples * (int32_t)sizeof(float), residueLinesize);
        int32_t framesToCopy = bytesToCopy / sizeof(float);
        
        for (int i = 0; i < data->mNumberBuffers && i < self.currentFrame.nb_samples; i++) {
            if (self.currentFrame->_linesize[i] - self.currentFrameReadOffset >= bytesToCopy) {
                Byte * bytes = (Byte *)self.currentFrame->_data[i] + self.currentFrameReadOffset;
                memcpy(data->mBuffers[i].mData + ioDataWriteOffset, bytes, bytesToCopy);
            }
        }
        
        if (ioDataWriteOffset == 0) {
            self.currentPostDuration = kCMTimeZero;
            CMTime duration = CMTimeMultiplyByRatio(self.currentFrame.duration, self.currentFrameReadOffset, self.currentFrame->_linesize[0]);
            self.currentPostPosition = CMTimeAdd(self.currentFrame.timeStamp, duration);
        }
        CMTime duration = CMTimeMultiplyByRatio(self.currentFrame.duration, bytesToCopy, self.currentFrame->_linesize[0]);
        duration = SGCMTimeMultiply(duration, CMTimeMake(1, 1));
        self.currentPostDuration = CMTimeAdd(self.currentPostDuration, duration);
        
        nb_samples -= framesToCopy;
        ioDataWriteOffset += bytesToCopy;
        
        if (bytesToCopy < residueLinesize) {
            self.currentFrameReadOffset += bytesToCopy;
        } else {
            [self.currentFrame unlock];
            self.currentFrame = nil;
            self.currentFrameReadOffset = 0;
        }
    }
    [self.coreLock unlock];
}

- (void)audioStreamPlayer:(SGAudioStreamPlayer *)player postRender:(const AudioTimeStamp *)timestamp
{
    [self.coreLock lock];
    CMTime currentPostPosition = self.currentPostPosition;
    CMTime currentPostDuration = self.currentPostDuration;
    CMTime rate = self.rate;
    CMTime delay = self.delay;
    dispatch_block_t block = ^{
        [self.clock updateKeyTime:currentPostPosition duration:currentPostDuration rate:rate];
    };
    if (CMTimeCompare(delay, kCMTimeZero) > 0) {
        if (!self.delegateQueue) {
            self.delegateQueue = dispatch_queue_create("SGPlaybackAudioRenderer-DelegateQueue", DISPATCH_QUEUE_SERIAL);
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CMTimeGetSeconds(delay) * NSEC_PER_SEC)), self.delegateQueue, block);
    } else {
        block();
    }
    [self.coreLock unlock];
}

@end
