//
//  SGTime.h
//  SGPlayer
//
//  Created by Single on 2018/6/13.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

CMTime SGTimeValidate(CMTime time, CMTime defaultTime);
CMTime SGTimeMultiply(CMTime time, int64_t multiplier);
CMTime SGTimeMultiplyByRatio(CMTime time, int64_t multiplier, int64_t divisor);
CMTime SGTimeMakeWithSeconds(Float64 seconds);
