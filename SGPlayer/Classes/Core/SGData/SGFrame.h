//
//  SGFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/18.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTrack.h"
#import "SGData.h"

static int const SGFramePlaneCount = 8;

@interface SGFrame : NSObject <SGData>

/**
 *
 */
@property (nonatomic, readonly) void *coreptr;

/**
 *
 */
@property (nonatomic, strong, readonly) SGTrack *track;

/**
 *
 */
@property (nonatomic, strong, readonly) NSDictionary *metadata;

/**
 *
 */
@property (nonatomic, readonly) CMTime duration;

/**
 *
 */
@property (nonatomic, readonly) CMTime timeStamp;

/**
 *
 */
@property (nonatomic, readonly) CMTime decodeTimeStamp;

/**
 *
 */
@property (nonatomic, readonly) int size;

@end
