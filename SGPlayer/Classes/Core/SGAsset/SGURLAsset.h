//
//  SGURLAsset.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/10.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAsset.h"
#import <AVFoundation/AVFoundation.h>

@interface SGURLAsset : SGAsset

- (instancetype)initWithURL:(NSURL *)URL;

@property (nonatomic, strong, readonly) NSURL * URL;
@property (nonatomic, assign) CMTime rate;

@end
