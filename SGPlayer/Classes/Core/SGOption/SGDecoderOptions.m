//
//  SGDecoderOptions.m
//  SGPlayer
//
//  Created by Single on 2019/6/14.
//  Copyright © 2019 single. All rights reserved.
//

#import "SGDecoderOptions.h"
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
    obj->_preferredPixelFormat = self->_preferredPixelFormat;
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.options = nil;
        self.threadsAuto = YES;
        self.refcountedFrames = YES;
        self.hardwareDecodeH264 = YES;
        self.hardwareDecodeH265 = YES;
        self.preferredPixelFormat = SGPixelFormatFF2AV(AV_PIX_FMT_NV12);
    }
    return self;
}

@end
