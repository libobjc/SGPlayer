//
//  SGAsset.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/10.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAsset.h"
#import "SGAsset+Internal.h"
#import "SGURLAsset.h"

@implementation SGAsset

+ (instancetype)assetWithURL:(NSURL *)URL
{
    return [[SGURLAsset alloc] initWithURL:URL];
}

- (id)copyWithZone:(NSZone *)zone
{
    SGAsset *obj = [[self.class alloc] init];
    return obj;
}

- (id<SGDemuxable>)newDemuxable
{
    NSAssert(NO, @"Subclass only.");
    return nil;
}

@end
