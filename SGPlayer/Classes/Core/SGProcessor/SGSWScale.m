//
//  SGSWScale.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/28.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGSWScale.h"
#import "swscale.h"

@interface SGSWScale ()

{
    struct SwsContext *_context;
}

@end

@implementation SGSWScale

- (instancetype)init
{
    if (self = [super init]) {
        self->_flags = SWS_FAST_BILINEAR;
    }
    return self;
}

- (void)dealloc
{
    if (self->_context) {
        sws_freeContext(self->_context);
        self->_context = nil;
    }
}

- (BOOL)open
{
    if (self->_width == 0 ||
        self->_height == 0) {
        return NO;
    }
    self->_context = sws_getCachedContext(self->_context,
                                          self->_width,
                                          self->_height,
                                          self->_i_format,
                                          self->_width,
                                          self->_height,
                                          self->_o_format,
                                          self->_flags,
                                          NULL, NULL, NULL);
    return self->_context ? YES : NO;
}

- (int)convert:(const uint8_t *const [])i_data i_linesize:(const int [])i_linesize o_data:(uint8_t *const [])o_data o_linesize:(const int [])o_linesize
{
    return sws_scale(self->_context,
                     i_data,
                     i_linesize,
                     0,
                     self->_height,
                     o_data,
                     o_linesize);;
}

@end
