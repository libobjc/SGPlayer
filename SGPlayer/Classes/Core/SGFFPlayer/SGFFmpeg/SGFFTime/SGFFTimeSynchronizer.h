//
//  SGFFTimeSynchronizer.h
//  SGPlayer
//
//  Created by Single on 2018/6/14.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFTime.h"

@interface SGFFTimeSynchronizer : NSObject

@property (nonatomic, assign, readonly) CMTime position;

- (void)updatePosition:(CMTime)position duration:(CMTime)duration rate:(CMTime)rate;
- (void)flush;

@end
