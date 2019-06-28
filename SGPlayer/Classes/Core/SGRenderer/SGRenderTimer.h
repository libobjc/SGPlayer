//
//  SGRenderTimer.h
//  SGPlayer
//
//  Created by Single on 2019/6/28.
//  Copyright © 2019 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGRenderTimer : NSObject

- (instancetype)initWithHandler:(dispatch_block_t)handler;

@property (nonatomic) NSTimeInterval timeInterval;
@property (nonatomic) BOOL paused;

- (void)start;
- (void)stop;

@end
