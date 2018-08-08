//
//  SGPlaybackTimeSync.h
//  SGPlayer
//
//  Created by Single on 2018/6/14.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTime.h"

@interface SGPlaybackTimeSync : NSObject

@property (nonatomic, assign, readonly) CMTime time;

- (void)updateKeyTime:(CMTime)time duration:(CMTime)duration rate:(CMTime)rate;
- (void)flush;

@end
