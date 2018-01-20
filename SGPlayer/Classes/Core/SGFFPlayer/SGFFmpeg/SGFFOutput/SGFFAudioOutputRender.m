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

- (void)dealloc
{
    if (self.samples)
    {
        free(self.samples);
        self.samples = nil;
    }
}

@end


@implementation SGFFAudioOutputRender (Factory)

- (SGFFAudioOutputRender *)initWithLength:(long long)length
{
    if (self = [super init])
    {
        self.length = length;
        self.samples = malloc((unsigned long)self.length);
    }
    return self;
}

@end
