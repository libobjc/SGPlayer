//
//  SGClock.h
//  SGPlayer
//
//  Created by Single on 2018/6/14.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTime.h"

NS_ASSUME_NONNULL_BEGIN

@interface SGClock : NSObject

/**
 *  [-2, 2]
 */
@property (nonatomic) CMTime videoAdvancedDuration;

@end

NS_ASSUME_NONNULL_END
