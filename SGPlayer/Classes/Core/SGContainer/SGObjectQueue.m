//
//  SGObjectQueue.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGObjectQueue.h"

@interface SGObjectQueue ()

{
    struct {
        int size;
        BOOL destoryed;
        CMTime duration;
        uint64_t maxCount;
    } _flags;
}

@property (nonatomic, strong, readonly) NSCondition *wakeup;
@property (nonatomic, strong, readonly) id<SGData> puttingObject;
@property (nonatomic, strong, readonly) NSMutableArray<id<SGData>> *objects;

@end

@implementation SGObjectQueue

- (instancetype)init
{
    return [self initWithMaxCount:UINT64_MAX];
}

- (instancetype)initWithMaxCount:(uint64_t)maxCount
{
    if (self = [super init]) {
        self->_flags.maxCount = maxCount;
        self->_flags.duration = kCMTimeZero;
        self->_objects = [NSMutableArray array];
        self->_wakeup = [[NSCondition alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self destroy];
}

- (SGCapacity)capacity
{
    [self->_wakeup lock];
    if (self->_flags.destoryed) {
        [self->_wakeup unlock];
        return SGCapacityCreate();
    }
    SGCapacity ret = SGCapacityCreate();
    ret.size = self->_flags.size;
    ret.count = (int)self->_objects.count;
    ret.duration = self->_flags.duration;
    [self->_wakeup unlock];
    return ret;
}

- (BOOL)putObjectSync:(id<SGData>)object
{
    return [self putObjectSync:object before:nil after:nil];
}

- (BOOL)putObjectSync:(id<SGData>)object before:(SGBlock)before after:(SGBlock)after
{
    [self->_wakeup lock];
    if (self->_flags.destoryed) {
        [self->_wakeup unlock];
        return NO;
    }
    while (self->_objects.count >= self->_flags.maxCount) {
        self->_puttingObject = object;
        if (before) {
            before();
        }
        [self->_wakeup wait];
        if (after) {
            after();
        }
        if (!self->_puttingObject) {
            [self->_wakeup unlock];
            return NO;
        }
        self->_puttingObject = nil;
        if (self->_flags.destoryed) {
            [self->_wakeup unlock];
            return NO;
        }
    }
    [self putObject:object];
    [self->_wakeup signal];
    [self->_wakeup unlock];
    return YES;
}

- (BOOL)putObjectAsync:(id<SGData>)object
{
    [self->_wakeup lock];
    if (self->_flags.destoryed || (self->_objects.count >= self->_flags.maxCount)) {
        [self->_wakeup unlock];
        return NO;
    }
    [self putObject:object];
    [self->_wakeup signal];
    [self->_wakeup unlock];
    return YES;
}

- (void)putObject:(id<SGData>)object
{
    [object lock];
    [self->_objects addObject:object];
    if (self->_shouldSortObjects) {
        [self->_objects sortUsingComparator:^NSComparisonResult(id<SGData> obj1, id<SGData> obj2) {
            return CMTimeCompare(obj1.timeStamp, obj2.timeStamp) < 0 ? NSOrderedAscending : NSOrderedDescending;
        }];
    }
    NSAssert(CMTIME_IS_VALID(object.duration), @"Objcet duration is invalid.");
    self->_flags.duration = CMTimeAdd(self->_flags.duration, object.duration);
    self->_flags.size += object.size;
}

- (BOOL)getObjectSync:(id<SGData> *)object
{
    return [self getObjectSync:object before:nil after:nil];
}

- (BOOL)getObjectSync:(id<SGData> *)object before:(SGBlock)before after:(SGBlock)after
{
    [self->_wakeup lock];
    while (self->_objects.count <= 0) {
        if (before) {
            before();
        }
        [self->_wakeup wait];
        if (after) {
            after();
        }
        if (self->_flags.destoryed) {
            [self->_wakeup unlock];
            return NO;
        }
    }
    *object = [self getObject];
    [self->_wakeup signal];
    [self->_wakeup unlock];
    return YES;
}

- (BOOL)getObjectAsync:(id<SGData> *)object
{
    [self->_wakeup lock];
    if (self->_flags.destoryed || self->_objects.count <= 0) {
        [self->_wakeup unlock];
        return NO;
    }
    *object = [self getObject];
    [self->_wakeup signal];
    [self->_wakeup unlock];
    return YES;
}

- (BOOL)getObjectAsync:(id<SGData> *)object timeReader:(SGTimeReader)timeReader discarded:(uint64_t *)discarded
{
    [self->_wakeup lock];
    if (self->_flags.destoryed || self->_objects.count <= 0) {
        [self->_wakeup unlock];
        return NO;
    }
    *object = [self getObjectWithTimeReader:timeReader discarded:discarded];
    if (*object) {
        [self->_wakeup signal];
    }
    [self->_wakeup unlock];
    return *object != nil;
}

- (id<SGData>)getObjectWithTimeReader:(SGTimeReader)timeReader discarded:(uint64_t *)discarded
{
    CMTime desire = kCMTimeZero;
    BOOL drop = NO;
    if (!timeReader || !timeReader(&desire, &drop)) {
        return [self getObject];
    }
    *discarded = 0;
    id<SGData> object = nil;
    do {
        CMTime first = self->_objects.firstObject.timeStamp;
        if (CMTimeCompare(first, desire) <= 0) {
            if (object) {
                *discarded += 1;
                [object unlock];
            }
            object = [self getObject];
            if (!object) {
                break;
            }
            continue;
        }
        break;
    } while (drop);
    return object;
}

- (id<SGData>)getObject
{
    if (!self->_objects.firstObject) {
        return nil;
    }
    id<SGData> object = self->_objects.firstObject;
    [self->_objects removeObjectAtIndex:0];
    self->_flags.duration = CMTimeSubtract(self->_flags.duration, object.duration);
    if (CMTimeCompare(self->_flags.duration, kCMTimeZero) < 0 || self->_objects.count <= 0) {
        self->_flags.duration = kCMTimeZero;
    }
    self->_flags.size -= object.size;
    if (self->_flags.size <= 0 || self->_objects.count <= 0) {
        self->_flags.size = 0;
    }
    return object;
}

- (BOOL)flush
{
    [self->_wakeup lock];
    if (self->_flags.destoryed) {
        [self->_wakeup unlock];
        return NO;
    }
    for (id<SGData> obj in self->_objects) {
        [obj unlock];
    }
    [self->_objects removeAllObjects];
    self->_flags.size = 0;
    self->_flags.duration = kCMTimeZero;
    self->_puttingObject = nil;
    [self->_wakeup broadcast];
    [self->_wakeup unlock];
    return YES;
}

- (BOOL)destroy
{
    [self->_wakeup lock];
    if (self->_flags.destoryed) {
        [self->_wakeup unlock];
        return NO;
    }
    self->_flags.destoryed = YES;
    for (id<SGData> obj in self->_objects) {
        [obj unlock];
    }
    [self->_objects removeAllObjects];
    self->_flags.size = 0;
    self->_flags.duration = kCMTimeZero;
    self->_puttingObject = nil;
    [self->_wakeup broadcast];
    [self->_wakeup unlock];
    return YES;
}

@end
