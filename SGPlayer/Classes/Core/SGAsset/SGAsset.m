//
//  SGAsset.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/10.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAsset.h"
#import "SGAsset+Internal.h"

@implementation SGAsset

- (id)copyWithZone:(NSZone *)zone
{
    SGAsset *obj = [[self.class alloc] init];
    return obj;
}

- (id<SGDemuxable>)newDemuxable
{
    return nil;
}

@end
