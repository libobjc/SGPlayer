//
//  SGConcatSource.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/10.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGSource.h"
#import "SGConcatAsset.h"

@interface SGConcatSource : NSObject <SGSource>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithAsset:(SGConcatAsset *)asset;

@end
