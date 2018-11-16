//
//  SGURLAsset2.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/10.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAsset.h"
#import <AVFoundation/AVFoundation.h>

@interface SGURLAsset2 : SGAsset

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithURL:(NSURL *)URL;

@property (nonatomic, strong, readonly) NSURL * URL;
@property (nonatomic) CMTime scale;             // Default value is (1, 1).
@property (nonatomic) CMTimeRange timeRange;    // Default value is (kCMTimeNegativeInfinity, kCMTimePositiveInfinity)).

@end
