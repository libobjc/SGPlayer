//
//  SGFFObjectQueue.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFObjectQueue.h"

@interface SGFFObjectQueue ()

@property (nonatomic, assign) NSInteger maxCount;
@property (nonatomic, assign) CMTime duration;
@property (nonatomic, assign) long long size;

@property (nonatomic, strong) NSCondition * condition;
@property (nonatomic, strong) NSMutableArray <id <SGFFObjectQueueItem>> * objects;
@property (nonatomic, strong) __kindof id <SGFFObjectQueueItem> puttingObject;
@property (nonatomic, strong) __kindof id <SGFFObjectQueueItem> cancelPutObject;

@property (nonatomic, assign) BOOL didDestoryed;

@end

@implementation SGFFObjectQueue

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

- (void)putObjectSync:(__kindof id <SGFFObjectQueueItem>)object
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

- (void)putObjectAsync:(__kindof id <SGFFObjectQueueItem>)object
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

- (void)putObject:(__kindof id <SGFFObjectQueueItem>)object
{
    [object lock];
    [self.objects addObject:object];
    if (self.shouldSortObjects)
    {
        [self.objects sortUsingComparator:^NSComparisonResult(id <SGFFObjectQueueItem> obj1, id <SGFFObjectQueueItem> obj2) {
            return CMTimeCompare(obj1.position, obj2.position) < 0 ? NSOrderedAscending : NSOrderedDescending;
        }];
    }
    NSAssert(CMTIME_IS_VALID(object.duration), @"Objcet duration is invaild.");
    self.duration = CMTimeAdd(self.duration, object.duration);
    self.size += object.size;
}

- (__kindof id <SGFFObjectQueueItem>)getObjectSync
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
    id <SGFFObjectQueueItem> object = [self getObject];
    [self.condition signal];
    [self.condition unlock];
    return object;
}

- (__kindof id <SGFFObjectQueueItem>)getObjectAsync
{
    [self.condition lock];
    if (self.objects.count <= 0 || self.didDestoryed)
    {
        [self.condition unlock];
        return nil;
    }
    id <SGFFObjectQueueItem> object = [self getObject];
    [self.condition signal];
    [self.condition unlock];
    return object;
}

- (__kindof id <SGFFObjectQueueItem>)getObjectSyncWithPositionHandler:(BOOL(^)(CMTime * current, CMTime * expect))positionHandler
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
    id <SGFFObjectQueueItem> object = [self getObjectWithPositionHandler:positionHandler];
    if (object)
    {
        [self.condition signal];
    }
    [self.condition unlock];
    return object;
}

- (__kindof id <SGFFObjectQueueItem>)getObjectAsyncWithPositionHandler:(BOOL(^)(CMTime * current, CMTime * expect))positionHandler
{
    [self.condition lock];
    if (self.objects.count <= 0 || self.didDestoryed)
    {
        [self.condition unlock];
        return nil;
    }
    id <SGFFObjectQueueItem> object = [self getObjectWithPositionHandler:positionHandler];
    if (object)
    {
        [self.condition signal];
    }
    [self.condition unlock];
    return object;
}

- (__kindof id <SGFFObjectQueueItem>)getObjectWithPositionHandler:(BOOL(^)(CMTime * current, CMTime * expect))positionHandler
{
    if (!positionHandler)
    {
        return [self getObject];
    }
    CMTime current = kCMTimeZero;
    CMTime expect = kCMTimeZero;
    if (!positionHandler(&current, &expect))
    {
        return [self getObject];
    }
    id <SGFFObjectQueueItem> object = nil;
    CMTime first = self.objects.firstObject.position;
    if (CMTimeCompare(first, expect) <= 0 || CMTimeCompare(current, kCMTimeZero) < 0)
    {
        object = [self getObject];
    }
    return object;
}

- (__kindof id <SGFFObjectQueueItem>)getObject
{
    if (!self.objects.firstObject) {
        return nil;
    }
    id <SGFFObjectQueueItem> object = self.objects.firstObject;
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

- (NSInteger)count
{
    return self.objects.count;
}

- (void)flush
{
    [self.condition lock];
    for (id <SGFFObjectQueueItem> obj in self.objects)
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
