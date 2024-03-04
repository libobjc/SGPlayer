//
//  SGDecoderOptions.m
//  SGPlayer
//
//  Created by Single on 2019/6/14.
//  Copyright © 2019 single. All rights reserved.
//

#import "SGDecoderOptions.h"
#import "SGAudioRenderer.h"
#import "SGVideoRenderer.h"
#import "SGMapping.h"

@implementation SGDecoderOptions

- (id)copyWithZone:(NSZone *)zone
{
    SGDecoderOptions *obj = [[SGDecoderOptions alloc] init];
    obj->_options = self->_options.copy;
    obj->_threadsAuto = self->_threadsAuto;
    obj->_refcountedFrames = self->_refcountedFrames;
    obj->_hardwareDecodeH264 = self->_hardwareDecodeH264;
    obj->_hardwareDecodeH265 = self->_hardwareDecodeH265;
    obj->_preferredCVPixelFormat = self->_preferredCVPixelFormat;
    obj->_supportedPixelFormats = self->_supportedPixelFormats.copy;
    obj->_supportedAudioDescriptors = self->_supportedAudioDescriptors.copy;
    obj->_resetFrameRate = self->_resetFrameRate;
    obj->_preferredFrameRate = self->_preferredFrameRate;
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_options = nil;
        self->_threadsAuto = YES;
        self->_refcountedFrames = YES;
        self->_hardwareDecodeH264 = YES;
        self->_hardwareDecodeH265 = YES;
        self->_preferredCVPixelFormat = SGPixelFormatFF2AV(AV_PIX_FMT_NV12);
        self->_supportedPixelFormats = [SGVideoRenderer supportedPixelFormats];
        self->_supportedAudioDescriptors = @[[SGAudioRenderer supportedAudioDescriptor]];
        self->_resetFrameRate = NO;
        self->_preferredFrameRate = CMTimeMake(1, 25);
    }
    return self;
}

@end
