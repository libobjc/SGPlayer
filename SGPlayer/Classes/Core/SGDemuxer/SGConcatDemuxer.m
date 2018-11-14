//
//  SGConcatDemuxer.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGConcatDemuxer.h"

@interface SGConcatDemuxer ()

@property (nonatomic, strong) NSArray <SGConcatDemuxerUnit *> * units;

@end

@implementation SGConcatDemuxer

- (instancetype)initWithUnits:(NSArray <SGConcatDemuxerUnit *> *)units
{
    if (self = [super init]) {
        self.units = units;
    }
    return self;
}

@end
