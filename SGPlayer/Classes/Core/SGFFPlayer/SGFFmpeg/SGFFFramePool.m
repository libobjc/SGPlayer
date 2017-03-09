//
//  SGFFFramePool.m
//  SGPlayer
//
//  Created by Single on 2017/3/3.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGFFFramePool.h"
#import "SGPlayerMacro.h"

@interface SGFFFramePool () <SGFFFrameDelegate>

@property (nonatomic, copy) Class frameClassName;
@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) SGFFFrame * playingFrame;
@property (nonatomic, strong) NSMutableSet <SGFFFrame *> * unuseFrames;
@property (nonatomic, strong) NSMutableSet <SGFFFrame *> * usedFrames;

@end

@implementation SGFFFramePool

+ (instancetype)videoPool
{
    return [self poolWithCapacity:60 frameClassName:NSClassFromString(@"SGFFAVYUVVideoFrame")];
}

+ (instancetype)audioPool
{
    return [self poolWithCapacity:500 frameClassName:NSClassFromString(@"SGFFAudioFrame")];
}

+ (instancetype)poolWithCapacity:(NSUInteger)number frameClassName:(Class)frameClassName
{
    return [[self alloc] initWithCapacity:number frameClassName:frameClassName];
}

- (instancetype)initWithCapacity:(NSUInteger)number frameClassName:(Class)frameClassName
{
    if (self = [super init]) {
        self.frameClassName = frameClassName;
        self.lock = [[NSLock alloc] init];
        self.unuseFrames = [NSMutableSet setWithCapacity:number];
        self.usedFrames = [NSMutableSet setWithCapacity:number];
    }
    return self;
}

- (NSUInteger)count
{
    return [self unuseCount] + [self usedCount] + (self.playingFrame ? 1 : 0);
}

- (NSUInteger)unuseCount
{
    return self.unuseFrames.count;
}

- (NSUInteger)usedCount
{
    return self.usedFrames.count;
}

- (__kindof SGFFFrame *)getUnuseFrame
{
    [self.lock lock];
    SGFFFrame * frame;
    if (self.unuseFrames.count > 0) {
        frame = [self.unuseFrames anyObject];
        [self.unuseFrames removeObject:frame];
        [self.usedFrames addObject:frame];
        
    } else {
        frame = [[self.frameClassName alloc] init];
        frame.delegate = self;
        [self.usedFrames  addObject:frame];
    }
    [self.lock unlock];
    return frame;
}

- (void)setFrameUnuse:(SGFFFrame *)frame
{
    if (!frame) return;
    if (![frame isKindOfClass:self.frameClassName]) return;
    [self.lock lock];
    [self.unuseFrames addObject:frame];
    [self.usedFrames removeObject:frame];
    [self.lock unlock];
}

- (void)setFramesUnuse:(NSArray <SGFFFrame *> *)frames
{
    if (frames.count <= 0) return;
    [self.lock lock];
    for (SGFFFrame * obj in frames) {
        if (![obj isKindOfClass:self.frameClassName]) continue;
        [self.usedFrames removeObject:obj];
        [self.unuseFrames addObject:obj];
    }
    [self.lock unlock];
}

- (void)setFrameStartDrawing:(SGFFFrame *)frame
{
    if (!frame) return;
    if (![frame isKindOfClass:self.frameClassName]) return;
    [self.lock lock];
    if (self.playingFrame) {
        [self.unuseFrames addObject:self.playingFrame];
    }
    self.playingFrame = frame;
    [self.usedFrames removeObject:self.playingFrame];
    [self.lock unlock];
}

- (void)setFrameStopDrawing:(SGFFFrame *)frame
{
    if (!frame) return;
    if (![frame isKindOfClass:self.frameClassName]) return;
    [self.lock lock];
    if (self.playingFrame == frame) {
        [self.unuseFrames addObject:self.playingFrame];
        self.playingFrame = nil;
    }
    [self.lock unlock];
}

- (void)flush
{
    [self.lock lock];
    [self.usedFrames enumerateObjectsUsingBlock:^(SGFFFrame * _Nonnull obj, BOOL * _Nonnull stop) {
        [self.unuseFrames addObject:obj];
    }];
    [self.usedFrames removeAllObjects];
    [self.lock unlock];
}

#pragma mark - SGFFFrameDelegate

- (void)frameDidStartPlaying:(SGFFFrame *)frame
{
    [self setFrameStartDrawing:frame];
}

- (void)frameDidStopPlaying:(SGFFFrame *)frame
{
    [self setFrameStopDrawing:frame];
}

- (void)frameDidCancel:(SGFFFrame *)frame
{
    [self setFrameUnuse:frame];
}

- (void)dealloc
{
    SGPlayerLog(@"SGFFFramePool release");
}

@end
