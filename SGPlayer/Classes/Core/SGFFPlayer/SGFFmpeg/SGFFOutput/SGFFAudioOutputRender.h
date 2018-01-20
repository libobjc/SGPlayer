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

@property (nonatomic, assign) float * samples;
@property (nonatomic, assign) long long length;
@property (nonatomic, assign) long long offset;

@end


@interface SGFFAudioOutputRender (Factory)

- (SGFFAudioOutputRender *)initWithLength:(long long)length;

@end
