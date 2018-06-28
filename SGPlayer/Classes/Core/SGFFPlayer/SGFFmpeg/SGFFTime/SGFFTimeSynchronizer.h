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

- (CMTime)realPositionWithRate:(CMTime)rate;

- (void)updateKeyPosition:(CMTime)keyPosition keyDuration:(CMTime)keyDuration;

- (void)flush;

@end
