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
CMTime SGTimeMultiplyByTime(CMTime time, CMTime multiplier);
CMTime SGTimeMultiplyByRatio(CMTime time, int64_t multiplier, int64_t divisor);
CMTime SGTimeDivide(CMTime time, int64_t divisor);
CMTime SGTimeDivideByTime(CMTime time, CMTime divisor);
CMTime SGTimeDivideByRatio(CMTime time, int64_t divisor, int64_t multiplier);
CMTime SGTimeMakeWithSeconds(Float64 seconds);
