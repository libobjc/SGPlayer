//
//  SGAudioFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFrame.h"
#import "SGFFDefines.h"

static int const SGAudioFrameMaxChannelCount = 8;

@interface SGAudioFrame : SGFrame

//@property (nonatomic, assign, readonly) SGAVSampleFormat format;
//@property (nonatomic, assign, readonly) int numberOfSamples;
//@property (nonatomic, assign, readonly) int sampleRate;
//@property (nonatomic, assign, readonly) int numberOfChannels;
//@property (nonatomic, assign, readonly) long long channelLayout;
//@property (nonatomic, assign, readonly) uint8_t ** data;
//@property (nonatomic, assign, readonly) int * linesize;

@property (nonatomic, assign) SGAVSampleFormat format;
@property (nonatomic, assign) int numberOfSamples;
@property (nonatomic, assign) int sampleRate;
@property (nonatomic, assign) int numberOfChannels;
@property (nonatomic, assign) long long channelLayout;
@property (nonatomic, assign) uint8_t ** data;
@property (nonatomic, assign) int * linesize;

@end
