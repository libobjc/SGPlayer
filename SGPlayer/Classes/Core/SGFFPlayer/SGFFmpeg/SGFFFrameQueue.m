//
//  SGFFFrameQueue.m
//  SGPlayer
//
//  Created by Single on 18/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFFrameQueue.h"

@interface SGFFFrameQueue ()

@property (nonatomic, assign) int size;
@property (nonatomic, assign) int packetSize;
@property (nonatomic, assign) NSUInteger count;
@property (atomic, assign) NSTimeInterval duration;

@property (nonatomic, strong) NSCondition * condition;
@property (nonatomic, strong) NSMutableArray <__kindof SGFFFrame *> * frames;

@property (nonatomic, assign) BOOL destoryToken;

@end

@implementation SGFFFrameQueue

+ (instancetype)frameQueue
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
        self.frames = [NSMutableArray array];
        self.condition = [[NSCondition alloc] init];
        self.minFrameCountForGet = 1;
        self.ignoreMinFrameCountForGetLimit = NO;
    }
    return self;
}

- (void)putFrame:(__kindof SGFFFrame *)frame
{
    if (!frame) return;
    [self.condition lock];
    if (self.destoryToken) {
        [self.condition unlock];
        return;
    }
    [self.frames addObject:frame];
    self.duration += frame.duration;
    self.size += frame.size;
    self.packetSize += frame.packetSize;
    [self.condition signal];
    [self.condition unlock];
}

- (void)putSortFrame:(__kindof SGFFFrame *)frame
{
    if (!frame) return;
    [self.condition lock];
    if (self.destoryToken) {
        [self.condition unlock];
        return;
    }
    BOOL added = NO;
    if (self.frames.count > 0) {
        for (int i = (int)self.frames.count - 1; i >= 0; i--) {
            SGFFFrame * obj = [self.frames objectAtIndex:i];
            if (frame.position > obj.position) {
                [self.frames insertObject:frame atIndex:i + 1];
                added = YES;
                break;
            }
        }
    }
    if (!added) {
        [self.frames addObject:frame];
        added = YES;
    }
    self.duration += frame.duration;
    self.size += frame.size;
    self.packetSize += frame.packetSize;
    [self.condition signal];
    [self.condition unlock];
}

- (__kindof SGFFFrame *)getFrameSync
{
    [self.condition lock];
    while (self.frames.count < self.minFrameCountForGet && !(self.ignoreMinFrameCountForGetLimit && self.frames.firstObject)) {
        if (self.destoryToken) {
            [self.condition unlock];
            return nil;
        }
        [self.condition wait];
    }
    SGFFFrame * frame = self.frames.firstObject;
    [self.frames removeObjectAtIndex:0];
    self.duration -= frame.duration;
    if (self.duration < 0 || self.count <= 0) {
        self.duration = 0;
    }
    self.size -= frame.size;
    if (self.size <= 0 || self.count <= 0) {
        self.size = 0;
    }
    self.packetSize -= frame.packetSize;
    if (self.packetSize <= 0 || self.count <= 0) {
        self.packetSize = 0;
    }
    [self.condition unlock];
    return frame;
}

- (__kindof SGFFFrame *)getFrameAsync
{
    [self.condition lock];
    if (self.destoryToken || self.frames.count <= 0) {
        [self.condition unlock];
        return nil;
    }
    if (!self.ignoreMinFrameCountForGetLimit && self.frames.count < self.minFrameCountForGet) {
        [self.condition unlock];
        return nil;
    }
    SGFFFrame * frame = self.frames.firstObject;
    [self.frames removeObjectAtIndex:0];
    self.duration -= frame.duration;
    if (self.duration < 0 || self.count <= 0) {
        self.duration = 0;
    }
    self.size -= frame.size;
    if (self.size <= 0 || self.count <= 0) {
        self.size = 0;
    }
    self.packetSize -= frame.packetSize;
    if (self.packetSize <= 0 || self.count <= 0) {
        self.packetSize = 0;
    }
    [self.condition unlock];
    return frame;
}

- (__kindof SGFFFrame *)getFrameAsyncPosistion:(NSTimeInterval)position discardFrames:(NSMutableArray <__kindof SGFFFrame *> **)discardFrames
{
    [self.condition lock];
    if (self.destoryToken || self.frames.count <= 0) {
        [self.condition unlock];
        return nil;
    }
    if (!self.ignoreMinFrameCountForGetLimit && self.frames.count < self.minFrameCountForGet) {
        [self.condition unlock];
        return nil;
    }
    SGFFFrame * frame = nil;
    NSMutableArray * temp = [NSMutableArray array];
    for (SGFFFrame * obj in self.frames) {
        if (obj.position + obj.duration < position) {
            [temp addObject:obj];
            self.duration -= obj.duration;
            self.size -= obj.size;
            self.packetSize -= obj.packetSize;
        } else {
            break;
        }
    }
    if (temp.count > 0) {
        frame = temp.lastObject;
        [self.frames removeObjectsInArray:temp];
        [temp removeObject:frame];
        if (temp.count > 0) {
            * discardFrames = temp;
        }
    } else {
        frame = self.frames.firstObject;
        [self.frames removeObject:frame];
        self.duration -= frame.duration;
        self.size -= frame.size;
        self.packetSize -= frame.packetSize;
    }
    if (self.duration < 0 || self.count <= 0) {
        self.duration = 0;
    }
    if (self.size <= 0 || self.count <= 0) {
        self.size = 0;
    }
    if (self.packetSize <= 0 || self.count <= 0) {
        self.packetSize = 0;
    }
    [self.condition unlock];
    return frame;
}

- (NSTimeInterval)getFirstFramePositionAsync
{
    [self.condition lock];
    if (self.destoryToken || self.frames.count <= 0) {
        [self.condition unlock];
        return -1;
    }
    if (!self.ignoreMinFrameCountForGetLimit && self.frames.count < self.minFrameCountForGet) {
        [self.condition unlock];
        return -1;
    }
    NSTimeInterval time = self.frames.firstObject.position;
    [self.condition unlock];
    return time;
}

- (NSMutableArray <__kindof SGFFFrame *> *)discardFrameBeforPosition:(NSTimeInterval)position
{
    [self.condition lock];
    if (self.destoryToken || self.frames.count <= 0) {
        [self.condition unlock];
        return nil;
    }
    if (!self.ignoreMinFrameCountForGetLimit && self.frames.count < self.minFrameCountForGet) {
        [self.condition unlock];
        return nil;
    }
    NSMutableArray * temp = [NSMutableArray array];
    for (SGFFFrame * obj in self.frames) {
        if (obj.position + obj.duration < position) {
            [temp addObject:obj];
            self.duration -= obj.duration;
            self.size -= obj.size;
            self.packetSize -= obj.packetSize;
        } else {
            break;
        }
    }
    if (temp.count > 0) {
        [self.frames removeObjectsInArray:temp];
    }
    if (self.duration < 0 || self.count <= 0) {
        self.duration = 0;
    }
    if (self.size <= 0 || self.count <= 0) {
        self.size = 0;
    }
    if (self.packetSize <= 0 || self.count <= 0) {
        self.packetSize = 0;
    }
    [self.condition unlock];
    if (temp.count > 0) {
        return temp;
    } else {
        return nil;
    }
}

- (void)flush
{
    [self.condition lock];
    [self.frames removeAllObjects];
    self.duration = 0;
    self.size = 0;
    self.packetSize = 0;
    self.ignoreMinFrameCountForGetLimit = NO;
    [self.condition unlock];
}

- (void)destroy
{
    [self flush];
    [self.condition lock];
    self.destoryToken = YES;
    [self.condition broadcast];
    [self.condition unlock];
}

- (NSUInteger)count
{
    return self.frames.count;
}

+ (NSTimeInterval)maxVideoDuration
{
    return 1.0;
}

+ (NSTimeInterval)sleepTimeIntervalForFull
{
    return [self maxVideoDuration] / 2.0f;
}

+ (NSTimeInterval)sleepTimeIntervalForFullAndPaused
{
    return [self maxVideoDuration] / 1.1f;
}

@end
