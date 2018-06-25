//
//  SGFFStream.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFStream.h"
#import "SGFFDefineMap.h"

@implementation SGFFStream

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

- (CMTime)timebase
{
    if (self.coreStream)
    {
        return CMTimeMake(self.coreStream->time_base.num, self.coreStream->time_base.den);
    }
    return kCMTimeZero;
}

@end
