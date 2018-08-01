//
//  SGFFVideoFFDecoder.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFVideoFFDecoder.h"
#import "SGFFVideoFFFrame.h"
#import "SGFFObjectPool.h"

@interface SGFFVideoFFDecoder ()

@end

@implementation SGFFVideoFFDecoder

- (SGMediaType)mediaType
{
    return SGMediaTypeVideo;
}

- (SGFFFrame *)nextReuseFrame
{
    SGFFVideoFFFrame * frame = [[SGFFObjectPool sharePool] objectWithClass:[SGFFVideoFFFrame class]];
    return frame;
}

@end
