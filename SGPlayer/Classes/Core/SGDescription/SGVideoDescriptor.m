//
//  SGVideoDescriptor.m
//  SGPlayer
//
//  Created by Single on 2018/12/11.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVideoDescriptor.h"
#import "SGMapping.h"
#import "SGFFmpeg.h"

@implementation SGVideoDescriptor

- (id)copyWithZone:(NSZone *)zone
{
    SGVideoDescriptor *obj = [[SGVideoDescriptor alloc] init];
    obj->_format = self->_format;
    obj->_cv_format = self->_cv_format;
    obj->_width = self->_width;
    obj->_height = self->_height;
    obj->_colorspace = self->_colorspace;
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_format = AV_PIX_FMT_NONE;
        self->_cv_format = SGPixelFormatFF2AV(self->_format);
        self->_width = 0;
        self->_height = 0;
        self->_colorspace = AVCOL_SPC_RGB;
    }
    return self;
}

- (instancetype)initWithFrame:(AVFrame *)frame
{
    if (self = [super init]) {
        self->_format = frame->format;
        self->_cv_format = SGPixelFormatFF2AV(self->_format);
        self->_width = frame->width;
        self->_height = frame->height;
        self->_colorspace = frame->colorspace;
    }
    return self;
}

- (BOOL)isEqualToDescriptor:(SGVideoDescriptor *)descriptor
{
    if (!descriptor) {
        return NO;
    }
    return
    self->_format == descriptor->_format &&
    self->_cv_format == descriptor->_cv_format &&
    self->_width == descriptor->_width &&
    self->_height == descriptor->_height &&
    self->_colorspace == descriptor->_colorspace;
}

@end
