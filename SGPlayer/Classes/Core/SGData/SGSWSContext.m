//
//  SGSWSContext.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/28.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGSWSContext.h"
#import "SGFFDefinesMapping.h"
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
                                        SGDMPixelFormatSG2FF(self.srcFormat),
                                        self.width,
                                        self.height,
                                        SGDMPixelFormatSG2FF(self.dstFormat),
                                        self.flags,
                                        NULL, NULL, NULL);
    return self.context ? YES : NO;
}

- (int)scaleWithSrcData:(const uint8_t *const [])srcData
            srcLinesize:(const int [])srcLinesize
                dstData:(uint8_t *const [])dstData
            dstLinesize:(const int [])dstLinesize
{
    int result = sws_scale(self.context,
                           srcData,
                           srcLinesize,
                           0,
                           self.height,
                           dstData,
                           dstLinesize);
    return result;
}

@end
