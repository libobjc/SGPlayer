//
//  SGFFVideoAVCodec.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFVideoAVCodec.h"
#import "SGFFVideoFrame.h"
#import "SGFFObjectPool.h"

@interface SGFFVideoAVCodec ()

@end

@implementation SGFFVideoAVCodec

- (SGMediaType)mediaType
{
    return SGMediaTypeVideo;
}

- (__kindof id <SGFFFrame>)fetchReuseFrame
{
    SGFFVideoFrame * frame = [[SGFFObjectPool sharePool] objectWithClass:[SGFFVideoFrame class]];
    [frame updateDataType:SGFFVideoFrameDataTypeAVFrame];
    return frame;
}

@end
