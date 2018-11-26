//
//  SGLock.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/29.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDefines.h"

BOOL SGLockEXE00(id<NSLocking> locking, void (^run)(void));
BOOL SGLockEXE10(id<NSLocking> locking, SGBlock (^run)(void));
BOOL SGLockEXE11(id<NSLocking> locking, SGBlock (^run)(void), BOOL (^finish)(SGBlock block));

BOOL SGLockCondEXE00(id<NSLocking> locking, BOOL (^verify)(void), void (^run)(void));
BOOL SGLockCondEXE10(id<NSLocking> locking, BOOL (^verify)(void), SGBlock (^run)(void));
BOOL SGLockCondEXE11(id<NSLocking> locking, BOOL (^verify)(void), SGBlock (^run)(void), BOOL (^finish)(SGBlock block));
