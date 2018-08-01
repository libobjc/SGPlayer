//
//  SGAudioFFDecoder.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGAudioFFDecoder.h"
#import "SGAudioFFFrame.h"
#import "SGObjectPool.h"

@interface SGAudioFFDecoder ()

@end

@implementation SGAudioFFDecoder

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
