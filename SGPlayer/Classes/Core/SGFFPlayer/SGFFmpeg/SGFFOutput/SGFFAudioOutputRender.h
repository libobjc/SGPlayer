//
//  SGFFAudioOutputRender.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFOutputRenderInternal.h"
#import "avformat.h"

static int const SGFFAudioOutputRenderMaxChannelCount = 8;

@interface SGFFAudioOutputRender : SGFFOutputRenderInternal

@property (nonatomic, assign) enum AVSampleFormat format;
@property (nonatomic, assign) int numberOfSamples;
@property (nonatomic, assign) int numberOfChannels;
@property (nonatomic, assign) SGFFTimebase timebase;
@property (nonatomic, assign) long long position;
@property (nonatomic, assign) long long duration;
@property (nonatomic, assign) long long size;
@property (nonatomic, assign, readonly) void ** data;
@property (nonatomic, assign, readonly) int * linesize;

- (void)updateData:(void **)data linesize:(int *)linesize;

@end
