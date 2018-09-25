//
//  SGURLSource.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGSource.h"
#import "SGURLAsset.h"

@interface SGURLSource : NSObject <SGSource>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithAsset:(SGURLAsset *)asset;

@end
