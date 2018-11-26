//
//  SGVideoDecoder.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVideoDecoder.h"
#import "SGPacket+Internal.h"
#import "SGFrame+Internal.h"
#import "SGCodecContext.h"
#import "SGVideoFrame.h"

@interface SGVideoDecoder ()

{
    BOOL _isEndOutput;
    CMTimeRange _timeRange;
    SGCodecContext *_codecContext;
    SGCodecDescription *_codecDescription;
}

@end

@implementation SGVideoDecoder

@synthesize index = _index;

- (void)setup
{
    SGCodecDescription *cd = self->_codecDescription;
    self->_codecContext = [[SGCodecContext alloc] initWithTimebase:cd.timebase codecpar:cd.codecpar frameClass:[SGVideoFrame class]];
    [self->_codecContext open];
}

- (void)destroy
{
    self->_isEndOutput = NO;
    [self->_codecContext close];
    self->_codecContext = nil;
}

- (void)flush
{
    self->_isEndOutput = NO;
    [self->_codecContext flush];
}

- (NSArray<__kindof SGFrame *> *)decode:(SGPacket *)packet
{
    SGCodecDescription *cd = packet.codecDescription;
    if (cd && ![cd isEqualToDescription:self->_codecDescription]) {
        cd = [cd copy];
        self->_codecDescription = cd;
        self->_timeRange = cd.finalTimeRange;
        [self destroy];
        [self setup];
    }
    if (self->_isEndOutput) {
        return nil;
    }
    NSMutableArray *ret = [NSMutableArray array];
    NSArray<SGVideoFrame *> *frames = [self->_codecContext decode:packet];
    for (SGVideoFrame *obj in frames) {
        obj.codecDescription = self->_codecDescription;
        [obj fill];
        if (CMTimeCompare(obj.timeStamp, self->_timeRange.start) < 0) {
            [obj unlock];
            continue;
        }
        if (CMTimeCompare(obj.timeStamp, CMTimeRangeGetEnd(self->_timeRange)) >= 0) {
            self->_isEndOutput = YES;
            [obj unlock];
            continue;
        }
        [ret addObject:obj];
    }
    return ret;
}

@end
