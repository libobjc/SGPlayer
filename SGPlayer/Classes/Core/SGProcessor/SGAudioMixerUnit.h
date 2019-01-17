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

NS_ASSUME_NONNULL_BEGIN

@interface SGAudioMixerUnit : NSObject

/**
 *
 */
@property (nonatomic, readonly) CMTimeRange timeRange;

/**
 *
 */
- (BOOL)putFrame:(SGAudioFrame *)frame;

/**
 *
 */
- (NSArray<SGAudioFrame *> * _Nullable)framesToEndTime:(CMTime)endTime;

/**
 *
 */
- (SGCapacity *)capacity;

/**
 *
 */
- (void)flush;

@end

NS_ASSUME_NONNULL_END
