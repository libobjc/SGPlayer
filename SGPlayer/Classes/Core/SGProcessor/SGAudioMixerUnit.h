//
//  SGAudioMixerUnit.h
//  SGPlayer
//
//  Created by Single on 2018/11/29.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGAudioFrame.h"
#import "SGCapacity.h"

@interface SGAudioMixerUnit : NSObject

/**
 *
 */
@property (nonatomic, readonly) CMTimeRange timeRange;

/**
 *
 */
- (BOOL)putFrame:(SGAudioFrame * _Nonnull)frame;

/**
 *
 */
- (NSArray<SGAudioFrame *> * _Nullable)framesToEndTime:(CMTime)endTime;

/**
 *
 */
- (SGCapacity * _Nonnull)capacity;

/**
 *
 */
- (void)flush;

@end
