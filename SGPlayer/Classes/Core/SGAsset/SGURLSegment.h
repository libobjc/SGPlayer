//
//  SGURLSegment.h
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGSegment.h"

@interface SGURLSegment : SGSegment

- (instancetype)initWithURL:(NSURL * _Nonnull)URL index:(int)index;
- (instancetype)initWithURL:(NSURL * _Nonnull)URL index:(int)index timeRange:(CMTimeRange)timeRange scale:(CMTime)scale;

@property (nonatomic, copy) NSURL * _Nonnull URL;
@property (nonatomic) int index;

@end
