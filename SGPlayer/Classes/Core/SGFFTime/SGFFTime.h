//
//  SGFFTime.h
//  SGPlayer
//
//  Created by Single on 2018/6/13.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

CMTime SGFFTimeValidate(CMTime time, CMTime defaultTime);
CMTime SGFFTimeMultiply(CMTime time, int64_t multiplier);
CMTime SGFFTimeMultiplyByRatio(CMTime time, int64_t multiplier, int64_t divisor);
CMTime SGFFTimeMakeWithSeconds(Float64 seconds);
