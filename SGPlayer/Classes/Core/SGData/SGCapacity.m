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
        self->_duration = kCMTimeZero;
        self->_size = 0;
        self->_count = 0;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    SGCapacity *obj = [[SGCapacity alloc] init];
    obj->_duration = self->_duration;
    obj->_size = self->_size;
    obj->_count = self->_count;
    return obj;
}

- (BOOL)isEqualToCapacity:(SGCapacity *)capacity
{
    if (!capacity) {
        return NO;
    }
    if (self->_count != capacity->_count) {
        return NO;
    }
    if (self->_size != capacity->_size) {
        return NO;
    }
    if (CMTimeCompare(self->_duration, capacity->_duration) != 0) {
        return NO;
    }
    return YES;
}

- (BOOL)isEnough
{
    if (self->_count < 30) {
        return NO;
    }
    if (CMTimeCompare(self->_duration, CMTimeMake(1, 1)) < 0) {
        return NO;
    }
    return YES;
}

- (BOOL)isEmpty
{
    if (self->_count != 0) {
        return NO;
    }
    if (self->_size != 0) {
        return NO;
    }
    if (CMTimeCompare(self->_duration, kCMTimeZero) != 0) {
        return NO;
    }
    return YES;
}

- (void)add:(SGCapacity *)capacity
{
    if (!capacity) {
        return;
    }
    self->_duration = CMTimeAdd(self->_duration, capacity->_duration);
    self->_size += capacity->_size;
    self->_count += capacity->_count;
}

- (SGCapacity *)minimum:(SGCapacity *)capacity
{
    if (!capacity) {
        return self;
    }
    if (CMTimeCompare(self->_duration, capacity->_duration) < 0) {
        return self;
    } else if (CMTimeCompare(self->_duration, capacity->_duration) > 0) {
        return capacity;
    }
    if (self->_count < capacity->_count) {
        return self;
    } else if (self->_count > capacity->_count) {
        return capacity;
    }
    if (self->_size < capacity->_size) {
        return self;
    } else if (self->_size > capacity->_size) {
        return capacity;
    }
    return self;
}

- (SGCapacity *)maximum:(SGCapacity *)capacity
{
    if (!capacity) {
        return self;
    }
    SGCapacity *obj = [self minimum:capacity];
    if (obj == self) {
        return capacity;
    }
    return self;
}

@end
