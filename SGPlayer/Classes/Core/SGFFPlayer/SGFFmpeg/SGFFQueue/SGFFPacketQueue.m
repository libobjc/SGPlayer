//
//  SGFFPacketQueue.m
//  SGPlayer
//
//  Created by Single on 2018/1/18.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFPacketQueue.h"

@interface SGFFPacketQueue ()

@property (nonatomic, assign) long long duration;
@property (nonatomic, assign) long long size;

@property (nonatomic, strong) NSCondition * condition;
@property (nonatomic, strong) NSMutableArray <NSValue *> * packets;

@property (nonatomic, assign) BOOL didDestoryed;

@end

@implementation SGFFPacketQueue

- (instancetype)init
{
    if (self = [super init])
    {
        self.packets = [NSMutableArray array];
        self.condition = [[NSCondition alloc] init];
    }
    return self;
}

- (void)putPacket:(AVPacket)packet
{
    if (self.didDestoryed) {
        return;
    }
    [self.condition lock];
    NSValue * value = [NSValue value:&packet withObjCType:@encode(AVPacket)];
    [self.packets addObject:value];
    self.size += packet.size;
    if (packet.duration > 0) {
        self.duration += packet.duration;
    }
    [self.condition signal];
    [self.condition unlock];
}

- (AVPacket)getPacketSync
{
    [self.condition lock];
    AVPacket packet = [self getEmptyPacket];
    while (self.packets.count <= 0)
    {
        if (self.didDestoryed)
        {
            [self.condition unlock];
            return packet;
        }
        [self.condition wait];
    }
    packet = [self getPacket];
    [self.condition unlock];
    return packet;
}

- (AVPacket)getPacketAsync
{
    [self.condition lock];
    AVPacket packet = [self getEmptyPacket];
    if (self.packets.count <= 0 || self.didDestoryed)
    {
        [self.condition unlock];
        return packet;
    }
    packet = [self getPacket];
    [self.condition unlock];
    return packet;
}

- (AVPacket)getPacket
{
    AVPacket packet = [self getEmptyPacket];
    if (!self.packets.firstObject)
    {
        return packet;
    }
    [self.packets.firstObject getValue:&packet];
    [self.packets removeObjectAtIndex:0];
    self.size -= packet.size;
    if (self.size < 0 || self.count <= 0) {
        self.size = 0;
    }
    self.duration -= packet.duration;
    if (self.duration < 0 || self.count <= 0) {
        self.duration = 0;
    }
    return packet;
}

- (AVPacket)getEmptyPacket
{
    AVPacket packet;
    av_init_packet(&packet);
    packet.data = NULL;
    packet.size = 0;
    return packet;
}

- (NSInteger)count
{
    return self.packets.count;
}

- (void)flush
{
    [self.condition lock];
    for (NSValue * value in self.packets)
    {
        AVPacket packet;
        [value getValue:&packet];
        av_packet_unref(&packet);
    }
    [self.packets removeAllObjects];
    self.size = 0;
    self.duration = 0;
    [self.condition broadcast];
    [self.condition unlock];
}

- (void)destroy
{
    self.didDestoryed = YES;
    [self flush];
}

@end
