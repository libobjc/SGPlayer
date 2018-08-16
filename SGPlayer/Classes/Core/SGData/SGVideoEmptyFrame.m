//
//  SGVideoEmptyFrame.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVideoEmptyFrame.h"

@implementation SGVideoEmptyFrame

- (void)fillWithPacket:(SGPacket *)packet
{
    self.timebase = packet.timebase;
    self.offset = packet.offset;
    self.scale = packet.scale;
    self.originalTimeStamp = packet.originalTimeStamp;
    self.originalDuration = packet.originalDuration;
    self.timeStamp = CMTimeAdd(self.offset, SGCMTimeMultiply(self.originalTimeStamp, self.scale));
    self.duration = packet.duration;
    self.decodeTimeStamp = packet.decodeTimeStamp;
    self.size = packet.corePacket->size;
    self.packetPosition = packet.corePacket->pos;
    self.packetDuration = packet.corePacket->duration;
    self.packetSize = packet.corePacket->size;
}

@end
