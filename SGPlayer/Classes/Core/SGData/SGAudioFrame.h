//
//  SGAudioFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFrame.h"
#import "SGAudioDescription.h"

@interface SGAudioFrame : SGFrame

/**
 *
 */
@property (nonatomic, strong, readonly) SGAudioDescription * _Nullable audioDescription;

/**
 *
 */
@property (nonatomic, readonly) int numberOfSamples;

/**
 *
 */
- (int * _Nullable)linesize;

/**
 *
 */
- (uint8_t * _Nullable * _Nullable)data;

@end
