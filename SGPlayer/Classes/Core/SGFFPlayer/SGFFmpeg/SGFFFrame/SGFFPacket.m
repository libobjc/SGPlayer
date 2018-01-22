//
//  SGFFPacket.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFPacket.h"

@interface SGFFPacket ()

SGFFObjectPoolItemLockingInterface

@property (nonatomic, assign) AVPacket * corePacket;

@end

@implementation SGFFPacket

- (instancetype)init
{
    if (self = [super init])
    {
        self.corePacket = av_packet_alloc();
    }
    return self;
}

- (void)dealloc
{
    if (self.corePacket)
    {
        av_packet_free(&_corePacket);
        self.corePacket = nil;
    }
}

- (void)fill
{
    if (self.corePacket)
    {
        self.streamIndex = self.corePacket->stream_index;
        self.position = self.corePacket->pts;
        self.duration = self.corePacket->duration;
        self.size = self.corePacket->size;
    }
}

SGFFObjectPoolItemLockingImplementation

- (void)clear
{
    self.streamIndex = 0;
    self.position = 0;
    self.duration = 0;
    self.size = 0;
    if (self.corePacket)
    {
        av_packet_unref(self.corePacket);
    }
}

@end
