//
//  SGFrame.m
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrame.h"

@interface SGFrame ()

SGObjectPoolItemInterface

@end

@implementation SGFrame

SGObjectPoolItemImplementation

- (SGMediaType)mediaType
{
    return SGMediaTypeUnknown;
}

- (void)clear
{
    self.timebase = av_make_q(0, 1);
    self.offset = kCMTimeZero;
    self.scale = CMTimeMake(1, 1);
    self.timeStamp = kCMTimeZero;
    self.duration = kCMTimeZero;
    self.originalTimeStamp = kCMTimeZero;
    self.originalDuration = kCMTimeZero;
    self.decodeTimeStamp = kCMTimeZero;
    self.size = 0;
}

@end
