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
#import "SGMapping.h"
#import "SGFFmpeg.h"
#import "SGMacro.h"

@interface SGPlayerItem () <SGFrameOutputDelegate, SGRenderableDelegate>

{
    SGPlayerItemState _state;
}

@property (nonatomic, copy) NSError * error;
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, assign) NSUInteger seekingCount;
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
        self.coreLock = [[NSLock alloc] init];
        self.frameOutput = [[SGFrameOutput alloc] initWithAsset:asset];
        self.frameOutput.delegate = self;
    }
    return self;
}

#pragma mark - Interface

- (BOOL)open
{
    SGFFmpegSetupIfNeeded();
    [self.coreLock lock];
    if (self.state != SGPlayerItemStateNone)
    {
        [self.coreLock unlock];
        return NO;
    }
    SGBasicBlock callback = [self setState:SGPlayerItemStateOpening];
    [self.coreLock unlock];
    callback();
    [self.frameOutput open];
    return YES;
}

- (BOOL)start
{
    [self.coreLock lock];
    if (self.state != SGPlayerItemStateOpened)
    {
        [self.coreLock unlock];
        return NO;
    }
    SGBasicBlock callback = [self setState:SGPlayerItemStateReading];
    [self.coreLock unlock];
    callback();
    [self.frameOutput start];
    return YES;
}

- (BOOL)close
{
    [self.coreLock lock];
    if (self.state == SGPlayerItemStateClosed)
    {
        [self.coreLock unlock];
        return NO;
    }
    SGBasicBlock callback = [self setState:SGPlayerItemStateClosed];
    [self.coreLock unlock];
    callback();
    [self.frameOutput close];
    [self.audioRenderable close];
    [self.videoRenderable close];
    return YES;
}

#pragma mark - Seek

- (BOOL)seeking
{
    [self.coreLock lock];
    BOOL ret = self.seekingCount != 0;
    [self.coreLock unlock];
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
    [self.coreLock lock];
    if (self.state != SGPlayerItemStateReading &&
        self.state != SGPlayerItemStateFinished)
    {
        [self.coreLock unlock];
        return NO;
    }
    self.seekingCount++;
    NSInteger seekingCount = self.seekingCount;
    [self.coreLock unlock];
    SGWeakSelf
    [self.frameOutput seekToTime:time completionHandler:^(CMTime time, NSError * error) {
        SGStrongSelf
        [self.coreLock lock];
        if (seekingCount != self.seekingCount)
        {
            [self.coreLock unlock];
            return;
        }
        self.seekingCount = 0;
        [self.coreLock unlock];
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
            [self.delegate playerItemDidChangeState:self];
        };
    }
    return ^{};
}

SGGet0(SGPlayerItemState, state, _state);
SGGet0Map(CMTime, duration, self.frameOutput);
SGGet0Map(NSDictionary *, metadata, self.frameOutput);
SGGet0Map(NSArray <SGTrack *> *, tracks, self.frameOutput);
SGGet0Map(NSArray <SGTrack *> *, audioTracks, self.frameOutput);
SGGet0Map(NSArray <SGTrack *> *, videoTracks, self.frameOutput);
SGGet0Map(NSArray <SGTrack *> *, otherTracks, self.frameOutput);
SGGet0Map(NSArray <SGTrack *> *, selectedTracks, self.frameOutput);
SGSet1Map(setSelectedTracks, NSArray <SGTrack *> *, self.frameOutput)
SGGet0Map(SGTrack *, selectedAudioTrack, self.frameOutput);
SGGet0Map(SGTrack *, selectedVideoTrack, self.frameOutput);

- (SGCapacity *)bestCapacity
{
    SGCapacity * ret = [[SGCapacity alloc] init];
    SGTrack * track = self.selectedAudioTrack ? self.selectedAudioTrack : self.selectedVideoTrack;
    id <SGRenderable> renderable = self.audioRenderable != SGRenderableStateNone ? self.audioRenderable : self.videoRenderable;
    if (track && renderable) {
        for (SGCapacity * obj in [self capacityWithTracks:@[track] renderables:@[renderable]]) {
            ret.duration = CMTimeAdd(ret.duration, obj.duration);
            ret.size += obj.size;
            ret.count += obj.count;
        }
    }
    return ret;
}

- (NSArray <SGCapacity *> *)capacityWithTracks:(NSArray <SGTrack *> *)tracks renderables:(NSArray <id <SGRenderable>> *)renderables
{
    NSMutableArray * ret = [NSMutableArray array];
    for (SGCapacity * obj in [self.frameOutput capacityWithTracks:tracks]) {
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
            [self.coreLock lock];
            if (self.selectedAudioTrack)
            {
                self.audioRenderable.key = YES;
                self.audioRenderable.delegate = self;
                [self.audioRenderable open];
            }
            if (self.selectedVideoTrack)
            {
                self.videoRenderable.key = !self.selectedAudioTrack;
                self.videoRenderable.delegate = self;
                [self.videoRenderable open];
            }
            SGBasicBlock callback = [self setState:SGPlayerItemStateOpened];
            [self.coreLock unlock];
            callback();
        }
            break;
        case SGFrameOutputStateReading:
        {
            [self.coreLock lock];
            SGBasicBlock callback = [self setState:SGPlayerItemStateReading];
            [self.coreLock unlock];
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
            [self.coreLock lock];
            SGBasicBlock callback = [self setState:SGPlayerItemStateFailed];
            [self.coreLock unlock];
            callback();
        }
            break;
        default:
            break;
    }
}

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeCapacity:(SGCapacity *)capacity track:(SGTrack *)track
{
    [self.delegate playerItemDidChangeCapacity:self];
}

- (void)frameOutput:(SGFrameOutput *)frameOutput didOutputFrame:(SGFrame *)frame
{
    if (frame.track.type == SGMediaTypeAudio)
    {
        [self.audioRenderable putFrame:frame];
    }
    else if (frame.track.type == SGMediaTypeVideo)
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
            [self.frameOutput pause:self.frameOutput.audioTracks];
        } else {
            [self.frameOutput resume:self.frameOutput.audioTracks];
        }
    }
    else if (renderable == self.videoRenderable)
    {
        if (self.videoRenderable.enough) {
            [self.frameOutput pause:self.frameOutput.videoTracks];
        } else {
            [self.frameOutput resume:self.frameOutput.videoTracks];
        }
    }
    [self.delegate playerItemDidChangeCapacity:self];
    [self callbackForFinisehdIfNeeded];
}

- (void)renderable:(id <SGRenderable>)renderable didRenderFrame:(__kindof SGFrame *)frame
{
    
}

#pragma mark - Callback

- (void)callbackForFinisehdIfNeeded
{
    if ([self finished]) {
        [self.coreLock lock];
        SGBasicBlock callback = [self setState:SGPlayerItemStateFinished];
        [self.coreLock unlock];
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

@end
