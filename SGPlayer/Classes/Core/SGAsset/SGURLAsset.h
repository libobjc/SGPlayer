//
//  SGURLAsset.h
//  SGPlayer iOS
//
//  Created by Single on 2018/9/19.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAsset.h"

@interface SGURLAsset : SGAsset

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method initWithURL:
 @abstract
    Initializes an SGURLAsset with the given URL.
 */
- (instancetype)initWithURL:(NSURL *)URL;

/*!
 @property URL
 @abstract
    Indicates the URL of the asset.
 */
@property (nonatomic, copy, readonly) NSURL *URL;

@end
