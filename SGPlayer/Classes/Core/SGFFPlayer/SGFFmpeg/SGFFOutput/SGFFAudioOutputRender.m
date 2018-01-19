//
//  SGFFAudioOutputRender.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAudioOutputRender.h"

@implementation SGFFAudioOutputRender

- (SGFFOutputRenderType)type
{
    return SGFFOutputRenderTypeAudio;
}

@end


@implementation SGFFAudioOutputRender (Factory)

- (SGFFAudioOutputRender *)initWithAudioFrame:(SGFFAudioFrame *)audioFrame
{
    if (self = [super init])
    {
        
    }
    return self;
}

@end
