//
//  SGGLDisplayLink.h
//  SGPlayer
//
//  Created by Single on 2018/1/24.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGGLDisplayLink : NSObject

- (instancetype)initWithTimeInterval:(double)timeInterval handler:(void (^)(void))handler;

@property(nonatomic, assign) BOOL paused;

@property (nonatomic, assign, readonly) double timestamp;
@property (nonatomic, assign, readonly) double duration;
@property (nonatomic, assign, readonly) double nextTimestamp;

- (void)invalidate;

@end
