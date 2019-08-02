//
//  SGVideoDecoder.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVideoDecoder.h"
#import "SGFrame+Internal.h"
#import "SGPacket+Internal.h"
#import "SGCodecContext.h"
#import "SGVideoFrame.h"

@interface SGVideoDecoder ()

{
    struct {
        BOOL needsAlignment;
    } _flags;
}

@property (nonatomic, strong, readonly) SGCodecContext *codecContext;
@property (nonatomic, strong, readonly) SGCodecDescriptor *codecDescriptor;

@end

@implementation SGVideoDecoder

@synthesize options = _options;

- (void)setup
{
    self->_flags.needsAlignment = YES;
    self->_codecContext = [[SGCodecContext alloc] initWithTimebase:self->_codecDescriptor.timebase
                                                          codecpar:self->_codecDescriptor.codecpar
                                                        frameClass:[SGVideoFrame class]
                                                    frameReuseName:[SGVideoFrame commonReuseName]];
    self->_codecContext.options = self->_options;
    [self->_codecContext open];
}

- (void)destroy
{
    self->_flags.needsAlignment = YES;
    [self->_codecContext close];
    self->_codecContext = nil;
}

#pragma mark - Control

- (void)flush
{
    self->_flags.needsAlignment = YES;
    [self->_codecContext flush];
}

- (NSArray<__kindof SGFrame *> *)decode:(SGPacket *)packet
{
    NSMutableArray *ret = [NSMutableArray array];
    SGCodecDescriptor *cd = packet.codecDescriptor;
    NSAssert(cd, @"Invalid Codec Descriptor.");
    if (![cd isEqualCodecContextToDescriptor:self->_codecDescriptor]) {
        NSArray<SGFrame *> *objs = [self processPacket:nil];
        for (SGFrame *obj in objs) {
            [ret addObject:obj];
        }
        self->_codecDescriptor = [cd copy];
        [self destroy];
        [self setup];
    }
    [cd fillToDescriptor:self->_codecDescriptor];
    switch (packet.codecDescriptor.type) {
        case SGCodecTypeDecode: {
            NSArray<SGFrame *> *objs = [self processPacket:packet];
            for (SGFrame *obj in objs) {
                [ret addObject:obj];
            }
        }
            break;
        case SGCodecTypePadding: {
            
        }
            break;
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
    if (!self->_codecContext || !self->_codecDescriptor) {
        return nil;
    }
    SGCodecDescriptor *cd = self->_codecDescriptor;
    NSArray *objs = [self->_codecContext decode:packet];
    objs = [self processFrames:objs done:!packet];
    objs = [self clipFrames:objs timeRange:cd.timeRange];
    return objs;
}

- (NSArray<__kindof SGFrame *> *)processFrames:(NSArray<__kindof SGFrame *> *)frames done:(BOOL)done
{
    NSMutableArray *ret = [NSMutableArray array];
    for (SGAudioFrame *obj in frames) {
        [obj setCodecDescriptor:[self->_codecDescriptor copy]];
        [obj fill];
        [ret addObject:obj];
    }
    return ret;
}

- (NSArray<__kindof SGFrame *> *)clipFrames:(NSArray<__kindof SGFrame *> *)frames timeRange:(CMTimeRange)timeRange
{
    if (!SGCMTimeIsValid(timeRange.start, NO) ||
        !SGCMTimeIsValid(timeRange.duration, NO)) {
        return frames;
    }
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
        if (self->_flags.needsAlignment) {
            self->_flags.needsAlignment = NO;
            CMTime start = timeRange.start;
            CMTime duration = CMTimeSubtract(CMTimeAdd(obj.timeStamp, obj.duration), start);
            if (CMTimeCompare(obj.timeStamp, start) > 0) {
                SGCodecDescriptor *cd = [[SGCodecDescriptor alloc] init];
                cd.track = obj.track;
                cd.metadata = obj.codecDescriptor.metadata;
                [obj setCodecDescriptor:cd];
                [obj fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
            }
        }
        CMTime start = obj.timeStamp;
        CMTime duration = CMTimeSubtract(CMTimeRangeGetEnd(timeRange), obj.timeStamp);
        if (CMTimeCompare(obj.duration, duration) > 0) {
            SGCodecDescriptor *cd = [[SGCodecDescriptor alloc] init];
            cd.track = obj.track;
            cd.metadata = obj.codecDescriptor.metadata;
            [obj setCodecDescriptor:cd];
            [obj fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
        }
        [ret addObject:obj];
    }
    return ret;
}

@end
