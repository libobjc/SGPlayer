//
//  SGPeriodTimer.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/8.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTime.h"

@interface SGPeriodTimer : NSObject

- (instancetype)initWithHandler:(void (^)(void))handler;

@property (nonatomic, assign) CMTime timeInterval;

- (void)start;
- (void)stop;

@end
