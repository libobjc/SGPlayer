//
//  SGAudioDescription.h
//  SGPlayer
//
//  Created by Single on 2018/11/28.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGAudioDescription : NSObject

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

@end
