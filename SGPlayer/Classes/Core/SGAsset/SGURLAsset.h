//
//  SGURLAsset.h
//  SGPlayer iOS
//
//  Created by Single on 2018/9/19.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAsset.h"

@interface SGURLAsset : SGAsset

/**
 *
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithURL:(NSURL * _Nonnull)URL NS_DESIGNATED_INITIALIZER;

/**
 *
 */
@property (nonatomic, copy, readonly) NSURL * _Nonnull URL;

@end
