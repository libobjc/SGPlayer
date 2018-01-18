//
//  SGFFFrameQueue.m
//  SGPlayer
//
//  Created by Single on 2018/1/18.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFFrameQueue.h"

@interface SGFFFrameQueue ()

@property (nonatomic, assign) long long duration;
@property (nonatomic, assign) long long size;

@property (nonatomic, strong) NSCondition * condition;
@property (nonatomic, strong) NSMutableArray <id <SGFFFrame>> * frames;

@property (nonatomic, assign) BOOL didDestoryed;

@end

@implementation SGFFFrameQueue

- (instancetype)init
{
    if (self = [super init])
    {
        self.frames = [NSMutableArray array];
        self.condition = [[NSCondition alloc] init];
    }
    return self;
}

- (void)putFrame:(id <SGFFFrame>)frame
{
    if (self.didDestoryed) {
        return;
    }
    [self.condition lock];
    [self.frames addObject:frame];
    self.duration += frame.duration;
    self.size += frame.size;
    [self.condition signal];
    [self.condition unlock];
}

- (id <SGFFFrame>)getFrameSync
{
    [self.condition lock];
    while (self.frames.count <= 0)
    {
        if (self.didDestoryed)
        {
            [self.condition unlock];
            return nil;
        }
        [self.condition wait];
    }
    id <SGFFFrame> frame = [self getFrame];
    [self.condition unlock];
    return frame;
}

- (id <SGFFFrame>)getFrameAsync
{
    [self.condition lock];
    if (self.frames.count <= 0 || self.didDestoryed)
    {
        return nil;
    }
    id <SGFFFrame> frame = [self getFrame];
    [self.condition unlock];
    return frame;
}

- (id <SGFFFrame>)getFrame
{
    if (!self.frames.firstObject) {
        return nil;
    }
    id <SGFFFrame> frame = self.frames.firstObject;
    [self.frames removeObjectAtIndex:0];
    self.duration -= frame.duration;
    if (self.duration < 0 || self.count <= 0) {
        self.duration = 0;
    }
    self.size -= frame.size;
    if (self.size <= 0 || self.count <= 0) {
        self.size = 0;
    }
    return frame;
}

- (NSInteger)count
{
    return self.frames.count;
}

- (void)flush
{
    [self.condition lock];
    [self.frames removeAllObjects];
    self.size = 0;
    self.duration = 0;
    [self.condition unlock];
}

- (void)destroy
{
    self.didDestoryed = YES;
    [self flush];
}

@end
