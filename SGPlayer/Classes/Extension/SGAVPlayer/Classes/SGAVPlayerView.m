//
//  SGAVPlayerView.m
//  SGAVPlayer iOS
//
//  Created by Single on 2018/1/9.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGAVPlayerView.h"
#import "SGPlatform.h"

@implementation SGAVPlayerView

#if SGPLATFORM_TARGET_OS_MAC

- (CALayer *)makeBackingLayer
{
    return [AVPlayerLayer playerLayerWithPlayer:nil];
}

#else

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

#endif

- (AVPlayerLayer *)playerLayer
{
    return (AVPlayerLayer *)self.layer;
}

@end
