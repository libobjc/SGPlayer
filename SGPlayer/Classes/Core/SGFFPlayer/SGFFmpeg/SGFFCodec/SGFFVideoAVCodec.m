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

- (NSInteger)outputRenderQueueMaxCount
{
    return 3;
}

- (BOOL)putPacket:(AVPacket)packet {return NO;}
- (void)decodeThread {}

@end
