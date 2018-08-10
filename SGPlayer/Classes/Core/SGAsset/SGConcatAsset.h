//
//  SGConcatAsset.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/10.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAsset.h"
#import <AVFoundation/AVFoundation.h>

@interface SGConcatAssetUnit : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithURL:(NSURL *)URL;

@property (nonatomic, strong, readonly) NSURL * URL;
@property (nonatomic, assign) CMTime scale;

@end

@interface SGConcatAsset : SGAsset

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithUnits:(NSArray <SGConcatAssetUnit *> *)units;

@property (nonatomic, strong) NSArray <SGConcatAssetUnit *> * units;

@end
