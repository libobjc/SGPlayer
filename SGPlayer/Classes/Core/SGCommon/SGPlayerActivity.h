//
//  SGPlayerActivity.h
//  SGPlayer
//
//  Created by Single on 2018/1/10.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPlayer.h"

@interface SGPlayerActivity : NSObject

+ (void)becomeActive:(SGPlayer *)player;
+ (void)resignActive:(SGPlayer *)player;

@end
