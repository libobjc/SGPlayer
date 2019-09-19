//
//  SGAsset+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/9/25.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAsset.h"
#import "SGDemuxable.h"

@interface SGAsset ()

/*!
 @method newDemuxable
 @abstract
    Create a new demuxer.
 */
- (id<SGDemuxable>)newDemuxable;

@end
