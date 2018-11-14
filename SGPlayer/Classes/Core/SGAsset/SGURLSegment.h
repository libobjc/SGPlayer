//
//  SGURLSegment.h
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGSegment.h"

@interface SGURLSegment : SGSegment

- (instancetype)initWithURL:(NSURL *)URL index:(int32_t)index;
- (instancetype)initWithURL:(NSURL *)URL index:(int32_t)index timeRange:(CMTimeRange)timeRange scale:(CMTime)scale;

@property (nonatomic, copy) NSURL * URL;
@property (nonatomic) int32_t index;

@end
