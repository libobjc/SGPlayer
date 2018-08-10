//
//  SGConcatAsset.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/10.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGConcatAsset.h"

@implementation SGConcatAssetUnit

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init])
    {
        _URL = URL;
        self.scale = CMTimeMake(1, 1);
    }
    return self;
}

@end

@interface SGConcatAsset ()

@end

@implementation SGConcatAsset

- (instancetype)initWithUnits:(NSArray <SGConcatAssetUnit *> *)units
{
    if (self = [super init])
    {
        _units = units;
    }
    return self;
}

@end
