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

@property (nonatomic) BOOL paused;

@property (nonatomic, readonly) double timestamp;
@property (nonatomic, readonly) double duration;
@property (nonatomic, readonly) double nextTimestamp;

- (void)invalidate;

@end
