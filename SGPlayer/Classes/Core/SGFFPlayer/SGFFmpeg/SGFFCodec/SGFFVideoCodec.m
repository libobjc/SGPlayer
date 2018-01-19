//
//  SGFFVideoCodec.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFVideoCodec.h"

@interface SGFFVideoCodec ()

@end

@implementation SGFFVideoCodec

+ (SGFFCodecType)type
{
    return SGFFCodecTypeVideo;
}

- (void)putPacket:(AVPacket)packet {};
- (void)decodeThread {};

@end
