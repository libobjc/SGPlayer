//
//  SGURLAsset.m
//  SGPlayer iOS
//
//  Created by Single on 2018/9/19.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGURLAsset.h"
#import "SGAsset+Internal.h"
#import "SGURLDemuxer.h"

@implementation SGURLAsset

- (id)copyWithZone:(NSZone *)zone
{
    SGURLAsset *obj = [super copyWithZone:zone];
    obj->_URL = [self->_URL copy];
    return obj;
}

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init]) {
        self->_URL = [URL copy];
    }
    return self;
}

- (id<SGDemuxable>)newDemuxable
{
    return [[SGURLDemuxer alloc] initWithURL:self->_URL];
}

@end
