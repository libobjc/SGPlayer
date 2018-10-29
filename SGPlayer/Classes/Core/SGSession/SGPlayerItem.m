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

@property (nonatomic, weak) id <SGPlayerItemDelegate> delegate;
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

- (BOOL)start
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

- (void)setSelectedStreams:(NSArray <SGStream *> *)selectedStreams
{
    self.frameOutput.selectedStreams = selectedStreams;
}

- (SGStream *)selectedAudioStream
{
    return self.frameOutput.selectedAudioStream;
}

- (SGStream *)selectedVideoStream
{
    return self.frameOutput.selectedVideoStream;
}

- (SGCapacity *)bestCapacity
{
    SGCapacity * ret = [[SGCapacity alloc] init];
    SGStream * stream = self.selectedAudioStream ? self.selectedAudioStream : self.selectedVideoStream;
    id <SGRenderable> renderable = self.audioRenderable != SGRenderableStateNone ? self.audioRenderable : self.videoRenderable;
    if (stream && renderable) {
        for (SGCapacity * obj in [self capacityWithStreams:@[stream] renderables:@[renderable]]) {
            ret.duration = CMTimeAdd(ret.duration, obj.duration);
            ret.size += obj.size;
            ret.count += obj.count;
        }
    }
    return ret;
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

#pragma mark - SGFrameOutputDelegate

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeState:(SGFrameOutputState)state
{
    switch (state)
    {
        case SGFrameOutputStateOpened:
        {
            [self lock];
            if (self.selectedAudioStream)
            {
                self.audioRenderable.key = YES;
                self.audioRenderable.delegate = self;
                [self.audioRenderable open];
            }
            if (self.selectedVideoStream)
            {
                self.videoRenderable.key = !self.selectedAudioStream;
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
            [self callbackForFinisehdIfNeeded];
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
    [self.delegate sessionDidChangeCapacity:self];
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

- (void)renderable:(id <SGRenderable>)renderable didChangeState:(SGRenderableState)state
{
    
}

- (void)renderable:(id <SGRenderable>)renderable didChangeCapacity:(SGCapacity *)capacity
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
    [self.delegate sessionDidChangeCapacity:self];
    [self callbackForFinisehdIfNeeded];
}

- (void)renderable:(id <SGRenderable>)renderable didRenderFrame:(__kindof SGFrame *)frame
{
    
}

#pragma mark - Callback

- (void)callbackForFinisehdIfNeeded
{
    if ([self finished]) {
        [self lock];
        SGBasicBlock callback = [self setState:SGPlayerItemStateFinished];
        [self unlock];
        callback();
    }
}

- (BOOL)finished
{
    BOOL finished = self.frameOutput.state == SGFrameOutputStateFinished;
    if (finished) {
        finished = finished && self.audioRenderable.capacity.count == 0;
        finished = finished && self.videoRenderable.capacity.count == 0;
    }
    return finished;
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
