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
    [self->_codecContext close];
    self->_codecContext = nil;
}

#pragma mark - Control

- (void)flush
{
    [self->_codecContext flush];
}

- (NSArray<__kindof SGFrame *> *)decode:(SGPacket *)packet
{
    NSMutableArray *ret = [NSMutableArray array];
    SGCodecDescription *cd = packet.codecDescription;
    if (cd && ![cd isEqualToDescription:self->_codecDescription]) {
        NSArray<SGFrame *> *objs = [self processPacket:nil];
        for (SGFrame *obj in objs) {
            [ret addObject:obj];
        }
        cd = [cd copy];
        self->_codecDescription = cd;
        self->_timeRange = cd.finalTimeRange;
        [self destroy];
        [self setup];
    }
    NSArray<SGFrame *> *objs = [self processPacket:packet];
    for (SGFrame *obj in objs) {
        [ret addObject:obj];
    }
    return ret;
}

- (NSArray<__kindof SGFrame *> *)finish
{
    return [self processPacket:nil];
}

#pragma mark - Process

- (NSArray<__kindof SGFrame *> *)processPacket:(SGPacket *)packet
{
    if (!self->_codecContext || !self->_codecDescription) {
        return nil;
    }
    NSArray *objs = [self->_codecContext decode:packet];
    return [self processFrames:objs];
}

- (NSArray<__kindof SGFrame *> *)processFrames:(NSArray<SGFrame *> *)frames
{
    NSMutableArray *ret = [NSMutableArray array];
    for (SGFrame *obj in frames) {
        obj.codecDescription = self->_codecDescription;
        [obj fill];
        if (CMTimeCompare(obj.timeStamp, self->_timeRange.start) < 0) {
            [obj unlock];
            continue;
        }
        if (CMTimeCompare(obj.timeStamp, CMTimeRangeGetEnd(self->_timeRange)) >= 0) {
            [obj unlock];
            continue;
        }
        [ret addObject:obj];
    }
    return ret;
}

@end
