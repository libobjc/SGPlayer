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

@property (nonatomic, readonly) BOOL needsAlignment;
@property (nonatomic, strong, readonly) SGCodecContext *codecContext;
@property (nonatomic, strong, readonly) SGCodecDescription *codecDescription;

@end

@implementation SGVideoDecoder

- (void)setup
{
    self->_needsAlignment = NO;
    self->_codecContext = [[SGCodecContext alloc] initWithTimebase:self->_codecDescription.timebase
                                                          codecpar:self->_codecDescription.codecpar
                                                        frameClass:[SGVideoFrame class]];
    [self->_codecContext open];
}

- (void)destroy
{
    self->_needsAlignment = NO;
    [self->_codecContext close];
    self->_codecContext = nil;
}

#pragma mark - Control

- (void)flush
{
    self->_needsAlignment = NO;
    [self->_codecContext flush];
}

- (NSArray<__kindof SGFrame *> *)decode:(SGPacket *)packet
{
    NSMutableArray *ret = [NSMutableArray array];
    SGCodecDescription *cd = packet.codecDescription;
    NSAssert(cd, @"Invalid Codec Description.");
    if (![cd isEqualCodecparToDescription:self->_codecDescription]) {
        NSArray<SGFrame *> *objs = [self processPacket:nil];
        for (SGFrame *obj in objs) {
            [ret addObject:obj];
        }
        self->_codecDescription = [cd copy];
        [self destroy];
        [self setup];
    }
    [cd fillToDescription:self->_codecDescription];
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
    SGCodecDescription *cd = self->_codecDescription;
    NSArray *objs = [self->_codecContext decode:packet];
    objs = [self processFrames:objs done:!packet];
    objs = [self clipFrames:objs timeRange:cd.timeRange];
    return objs;
}

- (NSArray<__kindof SGFrame *> *)processFrames:(NSArray<__kindof SGFrame *> *)frames done:(BOOL)done
{
    NSMutableArray *ret = [NSMutableArray array];
    for (SGAudioFrame *obj in frames) {
        [obj setCodecDescription:[self->_codecDescription copy]];
        [obj fill];
        [ret addObject:obj];
    }
    return ret;
}

- (NSArray<__kindof SGFrame *> *)clipFrames:(NSArray<__kindof SGFrame *> *)frames timeRange:(CMTimeRange)timeRange
{
    NSMutableArray *ret = [NSMutableArray array];
    for (SGFrame *obj in frames) {
        if (CMTimeCompare(obj.timeStamp, timeRange.start) < 0) {
            [obj unlock];
            continue;
        }
        if (CMTimeCompare(obj.timeStamp, CMTimeRangeGetEnd(timeRange)) >= 0) {
            [obj unlock];
            continue;
        }
        if (!self->_needsAlignment) {
            self->_needsAlignment = YES;
            CMTime start = timeRange.start;
            CMTime duration = CMTimeSubtract(CMTimeAdd(obj.timeStamp, obj.duration), start);
            if (CMTimeCompare(obj.timeStamp, start) > 0) {
                SGCodecDescription *cd = [[SGCodecDescription alloc] init];
                cd.track = obj.track;
                [obj setCodecDescription:cd];
                [obj fillWithDuration:duration timeStamp:start decodeTimeStamp:start];
            }
        }
        CMTime start = obj.timeStamp;
        CMTime duration = CMTimeSubtract(CMTimeRangeGetEnd(timeRange), obj.timeStamp);
        if (CMTimeCompare(obj.duration, duration) > 0) {
            SGCodecDescription *cd = [[SGCodecDescription alloc] init];
            cd.track = obj.track;
            [obj setCodecDescription:cd];
            [obj fillWithDuration:duration timeStamp:start decodeTimeStamp:start];
        }
        [ret addObject:obj];
    }
    return ret;
}

@end
