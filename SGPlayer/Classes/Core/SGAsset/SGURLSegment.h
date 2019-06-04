//
//  SGURLSegment.h
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGSegment.h"

@interface SGURLSegment : SGSegment

/**
 *
 */
- (instancetype)initWithURL:(NSURL *)URL index:(NSInteger)index timeRange:(CMTimeRange)timeRange scale:(CMTime)scale;

/**
 *
 */
@property (nonatomic, copy, readonly) NSURL *URL;

/**
 *
 */
@property (nonatomic, readonly) NSInteger index;

@end
