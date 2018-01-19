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

+ (AVRational)defaultTimebase
{
    static AVRational timabase = {1, 25000};
    return timabase;
}

@end
