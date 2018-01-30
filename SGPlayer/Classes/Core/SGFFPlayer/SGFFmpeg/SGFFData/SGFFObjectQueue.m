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
@property (nonatomic, assign) long long duration;
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
            return obj1.position < obj2.position ? NSOrderedAscending : NSOrderedDescending;
        }];
    }
    self.duration += object.duration;
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

- (__kindof id <SGFFObjectQueueItem>)getObjectSyncCurrentPosition:(long long)currentPosition
                                                   expectPosition:(long long)expectPosition
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
    id <SGFFObjectQueueItem> object = [self getObjectCurrentPosition:currentPosition
                                                      expectPosition:expectPosition];
    if (object)
    {
        [self.condition signal];
    }
    [self.condition unlock];
    return object;
}

- (__kindof id <SGFFObjectQueueItem>)getObjectAsyncCurrentPosition:(long long)currentPosition
                                                    expectPosition:(long long)expectPosition
{
    [self.condition lock];
    if (self.objects.count <= 0 || self.didDestoryed)
    {
        [self.condition unlock];
        return nil;
    }
    id <SGFFObjectQueueItem> object = [self getObjectCurrentPosition:currentPosition
                                                      expectPosition:expectPosition];
    [self.condition signal];
    [self.condition unlock];
    return object;
}

- (__kindof id <SGFFObjectQueueItem>)getObjectSyncWithPositionHandler:(BOOL(^)(long long * current, long long * expect))positionHandler
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

- (__kindof id <SGFFObjectQueueItem>)getObjectAsyncWithPositionHandler:(BOOL(^)(long long * current, long long * expect))positionHandler
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

- (__kindof id <SGFFObjectQueueItem>)getObjectWithPositionHandler:(BOOL(^)(long long * current, long long * expect))positionHandler
{
    if (!positionHandler)
    {
        return [self getObject];
    }
    long long current = 0;
    long long expect = 0;
    if (!positionHandler(&current, &expect))
    {
        return [self getObject];
    }
    NSLog(@"start : %f, %f", current / 12800.f, expect / 12800.f);
    id <SGFFObjectQueueItem> object = nil;
    while (self.objects.firstObject)
    {
        long long firstPosition = self.objects.firstObject.position;
        long long oldInterval = llabs(current - expect);
        long long newInterval = llabs(firstPosition - expect);
        if (newInterval <= oldInterval)
        {
            if (object)
            {
                [object unlock];
            }
            object = [self getObject];
            current = object.position;
            NSLog(@"get   : %f", object.position / 12800.f);
        }
        else if (firstPosition < current && firstPosition < expect)
        {
            id <SGFFObjectQueueItem> object = [self getObject];
            NSLog(@"drop  : %f", object.position / 12800.f);
            [object unlock];
        }
        else
        {
            break;
        }
    }
    NSLog(@"end   : %f", object.position / 12800.f);
    return object;
}

- (__kindof id <SGFFObjectQueueItem>)getObjectCurrentPosition:(long long)currentPosition
                                               expectPosition:(long long)expectPosition
{
    NSLog(@"start : %f, %f", currentPosition / 12800.f, expectPosition / 12800.f);
    id <SGFFObjectQueueItem> object = nil;
    while (self.objects.firstObject)
    {
        long long firstPosition = self.objects.firstObject.position;
        long long oldInterval = llabs(currentPosition - expectPosition);
        long long newInterval = llabs(firstPosition - expectPosition);
        if (newInterval <= oldInterval)
        {
            if (object)
            {
                [object unlock];
            }
            object = [self getObject];
            currentPosition = object.position;
            NSLog(@"get   : %f", object.position / 12800.f);
        }
        else if (firstPosition < currentPosition && firstPosition < expectPosition)
        {
            id <SGFFObjectQueueItem> object = [self getObject];
            NSLog(@"drop  : %f", object.position / 12800.f);
            [object unlock];
        }
        else
        {
            break;
        }
    }
    NSLog(@"end   : %f", object.position / 12800.f);
    return object;
}

- (__kindof id <SGFFObjectQueueItem>)getObject
{
    if (!self.objects.firstObject) {
        return nil;
    }
    id <SGFFObjectQueueItem> object = self.objects.firstObject;
    [self.objects removeObjectAtIndex:0];
    self.duration -= object.duration;
    if (self.duration < 0 || self.count <= 0) {
        self.duration = 0;
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
    self.duration = 0;
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
