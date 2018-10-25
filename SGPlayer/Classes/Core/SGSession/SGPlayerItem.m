//
//  SGPlayerItem.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPlayerItem.h"
#import "SGPlayerItem+Internal.h"
#import "SGFrameOutput.h"
#import "SGFFmpeg.h"
#import "SGMacro.h"
#import "SGError.h"
#import "SGTime.h"

@interface SGPlayerItem () <NSLocking, SGFrameOutputDelegate, SGRenderableDelegate>

{
    SGPlayerItemState _state;
}

@property (nonatomic, copy) NSError * error;
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, assign) NSUInteger seekingToken;
@property (nonatomic, strong) SGFrameOutput * frameOutput;

@property (nonatomic, weak) id <SGPlayerItemInternalDelegate> delegateInternal;
@property (nonatomic, strong) id <SGRenderable> audioRenderable;
@property (nonatomic, strong) id <SGRenderable> videoRenderable;

@end

@implementation SGPlayerItem

- (instancetype)initWithAsset:(SGAsset *)asset
{
    if (self = [super init])
    {
        self.frameOutput = [[SGFrameOutput alloc] initWithAsset:asset];
        self.frameOutput.delegate = self;
    }
    return self;
}

#pragma mark - Interface

- (BOOL)open
{
    SGFFmpegSetupIfNeeded();
    [self lock];
    if (self.state != SGPlayerItemStateNone)
    {
        [self unlock];
        return NO;
    }
    SGBasicBlock callback = [self setState:SGPlayerItemStateOpening];
    [self unlock];
    callback();
    [self.frameOutput open];
    return YES;
}

- (BOOL)load
{
    [self lock];
    if (self.state != SGPlayerItemStateOpened)
    {
        [self unlock];
        return NO;
    }
    SGBasicBlock callback = [self setState:SGPlayerItemStateReading];
    [self unlock];
    callback();
    [self.frameOutput start];
    return YES;
}

- (BOOL)close
{
    [self lock];
    if (self.state == SGPlayerItemStateClosed)
    {
        [self unlock];
        return NO;
    }
    SGBasicBlock callback = [self setState:SGPlayerItemStateClosed];
    [self unlock];
    callback();
    [self.frameOutput close];
    [self.audioRenderable close];
    [self.videoRenderable close];
    return YES;
}

#pragma mark - Seek

- (BOOL)seeking
{
    [self lock];
    BOOL ret = self.seekingToken != 0;
    [self unlock];
    return ret;
}

- (BOOL)seekable
{
    return !self.frameOutput.seekable;
}

- (BOOL)seekToTime:(CMTime)time completionHandler:(void (^)(CMTime, NSError *))completionHandler
{
    if (![self seekable])
    {
        return NO;
    }
    [self lock];
    if (self.state != SGPlayerItemStateReading &&
        self.state != SGPlayerItemStateFinished)
    {
        [self unlock];
        return NO;
    }
    self.seekingToken++;
    NSInteger seekingToken = self.seekingToken;
    [self unlock];
    SGWeakSelf
    [self.frameOutput seekToTime:time completionHandler:^(CMTime time, NSError * error) {
        SGStrongSelf
        [self lock];
        if (seekingToken != self.seekingToken)
        {
            [self unlock];
            return;
        }
        self.seekingToken = 0;
        [self unlock];
        [self.audioRenderable flush];
        [self.videoRenderable flush];
        if (completionHandler)
        {
            completionHandler(time, error);
        }
    }];
    return YES;
}

#pragma mark - Setter & Getter

- (SGBasicBlock)setState:(SGPlayerItemState)state
{
    if (_state != state)
    {
        _state = state;
        return ^{
            [self.delegate sessionDidChangeState:self];
            [self.delegateInternal sessionDidChangeState:self];
        };
    }
    return ^{};
}

- (SGPlayerItemState)state
{
    return _state;
}

- (CMTime)duration
{
    return self.frameOutput.duration;
}

 - (NSDictionary *)metadata
{
    return self.frameOutput.metadata;
}

- (NSArray <SGStream *> *)streams
{
    return self.frameOutput.streams;
}

- (NSArray <SGStream *> *)audioStreams
{
    return self.frameOutput.audioStreams;
}

- (NSArray <SGStream *> *)videoStreams
{
    return self.frameOutput.videoStreams;
}

- (NSArray <SGStream *> *)otherStreams
{
    return self.frameOutput.otherStreams;
}

- (NSArray <SGStream *> *)selectedStreams
{
    return self.frameOutput.selectedStreams;
}

- (BOOL)setSelectedStreams:(NSArray <SGStream *> *)selectedStreams
{
    return self.frameOutput.selectedStreams = selectedStreams;
}

- (BOOL)duration:(CMTime *)duration size:(int64_t *)size count:(NSUInteger *)count stream:(SGStream *)stream renderable:(id <SGRenderable>)renderable
{
    CMTime outputDuration = kCMTimeZero;
    int64_t outputSize = 0;
    NSUInteger outputCount = 0;
    [self.frameOutput duration:&outputDuration size:&outputSize count:&outputCount stream:stream];
    
    CMTime renderableDuration = kCMTimeZero;
    int64_t renderableSize = 0;
    NSUInteger renderableCount = 0;
    [renderable duration:&renderableDuration size:&renderableSize count:&renderableCount];
    
    if (duration) {
        * duration = CMTimeAdd(outputDuration, renderableDuration);
    }
    if (size) {
        * size = outputSize + renderableSize;
    }
    if (count) {
        * count = outputCount + renderableCount;
    }
    
    return YES;
}

- (CMTime)loadedDuration
{
    return [self loadedDurationWithMainMediaType:SGMediaTypeAudio];
}

- (CMTime)loadedDurationWithMainMediaType:(SGMediaType)mainMediaType
{
    if (self.audioEnable && !self.videoEnable)
    {
        return self.audioLoadedDuration;
    }
    else if (!self.audioEnable && self.videoEnable)
    {
        return self.videoLoadedDuration;
    }
    else if (self.audioEnable && self.videoEnable)
    {
        if (mainMediaType == SGMediaTypeAudio)
        {
            return self.audioLoadedDuration;
        }
        else if (mainMediaType == SGMediaTypeVideo)
        {
            return self.videoLoadedDuration;
        }
    }
    return kCMTimeZero;
}

- (long long)loadedSize
{
    return [self loadedSizeWithMainMediaType:SGMediaTypeAudio];
}

- (long long)loadedSizeWithMainMediaType:(SGMediaType)mainMediaType
{
    if (self.audioEnable && !self.videoEnable)
    {
        return self.audioLoadedSize;
    }
    else if (!self.audioEnable && self.videoEnable)
    {
        return self.videoLoadedSize;
    }
    else if (self.audioEnable && self.videoEnable)
    {
        if (mainMediaType == SGMediaTypeAudio)
        {
            return self.audioLoadedSize;
        }
        else if (mainMediaType == SGMediaTypeVideo)
        {
            return self.videoLoadedSize;
        }
    }
    return 0;
}

- (BOOL)empty
{
    return [self emptyWithMainMediaType:SGMediaTypeAudio];
}

- (BOOL)emptyWithMainMediaType:(SGMediaType)mainMediaType
{
    if (self.audioEnable && !self.videoEnable)
    {
        return self.audioEmpty;
    }
    else if (!self.audioEnable && self.videoEnable)
    {
        return self.videoEmpty;
    }
    else if (self.audioEnable && self.videoEnable)
    {
        if (mainMediaType == SGMediaTypeAudio)
        {
            return self.audioEmpty;
        }
        else if (mainMediaType == SGMediaTypeVideo)
        {
            return self.videoEmpty;
        }
    }
    return YES;
}

- (BOOL)audioEnable
{
    return self.frameOutput.audioStreams.count > 0;
}

- (BOOL)videoEnable
{
    return self.frameOutput.videoStreams.count > 0;
}

- (BOOL)audioEmpty
{
    if (self.audioEnable && self.audioRenderable)
    {
        NSUInteger sourceCount = 0;
        [self.frameOutput duration:NULL size:NULL count:&sourceCount stream:self.frameOutput.audioStreams.firstObject];
        
        NSUInteger outputCount = 0;
        [self.audioRenderable duration:NULL size:NULL count:&outputCount];
        
        return sourceCount == 0 && outputCount == 0;
    }
    return YES;
}

- (BOOL)videoEmpty
{
    if (self.videoEnable && self.videoRenderable)
    {
        NSUInteger sourceCount = 0;
        [self.frameOutput duration:NULL size:NULL count:&sourceCount stream:self.frameOutput.videoStreams.firstObject];
        
        NSUInteger outputCount = 0;
        [self.videoRenderable duration:NULL size:NULL count:&outputCount];
        
        return sourceCount == 0 && outputCount == 0;
    }
    return YES;
}

- (CMTime)audioLoadedDuration
{
    if (self.audioEnable && self.audioRenderable)
    {
        CMTime sourceDuration = kCMTimeZero;
        [self.frameOutput duration:&sourceDuration size:NULL count:NULL stream:self.frameOutput.audioStreams.firstObject];
        
        CMTime outputDuration = kCMTimeZero;
        [self.audioRenderable duration:&outputDuration size:NULL count:NULL];
        
        return CMTimeAdd(sourceDuration, outputDuration);
    }
    return kCMTimeZero;
}

- (CMTime)videoLoadedDuration
{
    if (self.videoEnable && self.videoRenderable)
    {
        CMTime sourceDuration = kCMTimeZero;
        [self.frameOutput duration:&sourceDuration size:NULL count:NULL stream:self.frameOutput.videoStreams.firstObject];
        
        CMTime outputDuration = kCMTimeZero;
        [self.videoRenderable duration:&outputDuration size:NULL count:NULL];
        
        return CMTimeAdd(sourceDuration, outputDuration);
    }
    return kCMTimeZero;
}

- (long long)audioLoadedSize
{
    int64_t sourceSize = 0;
    [self.frameOutput duration:NULL size:&sourceSize count:NULL stream:self.frameOutput.audioStreams.firstObject];
    
    int64_t outputSzie = 0;
    [self.audioRenderable duration:NULL size:&outputSzie count:NULL];
    
    return sourceSize + outputSzie;
}

- (long long)videoLoadedSize
{
    int64_t sourceSize = 0;
    [self.frameOutput duration:NULL size:&sourceSize count:NULL stream:self.frameOutput.videoStreams.firstObject];
    
    int64_t outputSzie = 0;
    [self.videoRenderable duration:NULL size:&outputSzie count:NULL];
    
    return sourceSize + outputSzie;
}

#pragma mark - SGFrameOutputDelegate

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeState:(SGFrameOutputState)state
{
    switch (state)
    {
        case SGFrameOutputStateOpened:
        {
            [self lock];
            if (self.audioEnable)
            {
                self.audioRenderable.key = YES;
                self.audioRenderable.delegate = self;
                [self.audioRenderable open];
            }
            if (self.videoEnable)
            {
                self.videoRenderable.key = !self.audioEnable;
                self.videoRenderable.delegate = self;
                [self.videoRenderable open];
            }
            SGBasicBlock callback = [self setState:SGPlayerItemStateOpened];
            [self unlock];
            callback();
        }
            break;
        case SGFrameOutputStateReading:
        {
            [self lock];
            SGBasicBlock callback = [self setState:SGPlayerItemStateReading];
            [self unlock];
            callback();
        }
            break;
        case SGFrameOutputStateFinished:
        {
            [self lock];
            SGBasicBlock callback = [self setState:SGPlayerItemStateFinished];
            [self unlock];
            callback();
        }
            break;
        case SGFrameOutputStateFailed:
        {
            self.error = frameOutput.error;
            [self lock];
            SGBasicBlock callback = [self setState:SGPlayerItemStateFailed];
            [self unlock];
            callback();
        }
            break;
        default:
            break;
    }
}

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeDuration:(CMTime)duration size:(int64_t)size count:(NSUInteger)count stream:(SGStream *)stream
{
    [self.delegateInternal sessionDidChangeCapacity:self];
}

- (void)frameOutput:(SGFrameOutput *)frameOutput didOutputFrame:(SGFrame *)frame
{
    if (frame.stream.type == SGMediaTypeAudio)
    {
        [self.audioRenderable putFrame:frame];
    }
    else if (frame.stream.type == SGMediaTypeVideo)
    {
        [self.videoRenderable putFrame:frame];
    }
}

#pragma mark - SGRenderableDelegate

- (void)renderable:(id <SGRenderable>)renderable didRenderFrame:(__kindof SGFrame *)frame
{
    
}

- (void)renderable:(id <SGRenderable>)renderable didChangeState:(SGRenderableState)state
{
    
}

- (void)renderable:(id <SGRenderable>)renderable didChangeDuration:(CMTime)duration size:(int64_t)size count:(NSUInteger)count
{
    if (renderable == self.audioRenderable)
    {
        if (self.audioRenderable.enough) {
            [self.frameOutput pause:self.frameOutput.audioStreams];
        } else {
            [self.frameOutput resume:self.frameOutput.audioStreams];
        }
    }
    else if (renderable == self.videoRenderable)
    {
        if (self.videoRenderable.enough) {
            [self.frameOutput pause:self.frameOutput.videoStreams];
        } else {
            [self.frameOutput resume:self.frameOutput.videoStreams];
        }
    }
    [self.delegateInternal sessionDidChangeCapacity:self];
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
