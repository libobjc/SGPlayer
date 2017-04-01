//
//  SGFFPacketQueue.m
//  SGPlayer
//
//  Created by Single on 18/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFPacketQueue.h"

@interface SGFFPacketQueue ()

@property (nonatomic, assign) int size;
@property (atomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSTimeInterval timebase;

@property (nonatomic, strong) NSCondition * condition;
@property (nonatomic, strong) NSMutableArray <NSValue *> * packets;

@property (nonatomic, assign) BOOL destoryToken;

@end

@implementation SGFFPacketQueue

+ (instancetype)packetQueueWithTimebase:(NSTimeInterval)timebase
{
    return [[self alloc] initWithTimebase:timebase];
}

- (instancetype)initWithTimebase:(NSTimeInterval)timebase
{
    if (self = [super init]) {
        self.timebase = timebase;
        self.packets = [NSMutableArray array];
        self.condition = [[NSCondition alloc] init];
    }
    return self;
}

- (void)putPacket:(AVPacket)packet duration:(NSTimeInterval)duration
{
    [self.condition lock];
    if (self.destoryToken) {
        [self.condition unlock];
        return;
    }
    NSValue * value = [NSValue value:&packet withObjCType:@encode(AVPacket)];
    [self.packets addObject:value];
    self.size += packet.size;
    if (packet.duration > 0) {
        self.duration += packet.duration * self.timebase;
    } else if (duration > 0) {
        self.duration += duration;
    }
    [self.condition signal];
    [self.condition unlock];
}

- (AVPacket)getPacketSync
{
    [self.condition lock];
    AVPacket packet;
    packet.stream_index = -2;
    while (!self.packets.firstObject) {
        if (self.destoryToken) {
            [self.condition unlock];
            return packet;
        }
        [self.condition wait];
    }
    [self.packets.firstObject getValue:&packet];
    [self.packets removeObjectAtIndex:0];
    self.size -= packet.size;
    if (self.size < 0 || self.count <= 0) {
        self.size = 0;
    }
    self.duration -= packet.duration * self.timebase;
    if (self.duration < 0 || self.count <= 0) {
        self.duration = 0;
    }
    [self.condition unlock];
    return packet;
}

- (AVPacket)getPacketAsync
{
    [self.condition lock];
    AVPacket packet;
    packet.stream_index = -2;
    if (self.packets.count <= 0 || self.destoryToken) {
        [self.condition unlock];
        return packet;
    }
    [self.packets.firstObject getValue:&packet];
    [self.packets removeObjectAtIndex:0];
    self.size -= packet.size;
    if (self.size < 0 || self.count <= 0) {
        self.size = 0;
    }
    self.duration -= packet.duration * self.timebase;
    if (self.duration < 0 || self.count <= 0) {
        self.duration = 0;
    }
    [self.condition unlock];
    return packet;
}

- (void)flush
{
    [self.condition lock];
    for (NSValue * value in self.packets) {
        AVPacket packet;
        [value getValue:&packet];
        av_packet_unref(&packet);
    }
    [self.packets removeAllObjects];
    self.size = 0;
    self.duration = 0;
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
    return self.packets.count;
}

@end
