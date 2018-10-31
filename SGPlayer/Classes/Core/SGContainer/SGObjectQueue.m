//
//  SGObjectQueue.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGObjectQueue.h"

@interface SGObjectQueue ()

@property (nonatomic, assign) NSUInteger maxCount;
@property (nonatomic, assign) CMTime duration;
@property (nonatomic, assign) uint64_t size;

@property (nonatomic, strong) NSCondition * condition;
@property (nonatomic, strong) NSMutableArray <id <SGObjectQueueItem>> * objects;
@property (nonatomic, strong) __kindof id <SGObjectQueueItem> puttingObject;
@property (nonatomic, strong) __kindof id <SGObjectQueueItem> cancelPutObject;

@property (nonatomic, assign) BOOL didDestoryed;

@end

@implementation SGObjectQueue

- (instancetype)init
{
    return [self initWithMaxCount:NSUIntegerMax];
}

- (instancetype)initWithMaxCount:(NSUInteger)maxCount
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

- (SGBasicBlock)putObjectSync:(__kindof id <SGObjectQueueItem>)object
{
    return [self putObjectSync:object waitHandler:nil resumeHandler:nil];
}

- (SGBasicBlock)putObjectSync:(__kindof id <SGObjectQueueItem>)object waitHandler:(void (^)(void))waitHandler resumeHandler:(void (^)(void))resumeHandler
{
    if (self.didDestoryed) {
        return ^{};
    }
    [self.condition lock];
    while (self.objects.count >= self.maxCount) {
        self.puttingObject = object;
        if (waitHandler) {
            waitHandler();
        }
        [self.condition wait];
        if (resumeHandler) {
            resumeHandler();
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

- (SGBasicBlock)putObjectAsync:(__kindof id <SGObjectQueueItem>)object
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

- (SGCapacity *)putObject:(__kindof id <SGObjectQueueItem>)object
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

- (SGBasicBlock)getObjectSync:(__kindof id <SGObjectQueueItem> *)object
{
    return [self getObjectSync:object waitHandler:nil resumeHandler:nil];
}

- (SGBasicBlock)getObjectSync:(__kindof id <SGObjectQueueItem> *)object waitHandler:(void (^)(void))waitHandler resumeHandler:(void (^)(void))resumeHandler
{
    [self.condition lock];
    while (self.objects.count <= 0) {
        if (waitHandler) {
            waitHandler();
        }
        [self.condition wait];
        if (resumeHandler) {
            resumeHandler();
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

- (SGBasicBlock)getObjectSync:(__kindof id <SGObjectQueueItem> *)object waitHandler:(void (^)(void))waitHandler resumeHandler:(void (^)(void))resumeHandler ptsHandler:(BOOL(^)(CMTime * current, CMTime * expect))ptsHandler drop:(BOOL)drop
{
    [self.condition lock];
    while (self.objects.count <= 0) {
        if (waitHandler) {
            waitHandler();
        }
        [self.condition wait];
        if (resumeHandler) {
            resumeHandler();
        }
        if (self.didDestoryed) {
            [self.condition unlock];
            return ^{};
        }
    }
    SGCapacity * capacity = nil;
    * object = [self getObject:&capacity ptsHandler:ptsHandler drop:drop];
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

- (SGBasicBlock)getObjectAsync:(__kindof id <SGObjectQueueItem> *)object
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

- (SGBasicBlock)getObjectAsync:(__kindof id <SGObjectQueueItem> *)object ptsHandler:(BOOL(^)(CMTime * current, CMTime * expect))ptsHandler drop:(BOOL)drop
{
    [self.condition lock];
    if (self.objects.count <= 0 || self.didDestoryed) {
        [self.condition unlock];
        return ^{};
    }
    SGCapacity * capacity = nil;
    * object = [self getObject:&capacity ptsHandler:ptsHandler drop:drop];
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

- (__kindof id <SGObjectQueueItem>)getObject:(SGCapacity **)capacity ptsHandler:(BOOL(^)(CMTime * current, CMTime * expect))ptsHandler drop:(BOOL)drop
{
    if (!ptsHandler) {
        return [self getObject:capacity];
    }
    CMTime current = kCMTimeZero;
    CMTime expect = kCMTimeZero;
    if (!ptsHandler(&current, &expect)) {
        return [self getObject:capacity];
    }
    id <SGObjectQueueItem> object = nil;
    do {
        CMTime first = self.objects.firstObject.timeStamp;
        if (CMTimeCompare(first, expect) <= 0 || CMTimeCompare(current, kCMTimeZero) < 0) {
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

- (__kindof id <SGObjectQueueItem>)getObject:(SGCapacity **)capacity
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

- (SGBasicBlock)flush
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

- (SGBasicBlock)destroy
{
    self.didDestoryed = YES;
    return [self flush];
}

@end
