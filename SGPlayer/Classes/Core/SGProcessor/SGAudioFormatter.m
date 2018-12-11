//
//  SGAudioFormatter.m
//  SGPlayer iOS
//
//  Created by Single on 2018/10/30.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioFormatter.h"
#import "SGAudioFrame+Internal.h"
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
    int numberOfPlanes = self->_audioDescription.numberOfPlanes;
    int numberOfSamples = [self->_context convert:frame.data nb_samples:frame.numberOfSamples];
    SGAudioFrame *ret = [SGAudioFrame audioFrameWithDescription:self->_audioDescription numberOfSamples:numberOfSamples];
    ret.core->pts = frame.core->pts;
    ret.core->pkt_dts = frame.core->pkt_dts;
    ret.core->pkt_size = frame.core->pkt_size;
    ret.core->pkt_duration = frame.core->pkt_duration;
    ret.core->best_effort_timestamp = frame.core->best_effort_timestamp;
    for (int i = 0; i < numberOfPlanes; i++) {
        [self->_context copy:ret.core->data[i] linesize:ret.core->linesize[i] plane:i];
    }
    [ret setCodecDescription:frame.codecDescription];
    [ret fill];
    [frame unlock];
    return ret;
}

- (void)flush
{
    self->_context = nil;
}

@end
