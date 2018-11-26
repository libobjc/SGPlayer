//
//  SGLock.m
//  SGPlayer iOS
//
//  Created by Single on 2018/10/29.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGLock.h"

BOOL SGLockEXE00(id<NSLocking> locking, void (^run)(void))
{
    [locking lock];
    if (run) {
        run();
    }
    [locking unlock];
    return YES;
}

BOOL SGLockEXE10(id<NSLocking> locking, SGBlock (^run)(void))
{
    [locking lock];
    SGBlock r = nil;
    if (run) {
        r = run();
    }
    [locking unlock];
    if (r) {
        r();
    }
    return YES;
}

BOOL SGLockEXE11(id<NSLocking> locking, SGBlock (^run)(void), BOOL (^finish)(SGBlock block))
{
    [locking lock];
    SGBlock r = nil;
    if (run) {
        r = run();
    }
    [locking unlock];
    if (finish) {
        return finish(r ? r : ^{});
    } else if (r) {
        r();
    }
    return YES;
}

BOOL SGLockCondEXE00(id<NSLocking> locking, BOOL (^verify)(void), void (^run)(void))
{
    [locking lock];
    BOOL s = YES;
    if (verify) {
        s = verify();
    }
    if (!s) {
        [locking unlock];
        return NO;
    }
    if (run) {
        run();
    }
    [locking unlock];
    return YES;
}

BOOL SGLockCondEXE10(id<NSLocking> locking, BOOL (^verify)(void), SGBlock (^run)(void))
{
    [locking lock];
    BOOL s = YES;
    if (verify) {
        s = verify();
    }
    if (!s) {
        [locking unlock];
        return NO;
    }
    SGBlock r = nil;
    if (run) {
        r = run();
    }
    [locking unlock];
    if (r) {
        r();
    }
    return YES;
}

BOOL SGLockCondEXE11(id<NSLocking> locking, BOOL (^verify)(void), SGBlock (^run)(void), BOOL (^finish)(SGBlock block))
{
    [locking lock];
    BOOL s = YES;
    if (verify) {
        s = verify();
    }
    if (!s) {
        [locking unlock];
        return NO;
    }
    SGBlock r = nil;
    if (run) {
        r = run();
    }
    [locking unlock];
    if (finish) {
        return finish(r ? r : ^{});
    } else if (r) {
        r();
    }
    return YES;
}
