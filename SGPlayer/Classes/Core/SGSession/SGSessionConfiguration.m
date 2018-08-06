//
//  SGSessionConfiguration.m
//  SGPlayer
//
//  Created by Single on 2018/1/31.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGSessionConfiguration.h"

@implementation SGSessionConfiguration

- (instancetype)init
{
    if (self = [super init])
    {
        self.hardwareDecodeEnableH264 = YES;
        self.hardwareDecodeEnableH265 = YES;
    }
    return self;
}

@end
