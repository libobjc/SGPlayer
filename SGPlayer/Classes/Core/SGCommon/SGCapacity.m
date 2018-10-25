//
//  SGCapacity.m
//  SGPlayer iOS
//
//  Created by Single on 2018/10/25.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGCapacity.h"

@implementation SGCapacity

- (instancetype)init
{
    if (self = [super init])
    {
        self.duration = kCMTimeZero;
        self.size = 0;
        self.count = 0;
    }
    return self;
}

@end
