//
//  SGFFAudioFFDecoder.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAudioFFDecoder.h"
#import "SGFFAudioFrame.h"
#import "SGFFObjectPool.h"

@interface SGFFAudioFFDecoder ()

@end

@implementation SGFFAudioFFDecoder

- (SGMediaType)mediaType
{
    return SGMediaTypeAudio;
}

- (__kindof id <SGFFFrame>)nextReuseFrame
{
    SGFFAudioFrame * frame = [[SGFFObjectPool sharePool] objectWithClass:[SGFFAudioFrame class]];
    return frame;
}

@end
