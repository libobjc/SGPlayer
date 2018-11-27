//
//  SGRenderer+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/11/1.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGRenderable.h"
#import "SGAudioFrameFilter.h"
#import "SGAudioRenderer.h"
#import "SGVideoRenderer.h"
#import "SGClock+Internal.h"

@class SGAudioFrameFilter;

@interface SGAudioRenderer () <SGRenderable>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithClock:(SGClock *)clock NS_DESIGNATED_INITIALIZER;

/**
 *
 */
@property (nonatomic) CMTime rate;

/**
 *
 */
- (SGAudioFrameFilter *)filter;

@end

@interface SGVideoRenderer () <SGRenderable>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithClock:(SGClock *)clock NS_DESIGNATED_INITIALIZER;

/**
 *
 */
@property (nonatomic) CMTime rate;

@end
