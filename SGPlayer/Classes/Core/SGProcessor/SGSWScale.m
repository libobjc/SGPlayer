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

@property (nonatomic, assign) struct SwsContext * context;

@end

@implementation SGSWScale

- (instancetype)init
{
    if (self = [super init]) {
        self.flags = SWS_FAST_BILINEAR;
    }
    return self;
}

- (void)dealloc
{
    if (self.context) {
        sws_freeContext(self.context);
        self.context = nil;
    }
}

- (BOOL)open
{
    if (self.width == 0 ||
        self.height == 0) {
        return NO;
    }
    self.context = sws_getCachedContext(self.context,
                                        self.width,
                                        self.height,
                                        self.i_format,
                                        self.width,
                                        self.height,
                                        self.o_format,
                                        self.flags,
                                        NULL, NULL, NULL);
    return self.context ? YES : NO;
}

- (int)convert:(const uint8_t *const [])i_data i_linesize:(const int [])i_linesize o_data:(uint8_t *const [])o_data o_linesize:(const int [])o_linesize
{
    return sws_scale(self.context, i_data, i_linesize, 0, self.height, o_data, o_linesize);;
}

@end
