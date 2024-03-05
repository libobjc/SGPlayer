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
#import "SGSWScale.h"

@interface SGVideoDecoder ()

{
    struct {
        BOOL needsKeyFrame;
        BOOL needsAlignment;
        BOOL sessionFinished;
        NSUInteger outputCount;
    } _flags;
}

@property (nonatomic, strong, readonly) SGSWScale *scaler;
@property (nonatomic, strong, readonly) SGCodecContext *codecContext;
@property (nonatomic, strong, readonly) SGVideoFrame *lastDecodeFrame;
@property (nonatomic, strong, readonly) SGVideoFrame *lastOutputFrame;
@property (nonatomic, strong, readonly) SGCodecDescriptor *codecDescriptor;

@end

@implementation SGVideoDecoder

@synthesize options = _options;

- (instancetype)init
{
    if (self = [super init]) {
        self->_outputFromKeyFrame = YES;
    }
    return self;
}

- (void)dealloc
{
    [self destroy];
}

- (void)setup
{
    self->_flags.needsAlignment = YES;
    self->_codecContext = [[SGCodecContext alloc] initWithTimebase:self->_codecDescriptor.timebase
                                                          codecpar:self->_codecDescriptor.codecpar
                                                    frameGenerator:^__kindof SGFrame *{
        return [SGVideoFrame frame];
    }];
    self->_codecContext.options = self->_options;
    [self->_codecContext open];
}

- (void)destroy
{
    self->_flags.outputCount = 0;
    self->_flags.needsKeyFrame = YES;
    self->_flags.needsAlignment = YES;
    self->_flags.sessionFinished = NO;
    [self->_codecContext close];
    self->_codecContext = nil;
    [self->_lastDecodeFrame unlock];
    self->_lastDecodeFrame = nil;
    [self->_lastOutputFrame unlock];
    self->_lastOutputFrame = nil;
}

#pragma mark - Control

- (void)flush
{
    self->_flags.outputCount = 0;
    self->_flags.needsKeyFrame = YES;
    self->_flags.needsAlignment = YES;
    self->_flags.sessionFinished = NO;
    [self->_codecContext flush];
    [self->_lastDecodeFrame unlock];
    self->_lastDecodeFrame = nil;
    [self->_lastOutputFrame unlock];
    self->_lastOutputFrame = nil;
}

- (NSArray<__kindof SGFrame *> *)decode:(SGPacket *)packet
{
    NSMutableArray *frames = [NSMutableArray array];
    SGCodecDescriptor *cd = packet.codecDescriptor;
    NSAssert(cd, @"Invalid Codec Descriptor.");
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
        
    } else {
        NSArray<SGFrame *> *objs = [self processPacket:packet];
        for (SGFrame *obj in objs) {
            [frames addObject:obj];
        }
    }
    NSArray *ret = [self resampleFrames:frames];
    if (ret.lastObject) {
        [self->_lastOutputFrame unlock];
        self->_lastOutputFrame = ret.lastObject;
        [self->_lastOutputFrame lock];
    }
    self->_flags.outputCount += ret.count;
    return ret;
}

- (NSArray<__kindof SGFrame *> *)finish
{
    if (self->_flags.sessionFinished) {
        return nil;
    }
    NSArray<SGFrame *> *frames = [self processPacket:nil];
    if (frames.count == 0 &&
        self->_lastDecodeFrame &&
        self->_flags.outputCount == 0) {
        CMTimeRange timeRange = self->_codecDescriptor.timeRange;
        if (CMTIME_IS_NUMERIC(timeRange.start) &&
            CMTIME_IS_NUMERIC(timeRange.duration)) {
            SGCodecDescriptor *cd = [[SGCodecDescriptor alloc] init];
            cd.track = self->_lastDecodeFrame.track;
            cd.metadata = self->_lastDecodeFrame.codecDescriptor.metadata;
            [self->_lastDecodeFrame setCodecDescriptor:cd];
            [self->_lastDecodeFrame fillWithTimeStamp:timeRange.start decodeTimeStamp:timeRange.start duration:timeRange.duration];
        }
        frames = @[self->_lastDecodeFrame];
        [self->_lastDecodeFrame lock];
    } else if (frames.count == 0 &&
               self->_lastOutputFrame) {
        CMTimeRange timeRange = self->_codecDescriptor.timeRange;
        if (CMTIME_IS_NUMERIC(timeRange.start) &&
            CMTIME_IS_NUMERIC(timeRange.duration)) {
            CMTime end = CMTimeRangeGetEnd(timeRange);
            CMTime lastEnd = CMTimeAdd(self->_lastOutputFrame.timeStamp, self->_lastOutputFrame.duration);
            CMTime duration = CMTimeSubtract(end, lastEnd);
            if (CMTimeCompare(duration, kCMTimeZero) > 0) {
                SGVideoFrame *obj = [SGVideoFrame frame];
                [obj fillWithFrame:self->_lastOutputFrame];
                SGCodecDescriptor *cd = [[SGCodecDescriptor alloc] init];
                cd.track = obj.track;
                cd.metadata = obj.codecDescriptor.metadata;
                [obj setCodecDescriptor:cd];
                [obj fillWithTimeStamp:lastEnd decodeTimeStamp:lastEnd duration:duration];
                frames = @[obj];
            }
        }
    } else if (frames.count > 0) {
        CMTimeRange timeRange = self->_codecDescriptor.timeRange;
        if (CMTIME_IS_NUMERIC(timeRange.start) &&
            CMTIME_IS_NUMERIC(timeRange.duration)) {
            SGFrame *obj = frames.lastObject;
            CMTime end = CMTimeRangeGetEnd(timeRange);
            CMTime lastEnd = CMTimeAdd(obj.timeStamp, obj.duration);
            CMTime duration = CMTimeSubtract(end, lastEnd);
            if (CMTimeCompare(duration, kCMTimeZero) > 0) {
                SGCodecDescriptor *cd = [[SGCodecDescriptor alloc] init];
                cd.track = obj.track;
                cd.metadata = obj.codecDescriptor.metadata;
                [obj setCodecDescriptor:cd];
                [obj fillWithTimeStamp:obj.timeStamp decodeTimeStamp:obj.timeStamp duration:CMTimeSubtract(end, obj.timeStamp)];
            }
        }
    }
    [self->_lastDecodeFrame unlock];
    self->_lastDecodeFrame = nil;
    [self->_lastOutputFrame unlock];
    self->_lastOutputFrame = nil;
    NSArray *ret = [self resampleFrames:frames];
    self->_flags.outputCount += ret.count;
    return ret;
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
    frames = [self clipKeyFrames:frames];
    frames = [self clipFrames:frames timeRange:cd.timeRange];
    frames = [self formatFrames:frames];
    return frames;
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

- (NSArray<__kindof SGFrame *> *)clipKeyFrames:(NSArray<__kindof SGFrame *> *)frames
{
    if (self->_outputFromKeyFrame == NO ||
        self->_flags.needsKeyFrame == NO) {
        return frames;
    }
    NSMutableArray *ret = [NSMutableArray array];
    for (SGFrame *obj in frames) {
        if (self->_flags.needsKeyFrame == NO) {
            [ret addObject:obj];
        } else if (obj.core->key_frame) {
            [ret addObject:obj];
            self->_flags.needsKeyFrame = NO;
        } else {
            [obj unlock];
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
    [self->_lastDecodeFrame unlock];
    self->_lastDecodeFrame = frames.lastObject;
    [self->_lastDecodeFrame lock];
    NSMutableArray *ret = [NSMutableArray array];
    for (SGFrame *obj in frames) {
        if (CMTimeCompare(CMTimeAdd(obj.timeStamp, obj.duration), timeRange.start) <= 0) {
            [obj unlock];
            continue;
        }
        if (SGCMTimeIsValid(timeRange.duration, NO) &&
            CMTimeCompare(obj.timeStamp, CMTimeRangeGetEnd(timeRange)) >= 0) {
            [obj unlock];
            continue;
        }
        if (self->_flags.needsAlignment) {
            self->_flags.needsAlignment = NO;
            CMTime start = timeRange.start;
            CMTime duration = CMTimeSubtract(CMTimeAdd(obj.timeStamp, obj.duration), start);
            if (CMTimeCompare(obj.timeStamp, start) != 0) {
                SGCodecDescriptor *cd = [[SGCodecDescriptor alloc] init];
                cd.track = obj.track;
                cd.metadata = obj.codecDescriptor.metadata;
                [obj setCodecDescriptor:cd];
                [obj fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
            }
        }
        if (SGCMTimeIsValid(timeRange.duration, NO)) {
            CMTime start = obj.timeStamp;
            CMTime duration = CMTimeSubtract(CMTimeRangeGetEnd(timeRange), start);
            if (CMTimeCompare(obj.duration, duration) > 0) {
                self->_flags.sessionFinished = YES;
                SGCodecDescriptor *cd = [[SGCodecDescriptor alloc] init];
                cd.track = obj.track;
                cd.metadata = obj.codecDescriptor.metadata;
                [obj setCodecDescriptor:cd];
                [obj fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
            } else if (CMTimeCompare(obj.duration, duration) == 0) {
                self->_flags.sessionFinished = YES;
            }
        }
        [ret addObject:obj];
    }
    return ret;
}

- (NSArray<__kindof SGFrame *> *)formatFrames:(NSArray<__kindof SGFrame *> *)frames
{
    NSArray<NSNumber *> *formats = self->_options.supportedPixelFormats;
    if (formats.count <= 0) {
        return frames;
    }
    NSMutableArray *ret = [NSMutableArray array];
    for (SGVideoFrame *obj in frames) {
        BOOL supported = NO;
        for (NSNumber *format in formats) {
            if (obj.pixelBuffer ||
                obj.descriptor.format == format.intValue) {
                supported = YES;
                break;
            }
        }
        if (supported) {
            [ret addObject:obj];
            continue;
        }
        int format = formats.firstObject.intValue;
        if (![self->_scaler.inputDescriptor isEqualToDescriptor:obj.descriptor]) {
            SGSWScale *scaler = [[SGSWScale alloc] init];
            scaler.inputDescriptor = obj.descriptor;
            scaler.outputDescriptor = obj.descriptor.copy;
            scaler.outputDescriptor.format = format;
            if ([scaler open]) {
                self->_scaler = scaler;
            }
        }
        if (!self->_scaler) {
            [obj unlock];
            continue;
        }
        SGVideoFrame *newObj = [SGVideoFrame frameWithDescriptor:self->_scaler.outputDescriptor];
        int result = [self->_scaler convert:(void *)obj.data
                              inputLinesize:obj.linesize
                                 outputData:newObj.core->data
                             outputLinesize:newObj.core->linesize];
        if (result < 0) {
            [newObj unlock];
            [obj unlock];
            continue;
        }
        [newObj setCodecDescriptor:obj.codecDescriptor];
        [newObj fillWithTimeStamp:obj.timeStamp decodeTimeStamp:obj.decodeTimeStamp duration:obj.duration];
        [ret addObject:newObj];
        [obj unlock];
    }
    return ret;
}

- (NSArray<__kindof SGFrame *> *)resampleFrames:(NSArray<__kindof SGFrame *> *)frames
{
    if (!self->_options.resetFrameRate &&
        CMTIME_IS_NUMERIC(self->_options.preferredFrameRate)) {
        return frames;
    }
    CMTime frameRate = self->_options.preferredFrameRate;
    NSMutableArray *ret = [NSMutableArray array];
    for (SGVideoFrame *obj in frames) {
        SGVideoFrame *frame = obj;
        while (CMTimeCompare(frame.duration, frameRate) > 0) {
            CMTime start = CMTimeAdd(frame.timeStamp, frameRate);
            CMTime duration = CMTimeSubtract(frame.duration, frameRate);
            SGCodecDescriptor *cd = [[SGCodecDescriptor alloc] init];
            cd.track = frame.track;
            cd.metadata = frame.codecDescriptor.metadata;
            [frame setCodecDescriptor:cd];
            [frame fillWithTimeStamp:frame.timeStamp decodeTimeStamp:frame.timeStamp duration:frameRate];
            SGVideoFrame *newFrame = [SGVideoFrame frame];
            [newFrame fillWithFrame:frame];
            [newFrame fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
            [ret addObject:frame];
            frame = newFrame;
        }
        [ret addObject:frame];
    }
    return ret;
}

@end
