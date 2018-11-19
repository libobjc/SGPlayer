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
    if (self = [super init]) {
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

- (BOOL)isEqualToCapacity:(SGCapacity *)capacity
{
    if (self.count != capacity.count) {
        return NO;
    }
    if (self.size != capacity.size) {
        return NO;
    }
    if (CMTimeCompare(self.duration, capacity.duration) != 0) {
        return NO;
    }
    return YES;
}

- (BOOL)isEnough
{
    if (self.count < 30) {
        return NO;
    }
    if (CMTimeCompare(self.duration, CMTimeMake(1, 1)) < 0) {
        return NO;
    }
    return YES;
}

- (BOOL)isEmpty
{
    if (self.count != 0) {
        return NO;
    }
    if (self.size != 0) {
        return NO;
    }
    if (CMTimeCompare(self.duration, kCMTimeZero) != 0) {
        return NO;
    }
    return YES;
}

- (void)add:(SGCapacity *)capacity
{
    self.duration = CMTimeAdd(self.duration, capacity.duration);
    self.size += capacity.size;
    self.count += capacity.count;
}

- (SGCapacity *)minimum:(SGCapacity *)capacity
{
    if (!capacity) {
        return self;
    }
    if (CMTimeCompare(self.duration, capacity.duration) < 0) {
        return self;
    } else if (CMTimeCompare(self.duration, capacity.duration) > 0) {
        return capacity;
    }
    if (self.count < capacity.count) {
        return self;
    } else if (self.count > capacity.count) {
        return capacity;
    }
    if (self.size < capacity.size) {
        return self;
    } else if (self.size > capacity.size) {
        return capacity;
    }
    return self;
}

@end
