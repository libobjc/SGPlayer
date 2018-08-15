//
//  SGStream.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGStream.h"
#import "SGDefinesMapping.h"

@implementation SGStream

- (SGMediaType)mediaType
{
    if (self.coreStream)
    {
        return SGFFMediaType(self.coreStream->codecpar->codec_type);
    }
    return SGMediaTypeUnknown;
}

- (int)index
{
    if (self.coreStream)
    {
        return self.coreStream->index;
    }
    return -1;
}

- (AVRational)timebase
{
    if (self.coreStream)
    {
        return self.coreStream->time_base;
    }
    return av_make_q(0, 1);
}

@end
