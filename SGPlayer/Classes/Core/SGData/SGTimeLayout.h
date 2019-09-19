//
//  SGTimeLayout.h
//  SGPlayer
//
//  Created by Single on 2018/11/15.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTime.h"

@interface SGTimeLayout : NSObject <NSCopying>

/**
 *
 */
- (instancetype)initWithScale:(CMTime)scale;

/**
 *
 */
- (instancetype)initWithOffset:(CMTime)offset;

/**
 *
 */
@property (nonatomic, readonly) CMTime scale;

/**
 *
 */
@property (nonatomic, readonly) CMTime offset;

/**
 *
 */
- (CMTime)convertDuration:(CMTime)duration;

/**
 *
 */
- (CMTime)convertTimeStamp:(CMTime)timeStamp;

/**
 *
 */
- (CMTime)reconvertTimeStamp:(CMTime)timeStamp;

/**
 *
 */
- (BOOL)isEqualToTimeLayout:(SGTimeLayout *)timeLayout;

@end
