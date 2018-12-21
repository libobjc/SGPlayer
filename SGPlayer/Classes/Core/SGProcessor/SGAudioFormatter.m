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

{
    SGSWResample *_context;
}

@end

@implementation SGAudioFormatter

- (instancetype)initWithAudioDescription:(SGAudioDescription *)audioDescription
{
    if (self = [super init]) {
        self->_audioDescription = [audioDescription copy];
    }
    return self;
}

- (SGAudioFrame *)format:(SGAudioFrame *)frame
{
    if (![frame isKindOfClass:[SGAudioFrame class]]) {
        [frame unlock];
        return nil;
    }
    if (![self->_context.inputDescription isEqualToDescription:frame.audioDescription] ||
        ![self->_context.outputDescription isEqualToDescription:self->_audioDescription]) {
        self->_context = nil;
        SGSWResample *context = [[SGSWResample alloc] init];
        context.inputDescription = frame.audioDescription;
        context.outputDescription = self->_audioDescription;
        if ([context open]) {
            self->_context = context;
        }
    }
    if (!self->_context) {
        [frame unlock];
        return nil;
    }
    int nb_planes = self->_audioDescription.numberOfPlanes;
    int nb_samples = [self->_context write:frame.data nb_samples:frame.numberOfSamples];
    CMTime start = frame.timeStamp;
    CMTime duration = CMTimeMake(nb_samples, self->_audioDescription.sampleRate);
    SGAudioFrame *ret = [SGAudioFrame audioFrameWithDescription:self->_audioDescription numberOfSamples:nb_samples];
    uint8_t *data[SGFramePlaneCount] = {NULL};
    for (int i = 0; i < nb_planes; i++) {
        data[i] = ret.core->data[i];
    }
    [self->_context read:data nb_samples:nb_samples];
    SGCodecDescription *cd = [[SGCodecDescription alloc] init];
    cd.track = frame.track;
    [ret setCodecDescription:cd];
    [ret fillWithDuration:duration timeStamp:start decodeTimeStamp:start];
    [frame unlock];
    return ret;
}

- (void)flush
{
    self->_context = nil;
}

@end
