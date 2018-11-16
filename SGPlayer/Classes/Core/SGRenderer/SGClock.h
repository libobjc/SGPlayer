//
//  SGClock.h
//  SGPlayer
//
//  Created by Single on 2018/6/14.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTime.h"

@interface SGClock : NSObject

@property (nonatomic) CMTime videoAdvancedDuration;        // [-2, 2];

@end
