//
//  SGFFAudioFFDecoder.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAudioFFDecoder.h"
#import "SGFFAudioFFFrame.h"
#import "SGFFObjectPool.h"

@interface SGFFAudioFFDecoder ()

@end

@implementation SGFFAudioFFDecoder

- (SGMediaType)mediaType
{
    return SGMediaTypeAudio;
}

- (SGFFFrame *)nextReuseFrame
{
    SGFFAudioFFFrame * frame = [[SGFFObjectPool sharePool] objectWithClass:[SGFFAudioFFFrame class]];
    return frame;
}

@end
