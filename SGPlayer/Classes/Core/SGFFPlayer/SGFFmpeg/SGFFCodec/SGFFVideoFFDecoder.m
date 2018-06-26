//
//  SGFFVideoFFDecoder.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFVideoFFDecoder.h"
#import "SGFFVideoFrame.h"
#import "SGFFObjectPool.h"

@interface SGFFVideoFFDecoder ()

@end

@implementation SGFFVideoFFDecoder

- (SGMediaType)mediaType
{
    return SGMediaTypeVideo;
}

- (__kindof SGFFFrame *)nextReuseFrame
{
    SGFFVideoFrame * frame = [[SGFFObjectPool sharePool] objectWithClass:[SGFFVideoFrame class]];
    [frame updateDataType:SGFFVideoFrameDataTypeAVFrame];
    return frame;
}

@end
