//
//  SGTime.h
//  SGPlayer
//
//  Created by Single on 2018/6/13.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "rational.h"

AVRational SGRationalValidate(AVRational rational, AVRational defaultRational);
CMTime SGCMTimeMakeWithRational(int64_t timeStamp, AVRational timebase);
CMTime SGCMTimeMakeWithSeconds(Float64 seconds);
CMTime SGCMTimeMultiply(CMTime time, CMTime multiplier);
CMTime SGCMTimeDivide(CMTime time, CMTime divisor);
