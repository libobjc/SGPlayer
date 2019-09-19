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
#import "SGDescriptor+Internal.h"
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
@property (nonatomic, strong, readonly) SGCodecDescriptor *codecDescriptor;
@property (nonatomic, strong, readonly) SGAudioDescriptor *audioDescriptor;

@end

@implementation SGAudioDecoder

@synthesize options = _options;

- (void)setup
{
    self->_flags.nextTimeStamp = 0;
    self->_flags.needsAlignment = YES;
    self->_flags.needsResetSonic = YES;
    self->_codecContext = [[SGCodecContext alloc] initWithTimebase:self->_codecDescriptor.timebase
                                                          codecpar:self->_codecDescriptor.codecpar
                                                        frameClass:[SGAudioFrame class]
                                                    frameReuseName:[SGAudioFrame commonReuseName]];
    self->_codecContext.options = self->_options;
    [self->_codecContext open];
}

- (void)destroy
{
    self->_flags.nextTimeStamp = 0;
    self->_flags.needsAlignment = YES;
    self->_flags.needsResetSonic = YES;
    [self->_codecContext close];
    self->_codecContext = nil;
    self->_audioDescriptor = nil;
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
    SGCodecDescriptor *cd = packet.codecDescriptor;
    NSAssert(cd, @"Invalid codec descriptor.");
    if (![cd isEqualCodecContextToDescriptor:self->_codecDescriptor]) {
        NSArray<SGFrame *> *objs = [self finish];
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
            SGAudioDescriptor *ad = self->_audioDescriptor;
            if (ad == nil) {
                ad = [[SGAudioDescriptor alloc] init];
            }
            CMTime start = packet.timeStamp;
            CMTime duration = packet.duration;
            int nb_samples = (int)CMTimeConvertScale(duration, ad.sampleRate, kCMTimeRoundingMethod_RoundTowardZero).value;
            if (nb_samples > 0) {
                duration = CMTimeMake(nb_samples, ad.sampleRate);
                SGAudioFrame *obj = [SGAudioFrame audioFrameWithDescriptor:ad numberOfSamples:nb_samples];
                SGCodecDescriptor *cd = [[SGCodecDescriptor alloc] init];
                cd.track = packet.track;
                [obj setCodecDescriptor:cd];
                [obj fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
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
        AVFrame *frame = obj.core;
        if (self->_audioDescriptor == nil) {
            self->_audioDescriptor = [[SGAudioDescriptor alloc] initWithFrame:frame];
        }
        self->_flags.nextTimeStamp = frame->best_effort_timestamp + frame->pkt_duration;
        SGAudioDescriptor *ad = self->_audioDescriptor;
        SGCodecDescriptor *cd = self->_codecDescriptor;
        if (CMTimeCompare(cd.scale, CMTimeMake(1, 1)) != 0) {
            if (self->_flags.needsResetSonic) {
                self->_flags.needsResetSonic = NO;
                self->_sonic = [[SGSonic alloc] initWithDescriptor:ad];
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
            [obj setCodecDescriptor:[cd copy]];
            [obj fill];
            [ret addObject:obj];
        }
    }
    if (done) {
        SGAudioDescriptor *ad = self->_audioDescriptor;
        SGCodecDescriptor *cd = self->_codecDescriptor;
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
        SGAudioDescriptor *ad = obj.descriptor;
        if (self->_flags.needsAlignment) {
            self->_flags.needsAlignment = NO;
            CMTime start = timeRange.start;
            CMTime duration = CMTimeSubtract(obj.timeStamp, start);
            int nb_samples = (int)CMTimeConvertScale(duration, ad.sampleRate, kCMTimeRoundingMethod_RoundTowardZero).value;
            if (nb_samples > 0) {
                duration = CMTimeMake(nb_samples, ad.sampleRate);
                SGAudioFrame *obj1 = [SGAudioFrame audioFrameWithDescriptor:ad numberOfSamples:nb_samples];
                SGCodecDescriptor *cd = [[SGCodecDescriptor alloc] init];
                cd.track = obj.track;
                [obj1 setCodecDescriptor:cd];
                [obj1 fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
                [ret addObject:obj1];
            }
        }
        CMTime start = obj.timeStamp;
        CMTime duration = CMTimeSubtract(CMTimeRangeGetEnd(timeRange), obj.timeStamp);
        int nb_samples = (int)CMTimeConvertScale(duration, ad.sampleRate, kCMTimeRoundingMethod_RoundTowardZero).value;
        if (nb_samples < obj.numberOfSamples) {
            duration = CMTimeMake(nb_samples, ad.sampleRate);
            SGAudioFrame *obj1 = [SGAudioFrame audioFrameWithDescriptor:ad numberOfSamples:nb_samples];
            for (int i = 0; i < ad.numberOfPlanes; i++) {
                memcpy(obj1.core->data[i], obj.core->data[i], obj1.core->linesize[i]);
            }
            SGCodecDescriptor *cd = [[SGCodecDescriptor alloc] init];
            cd.track = obj.track;
            [obj1 setCodecDescriptor:cd];
            [obj1 fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
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
    SGAudioDescriptor *ad = self->_audioDescriptor;
    SGCodecDescriptor *cd = self->_codecDescriptor;
    CMTime start = CMTimeMake(pts * cd.timebase.num, cd.timebase.den);
    CMTime duration = CMTimeMake(nb_samples, ad.sampleRate);
    start = [cd convertTimeStamp:start];
    SGAudioFrame *obj = [SGAudioFrame audioFrameWithDescriptor:ad numberOfSamples:nb_samples];
    [self->_sonic read:obj.core->data nb_samples:nb_samples];
    SGCodecDescriptor *cd1 = [[SGCodecDescriptor alloc] init];
    cd1.track = cd.track;
    [obj setCodecDescriptor:cd1];
    [obj fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
    return obj;
}

@end
