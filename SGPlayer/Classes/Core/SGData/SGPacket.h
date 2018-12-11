//
//  SGPacket.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTrack.h"
#import "SGData.h"

@interface SGPacket : NSObject <SGData>

/**
 *
 */
@property (nonatomic, readonly) void * _Nonnull coreptr;

/**
 *
 */
@property (nonatomic, strong, readonly) SGTrack * _Nullable track;

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
