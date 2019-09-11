//
//  SGOptions.m
//  SGPlayer iOS
//
//  Created by Single on 2018/10/29.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGOptions.h"

@implementation SGOptions

+ (instancetype)sharedOptions
{
    static SGOptions *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[SGOptions alloc] init];
    });
    return obj;
}

- (id)copyWithZone:(NSZone *)zone
{
    SGOptions *obj = [[SGOptions alloc] init];
    obj->_demuxer = self->_demuxer.copy;
    obj->_decoder = self->_decoder.copy;
    obj->_processor = self->_processor.copy;
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_demuxer = [[SGDemuxerOptions alloc] init];
        self->_decoder = [[SGDecoderOptions alloc] init];
        self->_processor = [[SGProcessorOptions alloc] init];
    }
    return self;
}

@end
