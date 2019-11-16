//
//  SGAudioFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFrame.h"
#import "SGAudioDescriptor.h"

@interface SGAudioFrame : SGFrame

/**
 *
 */
@property (nonatomic, strong, readonly) SGAudioDescriptor *descriptor;

/**
 *
 */
@property (nonatomic, readonly) int numberOfSamples;

/**
 *
 */
- (int *)linesize;

/**
 *
 */
- (uint8_t **)data;

@end
