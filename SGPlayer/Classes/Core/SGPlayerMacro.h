//
//  SGPlayerMacro.h
//  SGPlayer
//
//  Created by Single on 16/6/29.
//  Copyright © 2016年 single. All rights reserved.
//

#import <Foundation/Foundation.h>

// weak self
#define SGWeakSelf __weak typeof(self) weakSelf = self;
#define SGStrongSelf __strong typeof(weakSelf) strongSelf = weakSelf;

// log level
#ifdef DEBUG
#define SGPlayerLog(...) NSLog(__VA_ARGS__)
#else
#define SGPlayerLog(...)
#endif
