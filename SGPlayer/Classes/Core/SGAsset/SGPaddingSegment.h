//
//  SGPaddingSegment.h
//  SGPlayer
//
//  Created by Single on 2019/6/4.
//  Copyright © 2019 single. All rights reserved.
//

#import "SGSegment.h"

@interface SGPaddingSegment : SGSegment

/*!
 @method initWithDuration:
 @abstract
    Initializes an SGPaddingSegment.
 */
- (instancetype)initWithDuration:(CMTime)duration;

@end
