//
//  SGFFAudioOutputRender.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFOutputRenderInternal.h"
#import "SGFFAudioFrame.h"

@interface SGFFAudioOutputRender : SGFFOutputRenderInternal

@property (nonatomic, assign, readonly) float * samples;
@property (nonatomic, assign, readonly) long long length;
@property (nonatomic, assign) long long offset;

- (void)updateSamples:(float *)samples length:(long long)length;

@end
