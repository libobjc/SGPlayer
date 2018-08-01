//
//  SGMacro.h
//  SGPlayer
//
//  Created by Single on 16/6/29.
//  Copyright © 2016年 single. All rights reserved.
//

#ifndef SGMacro_h
#define SGMacro_h

#import <Foundation/Foundation.h>

#if defined(__cplusplus)
#define SGPLAYER_EXTERN extern "C"
#else
#define SGPLAYER_EXTERN extern
#endif

#define SGWeakSelf __weak typeof(self) weakSelf = self;
#define SGStrongSelf __strong typeof(weakSelf) strongSelf = weakSelf;

#ifdef DEBUG
#define SGPlayerLog(...) NSLog(__VA_ARGS__)
#else
#define SGPlayerLog(...)
#endif

#endif
