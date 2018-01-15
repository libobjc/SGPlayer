//
//  SGPlayerActivity.h
//  SGPlayer
//
//  Created by Single on 2018/1/10.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPlayerDefines.h"

@interface SGPlayerActivity : NSObject

+ (void)becomeActive:(id <SGPlayer>)player;
+ (void)resignActive:(id <SGPlayer>)player;

@end
