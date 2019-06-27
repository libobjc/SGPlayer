//
//  SGVideoDescription.m
//  SGPlayer
//
//  Created by Single on 2018/12/11.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVideoDescription.h"
#import "SGMapping.h"
#import "SGFFmpeg.h"

@implementation SGVideoDescription

- (id)copyWithZone:(NSZone *)zone
{
    SGVideoDescription *obj = [[SGVideoDescription alloc] init];
    obj->_format = self->_format;
    obj->_cv_format = self->_cv_format;
    obj->_width = self->_width;
    obj->_height = self->_height;
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_format = AV_PIX_FMT_NONE;
        self->_cv_format = SGPixelFormatFF2AV(self->_format);
        self->_width = 0;
        self->_height = 0;
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
    }
    return self;
}

- (BOOL)isEqualToDescription:(SGVideoDescription *)description
{
    if (!description) {
        return NO;
    }
    return
    self->_format == description->_format &&
    self->_cv_format == description->_cv_format &&
    self->_width == description->_width &&
    self->_height == description->_height;
}

@end
