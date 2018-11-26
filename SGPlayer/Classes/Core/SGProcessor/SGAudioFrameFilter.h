//
//  SGAudioFrameFilter.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/30.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrameFilter.h"

@interface SGAudioFrameFilter : SGFrameFilter

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
