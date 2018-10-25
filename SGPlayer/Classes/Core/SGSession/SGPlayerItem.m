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

- (NSArray <SGCapacity *> *)capacityWithStreams:(NSArray <SGStream *> *)streams renderables:(NSArray <id <SGRenderable>> *)renderables
{
    NSMutableArray * ret = [NSMutableArray array];
    for (SGCapacity * obj in [self.frameOutput capacityWithStreams:streams]) {
        [ret addObject:obj];
    }
    for (id <SGRenderable> obj in renderables) {
        SGCapacity * c = obj.capacity;
        c.object = obj;
        [ret addObject:c];
    }
    return [ret copy];
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
        NSUInteger sourceCount = [self.frameOutput capacityWithStreams:@[self.frameOutput.audioStreams.firstObject]].firstObject.count;
        NSUInteger outputCount = self.audioRenderable.capacity.count;
        return sourceCount == 0 && outputCount == 0;
    }
    return YES;
}

- (BOOL)videoEmpty
{
    if (self.videoEnable && self.videoRenderable)
    {
        NSUInteger sourceCount = [self.frameOutput capacityWithStreams:@[self.frameOutput.videoStreams.firstObject]].firstObject.count;
        NSUInteger outputCount = self.audioRenderable.capacity.count;
        return sourceCount == 0 && outputCount == 0;
    }
    return YES;
}

- (CMTime)audioLoadedDuration
{
    if (self.audioEnable && self.audioRenderable)
    {
        CMTime sourceDuration = [self.frameOutput capacityWithStreams:@[self.frameOutput.audioStreams.firstObject]].firstObject.duration;
        CMTime outputDuration = self.audioRenderable.capacity.duration;
        return CMTimeAdd(sourceDuration, outputDuration);
    }
    return kCMTimeZero;
}

- (CMTime)videoLoadedDuration
{
    if (self.videoEnable && self.videoRenderable)
    {
        CMTime sourceDuration = [self.frameOutput capacityWithStreams:@[self.frameOutput.videoStreams.firstObject]].firstObject.duration;
        CMTime outputDuration = self.videoRenderable.capacity.duration;
        return CMTimeAdd(sourceDuration, outputDuration);
    }
    return kCMTimeZero;
}

- (long long)audioLoadedSize
{
    int64_t sourceSize = [self.frameOutput capacityWithStreams:@[self.frameOutput.audioStreams.firstObject]].firstObject.size;
    int64_t outputSzie = self.audioRenderable.capacity.size;
    return sourceSize + outputSzie;
}

- (long long)videoLoadedSize
{
    int64_t sourceSize = [self.frameOutput capacityWithStreams:@[self.frameOutput.videoStreams.firstObject]].firstObject.size;
    int64_t outputSzie = self.videoRenderable.capacity.size;
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

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeCapacity:(SGCapacity *)capacity stream:(SGStream *)stream
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
