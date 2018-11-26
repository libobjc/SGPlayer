//
//  SGAudioFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFrame.h"

@interface SGAudioFrame : SGFrame

/**
 *  AVSampleFormat
 */
- (int)format;

/**
 *
 */
- (int)isPlanar;

/**
 *
 */
- (int)sampleRate;

/**
 *
 */
- (int)numberOfChannels;

/**
 *
 */
- (uint64_t)channelLayout;

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
