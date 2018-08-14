//
//  SGVideoVirtualFrame.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVideoVirtualFrame.h"

@implementation SGVideoVirtualFrame

- (void)fillWithPacket:(SGPacket *)packet
{
    self.timebase = packet.timebase;
    self.offset = packet.offset;
    self.scale = packet.scale;
    self.originalTimeStamp = packet.originalTimeStamp;
    self.timeStamp = CMTimeAdd(self.offset, SGTimeMultiplyByTime(self.originalTimeStamp, self.scale));
    self.duration = packet.duration;
    self.dts = packet.dts;
    self.size = packet.corePacket->size;
    self.packetPosition = packet.corePacket->pos;
    self.packetDuration = packet.corePacket->duration;
    self.packetSize = packet.corePacket->size;
}

@end
