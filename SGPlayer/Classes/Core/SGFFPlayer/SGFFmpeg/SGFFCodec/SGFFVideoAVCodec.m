//
//  SGFFVideoAVCodec.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFVideoAVCodec.h"

@interface SGFFVideoAVCodec ()

@end

@implementation SGFFVideoAVCodec

+ (SGFFCodecType)type
{
    return SGFFCodecTypeVideo;
}

- (NSInteger)frameQueueMaxCount
{
    return 3;
}

- (void)putPacket:(AVPacket)packet {};
- (void)decodeThread {};

@end
