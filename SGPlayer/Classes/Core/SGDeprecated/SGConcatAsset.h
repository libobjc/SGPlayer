//
//  SGConcatAsset.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/10.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAsset.h"
#import "SGURLAsset2.h"

@interface SGConcatAsset : SGAsset

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithAssets:(NSArray <SGURLAsset2 *> *)assets;

@property (nonatomic, strong, readonly) NSArray <SGURLAsset2 *> * assets;

@end
