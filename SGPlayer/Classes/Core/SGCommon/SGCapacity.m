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

- (id)copyWithZone:(NSZone *)zone
{
    SGCapacity * obj = [[SGCapacity alloc] init];
    obj.duration = self.duration;
    obj.size = self.size;
    obj.count = self.count;
    return obj;
}

- (void)add:(SGCapacity *)capacity
{
    self.duration = CMTimeAdd(self.duration, capacity.duration);
    self.size += capacity.size;
    self.count += capacity.count;
}

@end
