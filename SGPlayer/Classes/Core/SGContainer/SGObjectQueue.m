//
//  SGObjectQueue.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGObjectQueue.h"

@interface SGObjectQueue ()

@property (nonatomic) uint64_t maxCount;
@property (nonatomic) CMTime duration;
@property (nonatomic) uint64_t size;

@property (nonatomic, strong) NSCondition * condition;
@property (nonatomic, strong) NSMutableArray <id <SGObjectQueueItem>> * objects;
@property (nonatomic, strong) id <SGObjectQueueItem> puttingObject;
@property (nonatomic, strong) id <SGObjectQueueItem> cancelPutObject;

@property (nonatomic) BOOL didDestoryed;

@end

@implementation SGObjectQueue

- (instancetype)init
{
    return [self initWithMaxCount:UINT64_MAX];
}

- (instancetype)initWithMaxCount:(uint64_t)maxCount
{
    if (self = [super init]) {
        self.maxCount = maxCount;
        self.duration = kCMTimeZero;
        self.objects = [NSMutableArray array];
        self.condition = [[NSCondition alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self.condition lock];
    for (id <SGObjectQueueItem> obj in self.objects) {
        [obj unlock];
    }
    [self.objects removeAllObjects];
    self.size = 0;
    self.duration = kCMTimeZero;
    self.puttingObject = nil;
    self.cancelPutObject = nil;
    [self.condition unlock];
}

- (SGCapacity *)capacity
{
    if (self.didDestoryed) {
        return [[SGCapacity alloc] init];
    }
    [self.condition lock];
    SGCapacity * ret = [[SGCapacity alloc] init];
    ret.duration = self.duration;
    ret.size = self.size;
    ret.count = self.objects.count;
    [self.condition unlock];
    return ret;
}

- (SGBlock)putObjectSync:(id <SGObjectQueueItem>)object
{
    return [self putObjectSync:object before:nil after:nil];
}

- (SGBlock)putObjectSync:(id <SGObjectQueueItem>)object before:(SGBlock)before after:(SGBlock)after
{
    if (self.didDestoryed) {
        return ^{};
    }
    [self.condition lock];
    while (self.objects.count >= self.maxCount) {
        self.puttingObject = object;
        if (before) {
            before();
        }
        [self.condition wait];
        if (after) {
            after();
        }
        self.puttingObject = nil;
        if (self.didDestoryed) {
            [self.condition unlock];
            return ^{};
        }
    }
    SGCapacity * capacity = nil;
    if (object == self.cancelPutObject) {
        self.cancelPutObject = nil;
    } else {
        capacity = [self putObject:object];
        [self.condition signal];
    }
    [self.condition unlock];
    if (capacity) {
        return ^{
            [self.delegate objectQueue:self didChangeCapacity:capacity];
        };
    }
    return ^{};
}

- (SGBlock)putObjectAsync:(id <SGObjectQueueItem>)object
{
    if (self.didDestoryed) {
        return ^{};
    }
    [self.condition lock];
    if (self.objects.count >= self.maxCount) {
        [self.condition unlock];
        return ^{};
    }
    SGCapacity * capacity = [self putObject:object];
    [self.condition signal];
    [self.condition unlock];
    if (capacity) {
        return ^{
            [self.delegate objectQueue:self didChangeCapacity:capacity];
        };
    }
    return ^{};
}

- (SGCapacity *)putObject:(id <SGObjectQueueItem>)object
{
    [object lock];
    [self.objects addObject:object];
    if (self.shouldSortObjects) {
        [self.objects sortUsingComparator:^NSComparisonResult(id <SGObjectQueueItem> obj1, id <SGObjectQueueItem> obj2) {
            return CMTimeCompare(obj1.timeStamp, obj2.timeStamp) < 0 ? NSOrderedAscending : NSOrderedDescending;
        }];
    }
    NSAssert(CMTIME_IS_VALID(object.duration), @"Objcet duration is invalid.");
    self.duration = CMTimeAdd(self.duration, object.duration);
    self.size += object.size;
    SGCapacity * obj = [[SGCapacity alloc] init];
    obj.duration = self.duration;
    obj.size = self.size;
    obj.count = self.objects.count;
    return obj;
}

- (SGBlock)getObjectSync:(id <SGObjectQueueItem> *)object
{
    return [self getObjectSync:object before:nil after:nil];
}

- (SGBlock)getObjectSync:(id <SGObjectQueueItem> *)object before:(SGBlock)before after:(SGBlock)after
{
    [self.condition lock];
    while (self.objects.count <= 0) {
        if (before) {
            before();
        }
        [self.condition wait];
        if (after) {
            after();
        }
        if (self.didDestoryed) {
            [self.condition unlock];
            return ^{};
        }
    }
    SGCapacity * capacity = nil;
    * object = [self getObject:&capacity];
    [self.condition signal];
    [self.condition unlock];
    if (capacity) {
        return ^{
            [self.delegate objectQueue:self didChangeCapacity:capacity];
        };
    }
    return ^{};
}

- (SGBlock)getObjectSync:(id <SGObjectQueueItem> *)object before:(SGBlock)before after:(SGBlock)after timeReader:(SGTimeReaderBlock)timeReader
{
    [self.condition lock];
    while (self.objects.count <= 0) {
        if (before) {
            before();
        }
        [self.condition wait];
        if (after) {
            after();
        }
        if (self.didDestoryed) {
            [self.condition unlock];
            return ^{};
        }
    }
    SGCapacity * capacity = nil;
    * object = [self getObject:&capacity timeReader:timeReader];
    if (object) {
        [self.condition signal];
    }
    [self.condition unlock];
    if (capacity) {
        return ^{
            [self.delegate objectQueue:self didChangeCapacity:capacity];
        };
    }
    return ^{};
}

- (SGBlock)getObjectAsync:(id <SGObjectQueueItem> *)object
{
    [self.condition lock];
    if (self.objects.count <= 0 || self.didDestoryed) {
        [self.condition unlock];
        return ^{};
    }
    SGCapacity * capacity = nil;
    * object = [self getObject:&capacity];
    [self.condition signal];
    [self.condition unlock];
    if (capacity) {
        return ^{
            [self.delegate objectQueue:self didChangeCapacity:capacity];
        };
    }
    return ^{};
}

- (SGBlock)getObjectAsync:(id <SGObjectQueueItem> *)object timeReader:(SGTimeReaderBlock)timeReader
{
    [self.condition lock];
    if (self.objects.count <= 0 || self.didDestoryed) {
        [self.condition unlock];
        return ^{};
    }
    SGCapacity * capacity = nil;
    * object = [self getObject:&capacity timeReader:timeReader];
    if (* object) {
        [self.condition signal];
    }
    [self.condition unlock];
    if (capacity) {
        return ^{
            [self.delegate objectQueue:self didChangeCapacity:capacity];
        };
    }
    return ^{};
}

- (id <SGObjectQueueItem>)getObject:(SGCapacity **)capacity timeReader:(SGTimeReaderBlock)timeReader
{
    CMTime desire = kCMTimeZero;
    BOOL drop = NO;
    if (!timeReader || !timeReader(&desire, &drop)) {
        return [self getObject:capacity];
    }
    id <SGObjectQueueItem> object = nil;
    do {
        CMTime first = self.objects.firstObject.timeStamp;
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

- (id <SGObjectQueueItem>)getObject:(SGCapacity **)capacity
{
    if (!self.objects.firstObject) {
        return nil;
    }
    id <SGObjectQueueItem> object = self.objects.firstObject;
    [self.objects removeObjectAtIndex:0];
    self.duration = CMTimeSubtract(self.duration, object.duration);
    if (CMTimeCompare(self.duration, kCMTimeZero) < 0 || self.objects.count <= 0) {
        self.duration = kCMTimeZero;
    }
    self.size -= object.size;
    if (self.size <= 0 || self.objects.count <= 0) {
        self.size = 0;
    }
    SGCapacity * obj = [[SGCapacity alloc] init];
    obj.duration = self.duration;
    obj.size = self.size;
    obj.count = self.objects.count;
    * capacity = obj;
    return object;
}

- (SGBlock)flush
{
    [self.condition lock];
    for (id <SGObjectQueueItem> obj in self.objects) {
        [obj unlock];
    }
    [self.objects removeAllObjects];
    self.size = 0;
    self.duration = kCMTimeZero;
    if (self.puttingObject) {
        self.cancelPutObject = self.puttingObject;
    }
    SGCapacity * capacity = [[SGCapacity alloc] init];
    [self.condition broadcast];
    [self.condition unlock];
    if (capacity) {
        return ^{
            [self.delegate objectQueue:self didChangeCapacity:capacity];
        };
    }
    return ^{};
}

- (SGBlock)destroy
{
    self.didDestoryed = YES;
    return [self flush];
}

@end
