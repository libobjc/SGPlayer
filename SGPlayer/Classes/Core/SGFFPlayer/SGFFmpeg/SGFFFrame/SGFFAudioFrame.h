//
//  SGFFAudioFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFFrameInternal.h"

@interface SGFFAudioFrame : SGFFFrameInternal

@property (nonatomic, assign) SGFFTimebase timebase;
@property (nonatomic, assign) enum AVSampleFormat format;
@property (nonatomic, assign) long long numberOfSamples;
@property (nonatomic, assign) long long sampleRate;
@property (nonatomic, assign) long long numberOfChannels;
@property (nonatomic, assign) long long channelLayout;
@property (nonatomic, assign) long long position;
@property (nonatomic, assign) long long duration;
@property (nonatomic, assign) long long size;
@property (nonatomic, assign) long long bestEffortTimestamp;
@property (nonatomic, assign) long long packetPosition;
@property (nonatomic, assign) long long packetDuration;
@property (nonatomic, assign) long long packetSize;
@property (nonatomic, assign) uint8_t * data;

@end


@interface SGFFAudioFrame (Factory)

- (SGFFAudioFrame *)initWithAVFrame:(void *)avframe timebase:(SGFFTimebase)timebase;

@end
