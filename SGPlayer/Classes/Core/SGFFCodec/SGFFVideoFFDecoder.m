//
//  SGFFVideoFFDecoder.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFVideoFFDecoder.h"
#import "SGVideoFFFrame.h"
#import "SGObjectPool.h"

@interface SGFFVideoFFDecoder ()

@end

@implementation SGFFVideoFFDecoder

- (SGMediaType)mediaType
{
    return SGMediaTypeVideo;
}

- (SGFrame *)nextReuseFrame
{
    SGVideoFFFrame * frame = [[SGObjectPool sharePool] objectWithClass:[SGVideoFFFrame class]];
    return frame;
}

@end
