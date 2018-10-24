//
//  SGStream.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGStream.h"
#import "SGStream+Private.h"
#import "SGMapping.h"

@interface SGStream ()

@property (nonatomic, assign) AVStream * core;
@property (nonatomic, assign) void * coreptr;
@property (nonatomic, assign) SGMediaType type;
@property (nonatomic, assign) int index;
@property (nonatomic, assign) int disposition;
@property (nonatomic, assign) CMTime timebase;

@end

@implementation SGStream

- (instancetype)initWithCore:(AVStream *)core
{
    if (self = [super init])
    {
        self.core = core;
        self.coreptr = self.core;
        self.type = SGMediaTypeFF2SG(self.core->codecpar->codec_type);
        self.index = self.core->index;
        self.disposition = self.core->disposition;
        CMTime timebase = CMTimeMake(self.core->time_base.num, self.core->time_base.den);
        CMTime defaultTimebase = CMTimeMake(1, self.type == SGMediaTypeAudio ? 44100 : 25000);
        self.timebase = SGCMTimeValidate(timebase, defaultTimebase);
    }
    return self;
}

@end
