//
//  SGGLTimer.h
//  SGPlayer
//
//  Created by Single on 2018/6/27.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGGLTimer : NSObject

+ (instancetype)timerWithTimeInterval:(NSTimeInterval)timeInterval handler:(void (^)(void))handler;

@property (nonatomic, copy) NSDate * fireDate;
@property (nonatomic, assign, readonly) NSTimeInterval timeInterval;
@property (nonatomic, assign, readonly) BOOL valid;

- (void)invalidate;

@end
