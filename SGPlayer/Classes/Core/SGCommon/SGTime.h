//
//  SGTime.h
//  SGPlayer
//
//  Created by Single on 2018/6/13.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

/**
 *
 */
CMTime SGCMTimeValidate(CMTime time, CMTime defaultTime);

/**
 *
 */
CMTime SGCMTimeMakeWithSeconds(Float64 seconds);

/**
 *
 */
CMTime SGCMTimeMultiply(CMTime time, CMTime multiplier);

/**
 *
 */
CMTime SGCMTimeDivide(CMTime time, CMTime divisor);
