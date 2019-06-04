//
//  SGPaddingSegment.h
//  SGPlayer
//
//  Created by Single on 2019/6/4.
//  Copyright © 2019 single. All rights reserved.
//

#import "SGSegment.h"

NS_ASSUME_NONNULL_BEGIN

@interface SGPaddingSegment : SGSegment

/**
 *
 */
- (instancetype)initWithDuration:(CMTime)duration;

@end

NS_ASSUME_NONNULL_END
