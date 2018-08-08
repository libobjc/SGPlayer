//
//  SGPeriodTimer.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/8.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPeriodTimer.h"

static NSString * const SGPeriodTimerNotificationName = @"SGPeriodTimerNotificationName";

@interface SGPeriodTimer ()

@property (nonatomic, assign) NSInteger count;
@property (nonatomic, strong) NSTimer * timer;

@end

@implementation SGPeriodTimer

+ (instancetype)sharedInstance
{
    static SGPeriodTimer * obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[SGPeriodTimer alloc] init];
    });
    return obj;
}

+ (void)addTarget:(id)target selector:(SEL)selector
{
    [[SGPeriodTimer sharedInstance] addTarget:target selector:selector];
}

+ (void)removeTarget:(id)target
{
    [[SGPeriodTimer sharedInstance] removeTarget:target];
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.count = 0;
        self.timer = [NSTimer timerWithTimeInterval:0.03 target:self selector:@selector(timerHandler) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        [self resumeAndPause];
    }
    return self;
}

- (void)resumeAndPause
{
    self.timer.fireDate = self.count > 0 ? [NSDate distantPast] : [NSDate distantFuture];
}

- (void)timerHandler
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SGPeriodTimerNotificationName object:nil];
}

- (void)addTarget:(id)target selector:(SEL)selector
{
    [[NSNotificationCenter defaultCenter] addObserver:target selector:selector name:SGPeriodTimerNotificationName object:nil];
    self.count++;
    [self resumeAndPause];
}

- (void)removeTarget:(id)target
{
    [[NSNotificationCenter defaultCenter] removeObserver:target];
    self.count--;
    [self resumeAndPause];
}

@end
