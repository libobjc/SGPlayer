//
//  SGRenderer+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/11/1.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGRenderable.h"
#import "SGAudioDescription.h"
#import "SGAudioRenderer.h"
#import "SGVideoRenderer.h"
#import "SGClock+Internal.h"

@class SGAudioFormatter;

@interface SGAudioRenderer () <SGRenderable>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithClock:(SGClock *)clock;

/**
 *
 */
@property (nonatomic) CMTime rate;

/**
 *
 */
@property (nonatomic, copy, readonly) SGAudioDescription *audioDescription;

@end

@interface SGVideoRenderer () <SGRenderable>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithClock:(SGClock *)clock;

/**
 *
 */
@property (nonatomic) CMTime rate;

@end
