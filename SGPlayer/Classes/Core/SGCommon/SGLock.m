//
//  SGLock.m
//  SGPlayer iOS
//
//  Created by Single on 2018/10/29.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGLock.h"

BOOL SGLockEXE(id <NSLocking> locking,
               BOOL (^verify)(void),
               SGBasicBlock (^run)(void),
               BOOL (^done)(SGBasicBlock block))
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
    if (done) {
        return done(block);
    }
    return YES;
}
