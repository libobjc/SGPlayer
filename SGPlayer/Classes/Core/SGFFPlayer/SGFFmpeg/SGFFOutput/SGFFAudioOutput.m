//
//  SGFFAudioOutput.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAudioOutput.h"

@implementation SGFFAudioOutput

- (id <SGFFOutputRender>)renderWithFrame:(id <SGFFFrame>)frame
{
    NSLog(@"Frame Position : %lld", frame.position);
    return nil;
}

@end
