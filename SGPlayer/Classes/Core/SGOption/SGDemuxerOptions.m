//
//  SGDemuxerOptions.m
//  SGPlayer
//
//  Created by Single on 2019/6/14.
//  Copyright © 2019 single. All rights reserved.
//

#import "SGDemuxerOptions.h"

@implementation SGDemuxerOptions

- (id)copyWithZone:(NSZone *)zone
{
    SGDemuxerOptions *obj = [[SGDemuxerOptions alloc] init];
    obj->_options = self->_options.copy;
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_options = @{@"reconnect" : @(1),
                           @"user-agent" : @"SGPlayer",
                           @"timeout" : @(20 * 1000 * 1000)};
    }
    return self;
}

@end
