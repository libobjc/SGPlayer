//
//  SGSWSContext.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/28.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGSWSContext.h"
#import "swscale.h"

@interface SGSWSContext ()

@property (nonatomic, assign) struct SwsContext * context;

@end

@implementation SGSWSContext

- (instancetype)init
{
    if (self = [super init])
    {
        self.flags = SWS_FAST_BILINEAR;
    }
    return self;
}

- (void)dealloc
{
    if (self.context)
    {
        sws_freeContext(self.context);
        self.context = nil;
    }
}

- (BOOL)open
{
    if (self.width == 0 ||
        self.height == 0)
    {
        return NO;
    }
    self.context = sws_getCachedContext(self.context,
                                        self.width,
                                        self.height,
                                        self.src_format,
                                        self.width,
                                        self.height,
                                        self.dst_format,
                                        self.flags,
                                        NULL, NULL, NULL);
    return self.context ? YES : NO;
}

- (int)scaleWithSrcData:(const uint8_t *const [])src_data
            srcLinesize:(const int [])src_linesize
                dstData:(uint8_t *const [])dst_data
            dstLinesize:(const int [])dst_linesize
{
    int result = sws_scale(self.context,
                           src_data,
                           src_linesize,
                           0,
                           self.height,
                           dst_data,
                           dst_linesize);
    return result;
}

@end
