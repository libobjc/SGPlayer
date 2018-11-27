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

@property (nonatomic, copy) NSURL * URL;

@end

@implementation SGURLAsset

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init]) {
        self.URL = URL;
    }
    return self;
}

- (id<SGDemuxable>)newDemuxable
{
    return [[SGURLDemuxer alloc] initWithURL:self.URL];
}

@end
