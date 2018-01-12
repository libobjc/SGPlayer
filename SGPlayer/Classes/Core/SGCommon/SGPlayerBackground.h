//
//  SGPlayerBackground.h
//  SGPlayer
//
//  Created by Single on 2018/1/12.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPlayerDefines.h"

@interface SGPlayerBackground : NSObject

@property (nonatomic, weak, readonly) id<SGPlayer> player;

- (void)becomeActive:(id<SGPlayer>)player;
- (void)resignActive:(id<SGPlayer>)player;

@end
