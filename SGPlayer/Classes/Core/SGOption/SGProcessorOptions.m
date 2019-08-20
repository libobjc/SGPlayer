//
//  SGProcessorOptions.m
//  SGPlayer
//
//  Created by Single on 2019/8/13.
//  Copyright © 2019 single. All rights reserved.
//

#import "SGProcessorOptions.h"
#import "SGAudioProcessor.h"
#import "SGVideoProcessor.h"

@implementation SGProcessorOptions

- (id)copyWithZone:(NSZone *)zone
{
    SGProcessorOptions *obj = [[SGProcessorOptions alloc] init];
    obj->_audioClass = self->_audioClass.copy;
    obj->_videoClass = self->_videoClass.copy;
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_audioClass = [SGAudioProcessor class];
        self->_videoClass = [SGVideoProcessor class];
    }
    return self;
}

@end
