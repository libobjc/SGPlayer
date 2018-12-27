//
//  SGURLAsset.h
//  SGPlayer iOS
//
//  Created by Single on 2018/9/19.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAsset.h"

NS_ASSUME_NONNULL_BEGIN

@interface SGURLAsset : SGAsset

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
