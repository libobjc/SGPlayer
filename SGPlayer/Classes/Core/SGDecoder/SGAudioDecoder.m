//
//  SGAudioDecoder.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioDecoder.h"
#import "SGPacket+Internal.h"
#import "SGFrame+Internal.h"
#import "SGCodecContext.h"
#import "SGAudioFrame.h"

@interface SGAudioDecoder ()

{
    BOOL _finished;
    CMTimeRange _timeRange;
    SGCodecContext *_codecContext;
    SGCodecDescription *_codecDescription;
}

@end

@implementation SGAudioDecoder

@synthesize index = _index;

- (void)setup
{
    SGCodecDescription *cd = self->_codecDescription;
    self->_codecContext = [[SGCodecContext alloc] initWithTimebase:cd.timebase codecpar:cd.codecpar frameClass:[SGAudioFrame class]];
    [self->_codecContext open];
}

- (void)destroy
{
    self->_finished = NO;
    [self->_codecContext close];
    self->_codecContext = nil;
}

- (void)flush
{
    self->_finished = NO;
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
    if (self->_finished) {
        return nil;
    }
    NSMutableArray *ret = [NSMutableArray array];
    NSArray<SGAudioFrame *> *frames = [self->_codecContext decode:packet];
    for (SGAudioFrame *obj in frames) {
        obj.codecDescription = self->_codecDescription;
        [obj fill];
        if (CMTimeCompare(obj.timeStamp, self->_timeRange.start) < 0) {
            [obj unlock];
            continue;
        }
        if (CMTimeCompare(obj.timeStamp, CMTimeRangeGetEnd(self->_timeRange)) >= 0) {
            self->_finished = YES;
            [obj unlock];
            continue;
        }
        [ret addObject:obj];
    }
    return [ret copy];
}

- (NSArray<SGFrame *> *)finish
{
    return nil;
}

@end
