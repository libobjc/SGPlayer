//
//  SGFFOutputManager.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFOutputManager.h"

@implementation SGFFOutputManager

- (id <SGFFOutputRender>)renderWithFrame:(id <SGFFFrame>)frame
{
    switch (frame.type)
    {
        case SGFFFrameTypeAudio:
            return [self.audioOutput renderWithFrame:frame];
        default:
            return nil;
    }
    return nil;
}

@end
