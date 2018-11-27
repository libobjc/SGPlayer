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

@interface SGURLAsset ()

{
    NSURL *_URL;
}

@end

@implementation SGURLAsset

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
