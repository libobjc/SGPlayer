//
//  SGSonic.h
//  SGPlayer
//
//  Created by Single on 2018/12/20.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGAudioDescription.h"

@interface SGSonic : NSObject

/**
 *
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithAudioDescription:(SGAudioDescription *)audioDescription;

/**
 *
 */
@property (nonatomic, copy, readonly) SGAudioDescription *audioDescription;

/**
 *
 */
@property (nonatomic) float speed;

/**
 *
 */
@property (nonatomic) float pitch;

/**
 *
 */
@property (nonatomic) float rate;

/**
 *
 */
@property (nonatomic) float volume;

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (int)flush;

/**
 *
 */
- (int)samplesInput;

/**
 *
 */
- (int)samplesAvailable;

/**
 *
 */
- (int)write:(uint8_t **)data nb_samples:(int)nb_samples;

/**
 *
 */
- (int)read:(uint8_t **)data nb_samples:(int)nb_samples;

@end
