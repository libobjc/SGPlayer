//
//  SGStream.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGStream.h"
#import "SGFFDefinesMapping.h"

@implementation SGStream

- (SGMediaType)mediaType
{
    if (self.coreStream)
    {
        return SGDMMediaTypeFF2SG(self.coreStream->codecpar->codec_type);
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
    CMTime timebase = kCMTimeZero;
    if (self.coreStream)
    {
        timebase = CMTimeMake(self.coreStream->time_base.num, self.coreStream->time_base.den);
    }
    CMTime defaultTimebase = self.mediaType == SGMediaTypeAudio ? CMTimeMake(1, 44100) : CMTimeMake(1, 25000);
    return SGCMTimeValidate(timebase, defaultTimebase);
}

@end
