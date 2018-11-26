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
- (SInt32)format;

/**
 *
 */
- (BOOL)isPlanar;

/**
 *
 */
- (SInt32)sampleRate;

/**
 *
 */
- (SInt32)numberOfChannels;

/**
 *
 */
- (UInt64)channelLayout;

/**
 *
 */
- (SInt32)numberOfSamples;

/**
 *
 */
- (SInt32 * _Nullable)linesize;

/**
 *
 */
- (UInt8 * _Nullable * _Nullable)data;

@end
