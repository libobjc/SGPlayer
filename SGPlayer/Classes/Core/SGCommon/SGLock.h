//
//  SGLock.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/29.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGMacro.h"

BOOL SGLockEXE00(id <NSLocking> locking, void (^run)(void));
BOOL SGLockEXE10(id <NSLocking> locking, SGBasicBlock (^run)(void));
BOOL SGLockEXE11(id <NSLocking> locking, SGBasicBlock (^run)(void), BOOL (^finish)(SGBasicBlock block));

BOOL SGLockCondEXE00(id <NSLocking> locking, BOOL (^verify)(void), void (^run)(void));
BOOL SGLockCondEXE10(id <NSLocking> locking, BOOL (^verify)(void), SGBasicBlock (^run)(void));
BOOL SGLockCondEXE11(id <NSLocking> locking, BOOL (^verify)(void), SGBasicBlock (^run)(void), BOOL (^finish)(SGBasicBlock block));
