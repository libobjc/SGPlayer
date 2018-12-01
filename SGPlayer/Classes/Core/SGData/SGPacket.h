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
- (void * _Nonnull)coreptr;

/**
 *
 */
- (SGTrack * _Nullable)track;

/**
 *
 */
- (int)size;

/**
 *
 */
- (CMTime)duration;

/**
 *
 */
- (CMTime)timeStamp;

/**
 *
 */
- (CMTime)decodeTimeStamp;

@end
