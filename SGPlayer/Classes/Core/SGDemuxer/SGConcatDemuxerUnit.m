//
//  SGConcatDemuxerUnit.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGConcatDemuxerUnit.h"

@interface SGConcatDemuxerUnit ()

@property (nonatomic, strong) SGSegment * segment;

@end

@implementation SGConcatDemuxerUnit

- (instancetype)initWithSegment:(SGSegment *)segment
{
    if (self = [super init]) {
        self.segment = segment;
    }
    return self;
}

@end
