//
//  SGAudioFormatter.m
//  SGPlayer iOS
//
//  Created by Single on 2018/10/30.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioFormatter.h"
#import "SGFrame+Internal.h"
#import "SGSWResample.h"

@interface SGAudioFormatter ()

@property (nonatomic, readonly) SGTrack *track;
@property (nonatomic, readonly) CMTime nextTimeStamp;
@property (nonatomic, strong, readonly) SGSWResample *context;

@end

@implementation SGAudioFormatter

- (instancetype)init
{
    if (self = [super init]) {
        [self flush];
    }
    return self;
}

- (SGAudioFrame *)format:(SGAudioFrame *)frame
{
    if (![frame isKindOfClass:[SGAudioFrame class]]) {
        [frame unlock];
        return nil;
    }
    if (![self->_context.inputDescriptor isEqualToDescriptor:frame.descriptor] ||
        ![self->_context.outputDescriptor isEqualToDescriptor:self->_descriptor]) {
        [self flush];
        SGSWResample *context = [[SGSWResample alloc] init];
        context.inputDescriptor = frame.descriptor;
        context.outputDescriptor = self->_descriptor;
        if ([context open]) {
            self->_context = context;
        }
    }
    if (!self->_context) {
        [frame unlock];
        return nil;
    }
    self->_track = frame.track;
    int nb_samples = [self->_context write:frame.data nb_samples:frame.numberOfSamples];
    SGAudioFrame *ret = [self frameWithStart:frame.timeStamp nb_samples:nb_samples];
    self->_nextTimeStamp = CMTimeAdd(ret.timeStamp, ret.duration);
    [frame unlock];
    return ret;
}

- (SGAudioFrame *)finish
{
    if (!self->_track || !self->_context || CMTIME_IS_INVALID(self->_nextTimeStamp)) {
        return nil;
    }
    int nb_samples = [self->_context write:NULL nb_samples:0];
    if (nb_samples <= 0) {
        return nil;
    }
    SGAudioFrame *frame = [self frameWithStart:self->_nextTimeStamp nb_samples:nb_samples];
    return frame;
}

- (SGAudioFrame *)frameWithStart:(CMTime)start nb_samples:(int)nb_samples
{
    SGAudioFrame *frame = [SGAudioFrame frameWithDescriptor:self->_descriptor numberOfSamples:nb_samples];
    uint8_t nb_planes = self->_descriptor.numberOfPlanes;
    uint8_t *data[SGFramePlaneCount] = {NULL};
    for (int i = 0; i < nb_planes; i++) {
        data[i] = frame.core->data[i];
    }
    [self->_context read:data nb_samples:nb_samples];
    SGCodecDescriptor *cd = [[SGCodecDescriptor alloc] init];
    cd.track = self->_track;
    [frame setCodecDescriptor:cd];
    [frame fillWithTimeStamp:start decodeTimeStamp:start duration:CMTimeMake(nb_samples, self->_descriptor.sampleRate)];
    return frame;
}

- (void)flush
{
    self->_track = nil;
    self->_context = nil;
    self->_nextTimeStamp = kCMTimeInvalid;
}

@end
