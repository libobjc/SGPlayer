//
//  SGFFAudioFFDecoder.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAudioFFDecoder.h"
#import "SGAudioFFFrame.h"
#import "SGObjectPool.h"

@interface SGFFAudioFFDecoder ()

@end

@implementation SGFFAudioFFDecoder

- (SGMediaType)mediaType
{
    return SGMediaTypeAudio;
}

- (SGFrame *)nextReuseFrame
{
    SGFFAudioFFFrame * frame = [[SGObjectPool sharePool] objectWithClass:[SGFFAudioFFFrame class]];
    return frame;
}

@end
