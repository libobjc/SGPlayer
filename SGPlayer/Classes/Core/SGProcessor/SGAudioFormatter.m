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

@property (nonatomic, strong, readonly) SGSWResample *context;

@end

@implementation SGAudioFormatter

- (SGAudioFrame *)format:(SGAudioFrame *)frame
{
    if (![frame isKindOfClass:[SGAudioFrame class]]) {
        [frame unlock];
        return nil;
    }
    if (![self->_context.inputDescriptor isEqualToDescriptor:frame.descriptor] ||
        ![self->_context.outputDescriptor isEqualToDescriptor:self->_descriptor]) {
        self->_context = nil;
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
    int nb_planes = self->_descriptor.numberOfPlanes;
    int nb_samples = [self->_context write:frame.data nb_samples:frame.numberOfSamples];
    CMTime start = frame.timeStamp;
    CMTime duration = CMTimeMake(nb_samples, self->_descriptor.sampleRate);
    SGAudioFrame *ret = [SGAudioFrame audioFrameWithDescriptor:self->_descriptor numberOfSamples:nb_samples];
    uint8_t *data[SGFramePlaneCount] = {NULL};
    for (int i = 0; i < nb_planes; i++) {
        data[i] = ret.core->data[i];
    }
    [self->_context read:data nb_samples:nb_samples];
    SGCodecDescriptor *cd = [[SGCodecDescriptor alloc] init];
    cd.track = frame.track;
    [ret setCodecDescriptor:cd];
    [ret fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
    [frame unlock];
    return ret;
}

- (void)flush
{
    self->_context = nil;
}

@end
