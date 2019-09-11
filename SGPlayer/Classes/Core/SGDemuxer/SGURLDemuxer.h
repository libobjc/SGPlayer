//
//  SGURLDemuxer.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/13.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGDemuxable.h"

@interface SGURLDemuxer : NSObject <SGDemuxable>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method initWithURL:
 @abstract
    Initializes an SGURLDemuxer with an NSURL.
 */
- (instancetype)initWithURL:(NSURL *)URL;

/*!
 @property URL
 @abstract
    Indicates the URL of the demuxer.
 */
@property (nonatomic, copy, readonly) NSURL *URL;

@end
