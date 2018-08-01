//
//  SGVideoFFDecoder.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGVideoFFDecoder.h"
#import "SGVideoFFFrame.h"
#import "SGObjectPool.h"

@interface SGVideoFFDecoder ()

@end

@implementation SGVideoFFDecoder

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
