//
//  SGFFAudioFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFFrame.h"

static int const SGFFAudioFrameMaxChannelCount = 8;

@interface SGFFAudioFrame : SGFFFrame

@property (nonatomic, assign) enum AVSampleFormat format;
@property (nonatomic, assign) int numberOfSamples;
@property (nonatomic, assign) int sampleRate;
@property (nonatomic, assign) int numberOfChannels;
@property (nonatomic, assign) long long channelLayout;
@property (nonatomic, assign) long long bestEffortTimestamp;
@property (nonatomic, assign) long long packetPosition;
@property (nonatomic, assign) long long packetDuration;
@property (nonatomic, assign) long long packetSize;
@property (nonatomic, assign) uint8_t ** data;
@property (nonatomic, assign) int * linesize;

@end
