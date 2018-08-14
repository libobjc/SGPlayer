//
//  SGConcatAsset.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/10.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGConcatAsset.h"

@implementation SGConcatAsset

- (instancetype)initWithAssets:(NSArray <SGURLAsset *> *)assets
{
    if (self = [super init])
    {
        _assets = assets;
    }
    return self;
}

@end
