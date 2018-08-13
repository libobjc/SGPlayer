//
//  SGObjectQueue.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGObjectQueue.h"

@interface SGObjectQueue ()

@property (nonatomic, assign) NSInteger maxCount;
@property (nonatomic, assign) CMTime duration;
@property (nonatomic, assign) long long size;

@property (nonatomic, strong) NSCondition * condition;
@property (nonatomic, strong) NSMutableArray <id <SGObjectQueueItem>> * objects;
@property (nonatomic, strong) __kindof id <SGObjectQueueItem> puttingObject;
@property (nonatomic, strong) __kindof id <SGObjectQueueItem> cancelPutObject;

@property (nonatomic, assign) BOOL didDestoryed;

@end

@implementation SGObjectQueue

- (instancetype)init
{
    return [self initWithMaxCount:NSIntegerMax];
}

- (instancetype)initWithMaxCount:(NSInteger)maxCount
{
    if (self = [super init])
    {
        self.maxCount = maxCount;
        self.duration = kCMTimeZero;
        self.objects = [NSMutableArray array];
        self.condition = [[NSCondition alloc] init];
    }
    return self;
}

- (void)putObjectSync:(__kindof id <SGObjectQueueItem>)object
{
    if (self.didDestoryed) {
        return;
    }
    [self.condition lock];
    while (self.objects.count >= self.maxCount)
    {
        self.puttingObject = object;
        [self.condition wait];
        self.puttingObject = nil;
        if (self.didDestoryed)
        {
            [self.condition unlock];
            return;
        }
    }
    if (object == self.cancelPutObject)
    {
        self.cancelPutObject = nil;
    }
    else
    {
        [self putObject:object];
        [self.condition signal];
    }
    [self.condition unlock];
}

- (void)putObjectAsync:(__kindof id <SGObjectQueueItem>)object
{
    if (self.didDestoryed) {
        return;
    }
    [self.condition lock];
    if (self.objects.count >= self.maxCount)
    {
        [self.condition unlock];
        return;
    }
    [self putObject:object];
    [self.condition signal];
    [self.condition unlock];
}

- (void)putObject:(__kindof id <SGObjectQueueItem>)object
{
    [object lock];
    [self.objects addObject:object];
    if (self.shouldSortObjects)
    {
        [self.objects sortUsingComparator:^NSComparisonResult(id <SGObjectQueueItem> obj1, id <SGObjectQueueItem> obj2) {
            if (CMTimeCompare(obj1.offset, obj2.offset) == 0)
            {
                return CMTimeCompare(obj1.position, obj2.position) < 0 ? NSOrderedAscending : NSOrderedDescending;
            }
            else
            {
                return CMTimeCompare(obj1.offset, obj2.offset) < 0 ? NSOrderedAscending : NSOrderedDescending;
            }
        }];
    }
    NSAssert(CMTIME_IS_VALID(object.duration), @"Objcet duration is invalid.");
    self.duration = CMTimeAdd(self.duration, object.duration);
    self.size += object.size;
}

- (__kindof id <SGObjectQueueItem>)getObjectSync
{
    [self.condition lock];
    while (self.objects.count <= 0)
    {
        [self.condition wait];
        if (self.didDestoryed)
        {
            [self.condition unlock];
            return nil;
        }
    }
    id <SGObjectQueueItem> object = [self getObject];
    [self.condition signal];
    [self.condition unlock];
    return object;
}

- (__kindof id <SGObjectQueueItem>)getObjectAsync
{
    [self.condition lock];
    if (self.objects.count <= 0 || self.didDestoryed)
    {
        [self.condition unlock];
        return nil;
    }
    id <SGObjectQueueItem> object = [self getObject];
    [self.condition signal];
    [self.condition unlock];
    return object;
}

- (__kindof id <SGObjectQueueItem>)getObjectSyncWithPTSHandler:(BOOL(^)(CMTime * current, CMTime * expect))ptsHandler drop:(BOOL)drop
{
    [self.condition lock];
    while (self.objects.count <= 0)
    {
        [self.condition wait];
        if (self.didDestoryed)
        {
            [self.condition unlock];
            return nil;
        }
    }
    id <SGObjectQueueItem> object = [self getObjectWithPTSHandler:ptsHandler drop:drop];
    if (object)
    {
        [self.condition signal];
    }
    [self.condition unlock];
    return object;
}

- (__kindof id <SGObjectQueueItem>)getObjectAsyncWithPTSHandler:(BOOL(^)(CMTime * current, CMTime * expect))ptsHandler drop:(BOOL)drop
{
    [self.condition lock];
    if (self.objects.count <= 0 || self.didDestoryed)
    {
        [self.condition unlock];
        return nil;
    }
    id <SGObjectQueueItem> object = [self getObjectWithPTSHandler:ptsHandler drop:drop];
    if (object)
    {
        [self.condition signal];
    }
    [self.condition unlock];
    return object;
}

- (__kindof id <SGObjectQueueItem>)getObjectWithPTSHandler:(BOOL(^)(CMTime * current, CMTime * expect))ptsHandler drop:(BOOL)drop
{
    if (!ptsHandler)
    {
        return [self getObject];
    }
    CMTime current = kCMTimeZero;
    CMTime expect = kCMTimeZero;
    if (!ptsHandler(&current, &expect))
    {
        return [self getObject];
    }
    id <SGObjectQueueItem> object = nil;
    do {
        CMTime first = self.objects.firstObject.pts;
        if (CMTimeCompare(first, expect) <= 0 || CMTimeCompare(current, kCMTimeZero) < 0)
        {
            [object unlock];
            object = [self getObject];
            continue;
        }
        break;
    } while (drop);
    return object;
}

- (__kindof id <SGObjectQueueItem>)getObject
{
    if (!self.objects.firstObject) {
        return nil;
    }
    id <SGObjectQueueItem> object = self.objects.firstObject;
    [self.objects removeObjectAtIndex:0];
    self.duration = CMTimeSubtract(self.duration, object.duration);
    if (CMTimeCompare(self.duration, kCMTimeZero) < 0 || self.count <= 0) {
        self.duration = kCMTimeZero;
    }
    self.size -= object.size;
    if (self.size <= 0 || self.count <= 0) {
        self.size = 0;
    }
    return object;
}

- (NSUInteger)count
{
    return self.objects.count;
}

- (void)flush
{
    [self.condition lock];
    for (id <SGObjectQueueItem> obj in self.objects)
    {
        [obj unlock];
    }
    [self.objects removeAllObjects];
    self.size = 0;
    self.duration = kCMTimeZero;
    if (self.puttingObject)
    {
        self.cancelPutObject = self.puttingObject;
    }
    [self.condition broadcast];
    [self.condition unlock];
}

- (void)destroy
{
    self.didDestoryed = YES;
    [self flush];
}


@end
