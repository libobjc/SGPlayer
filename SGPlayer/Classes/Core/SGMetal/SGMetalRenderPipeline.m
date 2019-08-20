//
//  SGMetalRenderPipeline.m
//  MetalTest
//
//  Created by Single on 2019/6/26.
//  Copyright © 2019 Single. All rights reserved.
//

#import "SGMetalRenderPipeline.h"

@implementation SGMetalRenderPipeline

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if (self = [super init]) {
        self.device = device;
    }
    return self;
}

@end

