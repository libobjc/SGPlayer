//
//  SGAsset.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/10.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class SGAsset
 @abstract
    Abstract class for assets.
 
 @discussion
    Use SGURLAsset or SGMutableAsset.
 */
@interface SGAsset : NSObject <NSCopying>

/*!
 @method assetWithURL:
 @abstract
    Returns an instance of SGAsset for inspection of a media resource.
 @result
    An instance of SGAsset.
 
 @discussion
    Returns a newly allocated instance of a subclass of SGAsset initialized with the specified URL.
 */
+ (instancetype)assetWithURL:(NSURL *)URL;

@end
