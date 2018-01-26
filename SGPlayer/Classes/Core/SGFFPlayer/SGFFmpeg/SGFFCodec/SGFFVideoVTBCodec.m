//
//  SGFFVideoVTBCodec.m
//  SGPlayer
//
//  Created by Single on 2018/1/26.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFVideoVTBCodec.h"

@implementation SGFFVideoVTBCodec

+ (SGFFCodecType)type
{
    return SGFFCodecTypeVideo;
}

- (NSInteger)outputRenderQueueMaxCount
{
    return 3;
}

@end
