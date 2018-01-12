//
//  SGPlayerBackground.h
//  SGPlayer
//
//  Created by Single on 2018/1/12.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPlayerDefines.h"

@class SGPlayerBackground;

@protocol SGPlayerBackgroundDelegate <NSObject>

- (void)backgroundWillEnterForeground:(SGPlayerBackground *)background;
- (void)backgroundDidEnterBackground:(SGPlayerBackground *)background;

@end

@interface SGPlayerBackground : NSObject

@property (nonatomic, weak) id <SGPlayerBackgroundDelegate> delegate;

- (void)becomeActive:(id<SGPlayer>)player;
- (void)resignActive:(id<SGPlayer>)player;

@end
