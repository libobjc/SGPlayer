//
//  SGAudioDescription.h
//  SGPlayer
//
//  Created by Single on 2018/11/28.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SGAudioDescription : NSObject <NSCopying>

/**
 *  AVSampleFormat
 */
@property (nonatomic) int format;

/**
 *
 */
@property (nonatomic) int sampleRate;

/**
 *
 */
@property (nonatomic) int numberOfChannels;

/**
 *
 */
@property (nonatomic) uint64_t channelLayout;

/**
 *
 */
- (BOOL)isPlanar;

/**
 *
 */
- (int)bytesPerSample;

/**
 *
 */
- (int)numberOfPlanes;

/**
 *
 */
- (int)linesize:(int)numberOfSamples;

/**
 *
 */
- (BOOL)isEqualToDescription:(SGAudioDescription *)description;

@end

NS_ASSUME_NONNULL_END
