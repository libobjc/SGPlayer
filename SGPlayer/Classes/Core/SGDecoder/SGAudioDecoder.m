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
#import "SGAudioFormatter.h"
#import "SGCodecContext.h"
#import "SGAudioFrame.h"
#import "SGSonic.h"

@interface SGAudioDecoder ()

{
    struct {
        BOOL needsAlignment;
        BOOL needsResetSonic;
        BOOL sessionFinished;
        int64_t nextTimeStamp;
        CMTime lastEndTimeStamp;
    } _flags;
}

@property (nonatomic, strong, readonly) SGSonic *sonic;
@property (nonatomic, strong, readonly) SGAudioFormatter *formatter;
@property (nonatomic, strong, readonly) SGCodecContext *codecContext;
@property (nonatomic, strong, readonly) SGCodecDescriptor *codecDescriptor;
@property (nonatomic, strong, readonly) SGAudioDescriptor *audioDescriptor;

@end

@implementation SGAudioDecoder

@synthesize options = _options;

- (void)dealloc
{
    [self destroy];
}

- (void)setup
{
    self->_flags.nextTimeStamp = 0;
    self->_flags.needsAlignment = YES;
    self->_flags.needsResetSonic = YES;
    self->_codecContext = [[SGCodecContext alloc] initWithTimebase:self->_codecDescriptor.timebase
                                                          codecpar:self->_codecDescriptor.codecpar
                                                    frameGenerator:^__kindof SGFrame *{
        return [SGAudioFrame frame];
    }];
    self->_codecContext.options = self->_options;
    [self->_codecContext open];
}

- (void)destroy
{
    self->_flags.nextTimeStamp = 0;
    self->_flags.needsAlignment = YES;
    self->_flags.needsResetSonic = YES;
    self->_flags.sessionFinished = NO;
    self->_flags.lastEndTimeStamp = kCMTimeInvalid;
    [self->_codecContext close];
    self->_codecContext = nil;
    self->_audioDescriptor = nil;
    self->_formatter = nil;
}

#pragma mark - Control

- (void)flush
{
    self->_flags.nextTimeStamp = 0;
    self->_flags.needsAlignment = YES;
    self->_flags.needsResetSonic = YES;
    self->_flags.sessionFinished = NO;
    self->_flags.lastEndTimeStamp = kCMTimeInvalid;
    [self->_codecContext flush];
    [self->_formatter flush];
}

- (NSArray<__kindof SGFrame *> *)decode:(SGPacket *)packet
{
    NSMutableArray *frames = [NSMutableArray array];
    SGCodecDescriptor *cd = packet.codecDescriptor;
    NSAssert(cd, @"Invalid codec descriptor.");
    BOOL isEqual = [cd isEqualToDescriptor:self->_codecDescriptor];
    BOOL isEqualCodec = [cd isEqualCodecContextToDescriptor:self->_codecDescriptor];
    if (!isEqual) {
        NSArray<SGFrame *> *objs = [self finish];
        for (SGFrame *obj in objs) {
            [frames addObject:obj];
        }
        self->_codecDescriptor = [cd copy];
        if (isEqualCodec) {
            [self flush];
        } else {
            [self destroy];
            [self setup];
        }
    }
    if (self->_flags.sessionFinished) {
        return nil;
    }
    [cd fillToDescriptor:self->_codecDescriptor];
    if (packet.flags & SGDataFlagPadding) {
        SGAudioDescriptor *ad = self->_audioDescriptor;
        if (ad == nil) {
            ad = [[SGAudioDescriptor alloc] init];
        }
        CMTime start = packet.timeStamp;
        CMTime duration = packet.duration;
        int nb_samples = (int)CMTimeConvertScale(duration, ad.sampleRate, kCMTimeRoundingMethod_RoundTowardZero).value;
        if (nb_samples > 0) {
            duration = CMTimeMake(nb_samples, ad.sampleRate);
            SGAudioFrame *obj = [SGAudioFrame frameWithDescriptor:ad numberOfSamples:nb_samples];
            SGCodecDescriptor *cd = [[SGCodecDescriptor alloc] init];
            cd.track = packet.track;
            cd.metadata = packet.metadata;
            [obj setCodecDescriptor:cd];
            [obj fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
            [frames addObject:obj];
        }
    } else {
        NSArray<SGFrame *> *objs = [self processPacket:packet];
        for (SGFrame *obj in objs) {
            [frames addObject:obj];
        }
    }
    if (frames.count > 0) {
        SGFrame *obj = frames.lastObject;
        self->_flags.lastEndTimeStamp = CMTimeAdd(obj.timeStamp, obj.duration);
    }
    return frames;
}

- (NSArray<__kindof SGFrame *> *)finish
{
    if (self->_flags.sessionFinished) {
        return nil;
    }
    NSArray<SGFrame *> *frames = [self processPacket:nil];
    if (frames.count > 0) {
        self->_flags.lastEndTimeStamp = CMTimeAdd(frames.lastObject.timeStamp, frames.lastObject.duration);
    }
    CMTime lastEnd = self->_flags.lastEndTimeStamp;
    CMTimeRange timeRange = self->_codecDescriptor.timeRange;
    if (CMTIME_IS_NUMERIC(lastEnd) &&
        CMTIME_IS_NUMERIC(timeRange.start) &&
        CMTIME_IS_NUMERIC(timeRange.duration)) {
        CMTime end = CMTimeRangeGetEnd(timeRange);
        CMTime duration = CMTimeSubtract(end, lastEnd);
        SGAudioDescriptor *ad = self->_audioDescriptor;
        int nb_samples = (int)CMTimeConvertScale(duration, ad.sampleRate, kCMTimeRoundingMethod_RoundTowardZero).value;
        if (nb_samples > 0) {
            duration = CMTimeMake(nb_samples, ad.sampleRate);
            SGAudioFrame *obj = [SGAudioFrame frameWithDescriptor:ad numberOfSamples:nb_samples];
            SGCodecDescriptor *cd = [[SGCodecDescriptor alloc] init];
            cd.track = self->_codecDescriptor.track;
            cd.metadata = self->_codecDescriptor.metadata;
            [obj setCodecDescriptor:cd];
            [obj fillWithTimeStamp:lastEnd decodeTimeStamp:lastEnd duration:duration];
            NSMutableArray<SGFrame *> *newFrames = [NSMutableArray arrayWithArray:frames];
            [newFrames addObject:obj];
            frames = [newFrames copy];
        }
    }
    return frames;
}

#pragma mark - Process

- (NSArray<__kindof SGFrame *> *)processPacket:(SGPacket *)packet
{
    if (!self->_codecContext || !self->_codecDescriptor) {
        return nil;
    }
    SGCodecDescriptor *cd = self->_codecDescriptor;
    NSArray *frames = [self->_codecContext decode:packet];
    frames = [self processFrames:frames done:!packet];
    frames = [self clipFrames:frames timeRange:cd.timeRange];
    frames = [self formatFrames:frames];
    return frames;
}

- (NSArray<__kindof SGFrame *> *)processFrames:(NSArray<__kindof SGFrame *> *)frames done:(BOOL)done
{
    NSMutableArray<__kindof SGFrame *> *ret = [NSMutableArray array];
    for (SGAudioFrame *obj in frames) {
        AVFrame *frame = obj.core;
        if (self->_audioDescriptor == nil) {
            self->_audioDescriptor = [[SGAudioDescriptor alloc] initWithFrame:frame];
        }
        self->_flags.nextTimeStamp = frame->best_effort_timestamp + frame->duration;
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
    if (frames.count <= 0) {
        return nil;
    }
    if (!SGCMTimeIsValid(timeRange.start, NO)) {
        return frames;
    }
    NSMutableArray *ret = [NSMutableArray array];
    for (SGAudioFrame *obj in frames) {
        if (CMTimeCompare(obj.timeStamp, timeRange.start) < 0) {
            [obj unlock];
            continue;
        }
        if (SGCMTimeIsValid(timeRange.duration, NO) &&
            CMTimeCompare(obj.timeStamp, CMTimeRangeGetEnd(timeRange)) >= 0) {
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
                SGAudioFrame *obj1 = [SGAudioFrame frameWithDescriptor:ad numberOfSamples:nb_samples];
                SGCodecDescriptor *cd = [[SGCodecDescriptor alloc] init];
                cd.track = obj.track;
                cd.metadata = obj.metadata;
                [obj1 setCodecDescriptor:cd];
                [obj1 fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
                [ret addObject:obj1];
            }
        }
        if (SGCMTimeIsValid(timeRange.duration, NO)) {
            CMTime start = obj.timeStamp;
            CMTime duration = CMTimeSubtract(CMTimeRangeGetEnd(timeRange), start);
            int nb_samples = (int)CMTimeConvertScale(duration, ad.sampleRate, kCMTimeRoundingMethod_RoundTowardZero).value;
            if (nb_samples < obj.numberOfSamples) {
                self->_flags.sessionFinished = YES;
                duration = CMTimeMake(nb_samples, ad.sampleRate);
                SGAudioFrame *obj1 = [SGAudioFrame frameWithDescriptor:ad numberOfSamples:nb_samples];
                for (int i = 0; i < ad.numberOfPlanes; i++) {
                    memcpy(obj1.core->data[i], obj.core->data[i], obj1.core->linesize[i]);
                }
                SGCodecDescriptor *cd = [[SGCodecDescriptor alloc] init];
                cd.track = obj.track;
                cd.metadata = obj.metadata;
                [obj1 setCodecDescriptor:cd];
                [obj1 fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
                [ret addObject:obj1];
                [obj unlock];
                continue;
            } else if (nb_samples == obj.numberOfSamples) {
                self->_flags.sessionFinished = YES;
            }
        }
        [ret addObject:obj];
    }
    return ret;
}

- (NSArray<__kindof SGFrame *> *)formatFrames:(NSArray<__kindof SGFrame *> *)frames
{
    NSArray<SGAudioDescriptor *> *descriptors = self->_options.supportedAudioDescriptors;
    if (descriptors.count <= 0) {
        return frames;
    }
    NSMutableArray *ret = [NSMutableArray array];
    for (SGAudioFrame *obj in frames) {
        BOOL supported = NO;
        for (SGAudioDescriptor *descriptor in descriptors) {
            if ([obj.descriptor isEqualToDescriptor:descriptor]) {
                supported = YES;
                break;
            }
        }
        if (supported) {
            [ret addObject:obj];
            continue;
        }
        if (!self->_formatter) {
            self->_formatter = [[SGAudioFormatter alloc] init];
            self->_formatter.descriptor = descriptors.firstObject;
        }
        SGAudioFrame *newObj = [self->_formatter format:obj];
        if (newObj) {
            [ret addObject:newObj];
        }
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
    SGAudioFrame *obj = [SGAudioFrame frameWithDescriptor:ad numberOfSamples:nb_samples];
    [self->_sonic read:obj.core->data nb_samples:nb_samples];
    SGCodecDescriptor *cd1 = [[SGCodecDescriptor alloc] init];
    cd1.track = cd.track;
    cd1.metadata = cd.metadata;
    [obj setCodecDescriptor:cd1];
    [obj fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
    return obj;
}

@end
