//
//  SGSegment.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGSegment.h"
#import "SGSegment+Internal.h"

@interface SGSegment ()

@property (nonatomic) SGMediaType type;

@end

@implementation SGSegment

- (id)copyWithZone:(NSZone *)zone
{
    SGSegment * obj = [[self.class alloc] init];
    obj.timeRange = self.timeRange;
    obj.scale = self.scale;
    return obj;
}

- (instancetype)init
{
    return [self initWithTimeRange:kCMTimeRangeInvalid scale:kCMTimeInvalid];
}

- (instancetype)initWithTimeRange:(CMTimeRange)timeRange scale:(CMTime)scale
{
    if (self = [super init]) {
        self.timeRange = timeRange;
        self.scale = scale;
    }
    return self;
}

- (id<SGDemuxable>)newDemuxable
{
    return nil;
}

@end
