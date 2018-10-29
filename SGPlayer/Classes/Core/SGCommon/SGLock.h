//
//  SGLock.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/29.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGMacro.h"

BOOL SGLockEXE(id <NSLocking> locking,
               BOOL (^verify)(void),
               SGBasicBlock (^run)(void),
               BOOL (^done)(SGBasicBlock block));
