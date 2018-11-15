//
//  SGTimeLayout.h
//  SGPlayer
//
//  Created by Single on 2018/11/15.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTime.h"

@interface SGTimeLayout : NSObject <NSCopying>

- (instancetype)initWithStart:(CMTime)start scale:(CMTime)scale;

@property (nonatomic, readonly) CMTime start;
@property (nonatomic, readonly) CMTime scale;

- (BOOL)isEqualToTimeLayout:(SGTimeLayout *)timeLayout;

- (CMTime)applyToTimeStamp:(CMTime)timeStamp;
- (CMTime)applyToDuration:(CMTime)duration;

@end
