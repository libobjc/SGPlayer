//
//  SGFFAudioOutput.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAudioOutput.h"
#import "SGFFAudioOutputRender.h"

@implementation SGFFAudioOutput

- (id <SGFFOutputRender>)renderWithFrame:(id <SGFFFrame>)frame
{
    if (frame.audioFrame)
    {
        NSLog(@"Frame Position : %lld", frame.position);
        return [[SGFFAudioOutputRender alloc] initWithAudioFrame:frame.audioFrame];
    }
    return nil;
}

@end
