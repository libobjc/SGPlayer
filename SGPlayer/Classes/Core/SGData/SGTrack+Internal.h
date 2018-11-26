//
//  SGTrack+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGTrack.h"

@interface SGTrack ()

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithType:(SGMediaType)type index:(int)index NS_DESIGNATED_INITIALIZER;

@end
