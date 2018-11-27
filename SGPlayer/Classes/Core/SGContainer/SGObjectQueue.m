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
    int _size;
    BOOL _destoryed;
    CMTime _duration;
    uint64_t _maxCount;
    NSCondition *_wakeup;
    id<SGObjectQueueItem> _puttingObject;
    id<SGObjectQueueItem> _cancelPutObject;
    NSMutableArray<id<SGObjectQueueItem>> *_objects;
}

@end

@implementation SGObjectQueue

- (instancetype)init
{
    return [self initWithMaxCount:UINT64_MAX];
}

- (instancetype)initWithMaxCount:(uint64_t)maxCount
{
    if (self = [super init]) {
        self->_maxCount = maxCount;
        self->_duration = kCMTimeZero;
        self->_objects = [NSMutableArray array];
        self->_wakeup = [[NSCondition alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self->_wakeup lock];
    for (id<SGObjectQueueItem> obj in self->_objects) {
        [obj unlock];
    }
    [self->_objects removeAllObjects];
    self->_size = 0;
    self->_duration = kCMTimeZero;
    self->_puttingObject = nil;
    self->_cancelPutObject = nil;
    [self->_wakeup unlock];
}

- (SGCapacity *)capacity
{
    if (self.self->_destoryed) {
        return [[SGCapacity alloc] init];
    }
    [self->_wakeup lock];
    SGCapacity *ret = [[SGCapacity alloc] init];
    ret.duration = self->_duration;
    ret.size = self->_size;
    ret.count = (int)self->_objects.count;
    [self->_wakeup unlock];
    return ret;
}

- (SGBlock)putObjectSync:(id<SGObjectQueueItem>)object
{
    return [self putObjectSync:object before:nil after:nil];
}

- (SGBlock)putObjectSync:(id<SGObjectQueueItem>)object before:(SGBlock)before after:(SGBlock)after
{
    if (self.self->_destoryed) {
        return ^{};
    }
    [self->_wakeup lock];
    while (self->_objects.count >= self->_maxCount) {
        self->_puttingObject = object;
        if (before) {
            before();
        }
        [self->_wakeup wait];
        if (after) {
            after();
        }
        self->_puttingObject = nil;
        if (self.self->_destoryed) {
            [self->_wakeup unlock];
            return ^{};
        }
    }
    SGCapacity *capacity = nil;
    if (object == self->_cancelPutObject) {
        self->_cancelPutObject = nil;
    } else {
        capacity = [self putObject:object];
        [self->_wakeup signal];
    }
    [self->_wakeup unlock];
    if (capacity) {
        return ^{
            [self.delegate objectQueue:self didChangeCapacity:capacity];
        };
    }
    return ^{};
}

- (SGBlock)putObjectAsync:(id<SGObjectQueueItem>)object
{
    if (self.self->_destoryed) {
        return ^{};
    }
    [self->_wakeup lock];
    if (self->_objects.count >= self->_maxCount) {
        [self->_wakeup unlock];
        return ^{};
    }
    SGCapacity *capacity = [self putObject:object];
    [self->_wakeup signal];
    [self->_wakeup unlock];
    if (capacity) {
        return ^{
            [self.delegate objectQueue:self didChangeCapacity:capacity];
        };
    }
    return ^{};
}

- (SGCapacity *)putObject:(id<SGObjectQueueItem>)object
{
    [object lock];
    [self->_objects addObject:object];
    if (self.shouldSortObjects) {
        [self->_objects sortUsingComparator:^NSComparisonResult(id<SGObjectQueueItem> obj1, id<SGObjectQueueItem> obj2) {
            return CMTimeCompare(obj1.timeStamp, obj2.timeStamp) < 0 ? NSOrderedAscending : NSOrderedDescending;
        }];
    }
    NSAssert(CMTIME_IS_VALID(object.duration), @"Objcet duration is invalid.");
    self->_duration = CMTimeAdd(self->_duration, object.duration);
    self->_size += object.size;
    SGCapacity *obj = [[SGCapacity alloc] init];
    obj.duration = self->_duration;
    obj.size = self->_size;
    obj.count = (int)self->_objects.count;
    return obj;
}

- (SGBlock)getObjectSync:(id<SGObjectQueueItem> *)object
{
    return [self getObjectSync:object before:nil after:nil];
}

- (SGBlock)getObjectSync:(id<SGObjectQueueItem> *)object before:(SGBlock)before after:(SGBlock)after
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
        if (self.self->_destoryed) {
            [self->_wakeup unlock];
            return ^{};
        }
    }
    SGCapacity *capacity = nil;
    *object = [self getObject:&capacity];
    [self->_wakeup signal];
    [self->_wakeup unlock];
    if (capacity) {
        return ^{
            [self.delegate objectQueue:self didChangeCapacity:capacity];
        };
    }
    return ^{};
}

- (SGBlock)getObjectSync:(id<SGObjectQueueItem> *)object before:(SGBlock)before after:(SGBlock)after timeReader:(SGTimeReader)timeReader
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
        if (self.self->_destoryed) {
            [self->_wakeup unlock];
            return ^{};
        }
    }
    SGCapacity *capacity = nil;
    *object = [self getObject:&capacity timeReader:timeReader];
    if (object) {
        [self->_wakeup signal];
    }
    [self->_wakeup unlock];
    if (capacity) {
        return ^{
            [self.delegate objectQueue:self didChangeCapacity:capacity];
        };
    }
    return ^{};
}

- (SGBlock)getObjectAsync:(id<SGObjectQueueItem> *)object
{
    [self->_wakeup lock];
    if (self->_objects.count <= 0 || self.self->_destoryed) {
        [self->_wakeup unlock];
        return ^{};
    }
    SGCapacity *capacity = nil;
    *object = [self getObject:&capacity];
    [self->_wakeup signal];
    [self->_wakeup unlock];
    if (capacity) {
        return ^{
            [self.delegate objectQueue:self didChangeCapacity:capacity];
        };
    }
    return ^{};
}

- (SGBlock)getObjectAsync:(id<SGObjectQueueItem> *)object timeReader:(SGTimeReader)timeReader
{
    [self->_wakeup lock];
    if (self->_objects.count <= 0 || self.self->_destoryed) {
        [self->_wakeup unlock];
        return ^{};
    }
    SGCapacity *capacity = nil;
    *object = [self getObject:&capacity timeReader:timeReader];
    if (*object) {
        [self->_wakeup signal];
    }
    [self->_wakeup unlock];
    if (capacity) {
        return ^{
            [self.delegate objectQueue:self didChangeCapacity:capacity];
        };
    }
    return ^{};
}

- (id<SGObjectQueueItem>)getObject:(SGCapacity **)capacity timeReader:(SGTimeReader)timeReader
{
    CMTime desire = kCMTimeZero;
    BOOL drop = NO;
    if (!timeReader || !timeReader(&desire, &drop)) {
        return [self getObject:capacity];
    }
    id<SGObjectQueueItem> object = nil;
    do {
        CMTime first = self->_objects.firstObject.timeStamp;
        if (CMTimeCompare(first, desire) <= 0) {
            [object unlock];
            object = [self getObject:capacity];
            if (!object) {
                break;
            }
            continue;
        }
        break;
    } while (drop);
    return object;
}

- (id<SGObjectQueueItem>)getObject:(SGCapacity **)capacity
{
    if (!self->_objects.firstObject) {
        return nil;
    }
    id<SGObjectQueueItem> object = self->_objects.firstObject;
    [self->_objects removeObjectAtIndex:0];
    self->_duration = CMTimeSubtract(self->_duration, object.duration);
    if (CMTimeCompare(self->_duration, kCMTimeZero) < 0 || self->_objects.count <= 0) {
        self->_duration = kCMTimeZero;
    }
    self->_size -= object.size;
    if (self->_size <= 0 || self->_objects.count <= 0) {
        self->_size = 0;
    }
    SGCapacity *obj = [[SGCapacity alloc] init];
    obj.duration = self->_duration;
    obj.size = self->_size;
    obj.count = (int)self->_objects.count;
    *capacity = obj;
    return object;
}

- (SGBlock)flush
{
    [self->_wakeup lock];
    for (id<SGObjectQueueItem> obj in self->_objects) {
        [obj unlock];
    }
    [self->_objects removeAllObjects];
    self->_size = 0;
    self->_duration = kCMTimeZero;
    if (self->_puttingObject) {
        self->_cancelPutObject = self->_puttingObject;
    }
    SGCapacity *capacity = [[SGCapacity alloc] init];
    [self->_wakeup broadcast];
    [self->_wakeup unlock];
    if (capacity) {
        return ^{
            [self.delegate objectQueue:self didChangeCapacity:capacity];
        };
    }
    return ^{};
}

- (SGBlock)destroy
{
    self.self->_destoryed = YES;
    return [self flush];
}

@end
