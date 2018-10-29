//
//  SGLock.m
//  SGPlayer iOS
//
//  Created by Single on 2018/10/29.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGLock.h"

BOOL SGLockEXE(id <NSLocking> locking, SGBasicBlock (^run)(void))
{
    [locking lock];
    SGBasicBlock r = run();
    [locking unlock];
    if (r) {
        r();
    }
    return YES;
}

BOOL SGLockCondEXE(id <NSLocking> locking, BOOL (^verify)(void), SGBasicBlock (^run)(void), BOOL (^finish)(SGBasicBlock block))
{
    [locking lock];
    BOOL suc = YES;
    if (verify) {
        suc = verify();
    }
    if (!suc) {
        [locking unlock];
        return NO;
    }
    SGBasicBlock block = ^{};
    if (run) {
        SGBasicBlock r = run();
        if (r) {
            block = r;
        }
    }
    [locking unlock];
    if (finish) {
        return finish(block);
    } else if (block) {
        block();
    }
    return YES;
}
