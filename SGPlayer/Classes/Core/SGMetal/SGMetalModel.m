//
//  SGMetalModel.m
//  MetalTest
//
//  Created by Single on 2019/6/24.
//  Copyright © 2019 Single. All rights reserved.
//

#import "SGMetalModel.h"

@implementation SGMetalModel

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if (self = [super init]) {
        self.device = device;
    }
    return self;
}

@end
