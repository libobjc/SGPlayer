//
//  SGPlayerBackgroundHandler.h
//  SGPlayer
//
//  Created by Single on 2018/1/12.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPlayerDefines.h"
#import "SGFFPlayer.h"

@interface SGPlayerBackgroundHandler : NSObject

+ (NSTimeInterval)lastWillEnterForegroundTimeInterval;
+ (NSTimeInterval)lastDidEnterBackgroundTimeInterval;

+ (instancetype)backgroundHandlerWithPlayer:(SGFFPlayer *)player;

@end
