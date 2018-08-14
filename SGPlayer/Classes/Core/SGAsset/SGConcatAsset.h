//
//  SGConcatAsset.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/10.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAsset.h"
#import "SGURLAsset.h"

@interface SGConcatAsset : SGAsset

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithAssets:(NSArray <SGURLAsset *> *)assets;

@property (nonatomic, strong, readonly) NSArray <SGURLAsset *> * assets;

@end
