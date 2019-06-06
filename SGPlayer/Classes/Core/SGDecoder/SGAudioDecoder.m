//
//  SGAudioDecoder.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioDecoder.h"
#import "SGFrame+Internal.h"
#import "SGPacket+Internal.h"
#import "SGDescription+Internal.h"
#import "SGCodecContext.h"
#import "SGAudioFrame.h"
#import "SGSonic.h"

@interface SGAudioDecoder ()

{
    struct {
        BOOL needsAlignment;
        BOOL needsResetSonic;
        int64_t nextTimeStamp;
    } _flags;
}

@property (nonatomic, strong, readonly) SGSonic *sonic;
@property (nonatomic, strong, readonly) SGCodecContext *codecContext;
@property (nonatomic, strong, readonly) SGCodecDescription *codecDescription;
@property (nonatomic, strong, readonly) SGAudioDescription *audioDescription;

@end

@implementation SGAudioDecoder

- (void)setup
{
    self->_flags.nextTimeStamp = 0;
    self->_flags.needsAlignment = YES;
    self->_flags.needsResetSonic = YES;
    self->_codecContext = [[SGCodecContext alloc] initWithTimebase:self->_codecDescription.timebase
                                                          codecpar:self->_codecDescription.codecpar
                                                        frameClass:[SGAudioFrame class]
                                                    frameReuseName:[SGAudioFrame commonReuseName]];
    [self->_codecContext open];
}

- (void)destroy
{
    self->_flags.nextTimeStamp = 0;
    self->_flags.needsAlignment = YES;
    self->_flags.needsResetSonic = YES;
    [self->_codecContext close];
    self->_codecContext = nil;
    self->_audioDescription = nil;
}

#pragma mark - Control

- (void)flush
{
    self->_flags.nextTimeStamp = 0;
    self->_flags.needsAlignment = YES;
    self->_flags.needsResetSonic = YES;
    [self->_codecContext flush];
}

- (NSArray<__kindof SGFrame *> *)decode:(SGPacket *)packet
{
    NSMutableArray *ret = [NSMutableArray array];
    SGCodecDescription *cd = packet.codecDescription;
    NSAssert(cd, @"Invalid codec description.");
    if (![cd isEqualCodecContextToDescription:self->_codecDescription]) {
        NSArray<SGFrame *> *objs = [self finish];
        for (SGFrame *obj in objs) {
            [ret addObject:obj];
        }
        self->_codecDescription = [cd copy];
        [self destroy];
        [self setup];
    }
    [cd fillToDescription:self->_codecDescription];
    switch (packet.codecDescription.type) {
        case SGCodecType_Decode: {
            NSArray<SGFrame *> *objs = [self processPacket:packet];
            for (SGFrame *obj in objs) {
                [ret addObject:obj];
            }
        }
            break;
        case SGCodecType_Padding: {
            SGAudioDescription *ad = self->_audioDescription;
            if (ad == nil) {
                ad = [[SGAudioDescription alloc] init];
            }
            CMTime start = packet.timeStamp;
            CMTime duration = packet.duration;
            int nb_samples = CMTimeGetSeconds(CMTimeMultiply(duration, ad.sampleRate));
            if (nb_samples > 0) {
                duration = CMTimeMake(nb_samples, ad.sampleRate);
                SGAudioFrame *obj = [SGAudioFrame audioFrameWithDescription:ad numberOfSamples:nb_samples];
                SGCodecDescription *cd = [[SGCodecDescription alloc] init];
                cd.track = packet.track;
                [obj setCodecDescription:cd];
                [obj fillWithDuration:duration timeStamp:start decodeTimeStamp:start];
                [ret addObject:obj];
            }
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
        AVFrame *frame = obj.core;
        if (self->_audioDescription == nil) {
            self->_audioDescription = [[SGAudioDescription alloc] initWithFrame:frame];
        }
        self->_flags.nextTimeStamp = frame->best_effort_timestamp + frame->pkt_duration;
        SGAudioDescription *ad = self->_audioDescription;
        SGCodecDescription *cd = self->_codecDescription;
        if (CMTimeCompare(cd.scale, CMTimeMake(1, 1)) != 0) {
            if (self->_flags.needsResetSonic) {
                self->_flags.needsResetSonic = NO;
                self->_sonic = [[SGSonic alloc] initWithAudioDescription:ad];
                self->_sonic.speed = 1.0 / CMTimeGetSeconds(cd.scale);
                [self->_sonic open];
            }
            int64_t input = av_rescale_q(self->_sonic.samplesInput, av_make_q(1, ad.sampleRate), cd.timebase);
            int64_t pts = frame->best_effort_timestamp - input;
            if ([self->_sonic write:frame->data nb_samples:frame->nb_samples]) {
                [ret addObject:[self readSonicFrame:pts]];
            }
            [obj unlock];
        } else {
            [obj setCodecDescription:[cd copy]];
            [obj fill];
            [ret addObject:obj];
        }
    }
    if (done) {
        SGAudioDescription *ad = self->_audioDescription;
        SGCodecDescription *cd = self->_codecDescription;
        int64_t input = av_rescale_q(self->_sonic.samplesInput, av_make_q(1, ad.sampleRate), cd.timebase);
        int64_t pts = self->_flags.nextTimeStamp - input;
        if ([self->_sonic flush]) {
            [ret addObject:[self readSonicFrame:pts]];
        }
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
    for (SGAudioFrame *obj in frames) {
        if (CMTimeCompare(obj.timeStamp, timeRange.start) < 0) {
            [obj unlock];
            continue;
        }
        if (CMTimeCompare(obj.timeStamp, CMTimeRangeGetEnd(timeRange)) >= 0) {
            [obj unlock];
            continue;
        }
        SGAudioDescription *ad = obj.audioDescription;
        if (self->_flags.needsAlignment) {
            self->_flags.needsAlignment = NO;
            CMTime start = timeRange.start;
            CMTime duration = CMTimeSubtract(obj.timeStamp, start);
            int nb_samples = CMTimeGetSeconds(CMTimeMultiply(duration, ad.sampleRate));
            if (nb_samples > 0) {
                duration = CMTimeMake(nb_samples, ad.sampleRate);
                SGAudioFrame *obj1 = [SGAudioFrame audioFrameWithDescription:ad numberOfSamples:nb_samples];
                SGCodecDescription *cd = [[SGCodecDescription alloc] init];
                cd.track = obj.track;
                [obj1 setCodecDescription:cd];
                [obj1 fillWithDuration:duration timeStamp:start decodeTimeStamp:start];
                [ret addObject:obj1];
            }
        }
        CMTime start = obj.timeStamp;
        CMTime duration = CMTimeSubtract(CMTimeRangeGetEnd(timeRange), obj.timeStamp);
        int nb_samples = CMTimeGetSeconds(CMTimeMultiply(duration, ad.sampleRate));
        if (nb_samples < obj.numberOfSamples) {
            duration = CMTimeMake(nb_samples, ad.sampleRate);
            SGAudioFrame *obj1 = [SGAudioFrame audioFrameWithDescription:ad numberOfSamples:nb_samples];
            for (int i = 0; i < ad.numberOfPlanes; i++) {
                memcpy(obj1.core->data[i], obj.core->data[i], obj1.core->linesize[i]);
            }
            SGCodecDescription *cd = [[SGCodecDescription alloc] init];
            cd.track = obj.track;
            [obj1 setCodecDescription:cd];
            [obj1 fillWithDuration:duration timeStamp:start decodeTimeStamp:start];
            [ret addObject:obj1];
            [obj unlock];
            continue;
        }
        [ret addObject:obj];
    }
    return ret;
}

- (SGAudioFrame *)readSonicFrame:(int64_t)pts
{
    int nb_samples = [self->_sonic samplesAvailable];
    SGAudioDescription *ad = self->_audioDescription;
    SGCodecDescription *cd = self->_codecDescription;
    CMTime start = CMTimeMultiply(CMTimeMake(pts, cd.timebase.den), cd.timebase.num);
    CMTime duration = CMTimeMake(nb_samples, ad.sampleRate);
    for (SGTimeLayout *obj in cd.timeLayouts) {
        start = [obj convertTimeStamp:start];
    }
    SGAudioFrame *obj = [SGAudioFrame audioFrameWithDescription:ad numberOfSamples:nb_samples];
    [self->_sonic read:obj.core->data nb_samples:nb_samples];
    SGCodecDescription *cd1 = [[SGCodecDescription alloc] init];
    cd1.track = cd.track;
    [obj setCodecDescription:cd1];
    [obj fillWithDuration:duration timeStamp:start decodeTimeStamp:start];
    return obj;
}

@end
