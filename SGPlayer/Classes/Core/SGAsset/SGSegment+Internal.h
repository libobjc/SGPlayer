//
//  SGSegment+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/9/25.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGSegment.h"
#import "SGDemuxable.h"

@interface SGSegment ()

/**
 *
 */
- (id<SGDemuxable>)newDemuxable;

@end
