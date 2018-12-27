//
//  SGURLDemuxer.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/13.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGDemuxable.h"

NS_ASSUME_NONNULL_BEGIN

@interface SGURLDemuxer : NSObject <SGDemuxable>

/**
 *
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithURL:(NSURL *)URL NS_DESIGNATED_INITIALIZER;

/**
 *
 */
@property (nonatomic, copy, readonly) NSURL *URL;

@end

NS_ASSUME_NONNULL_END
