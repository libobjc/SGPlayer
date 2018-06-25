//
//  SGFFAudioAVCodec.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAudioAVCodec.h"
#import "SGFFAudioFrame.h"
#import "SGFFObjectPool.h"

@interface SGFFAudioAVCodec ()

@end

@implementation SGFFAudioAVCodec

- (SGMediaType)mediaType
{
    return SGMediaTypeAudio;
}

- (__kindof id <SGFFFrame>)fetchReuseFrame
{
    SGFFAudioFrame * frame = [[SGFFObjectPool sharePool] objectWithClass:[SGFFAudioFrame class]];
    return frame;
}

@end
