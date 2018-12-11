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
- (SGAudioDescription * _Nullable)audioDescription;

/**
 *
 */
- (int)numberOfSamples;

/**
 *
 */
- (int * _Nullable)linesize;

/**
 *
 */
- (uint8_t * _Nullable * _Nullable)data;

@end
