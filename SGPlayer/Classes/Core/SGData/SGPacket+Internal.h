//
//  SGPacket+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPacket.h"
#import "SGCodecDescription.h"

@interface SGPacket ()

/**
 *
 */
@property (nonatomic, assign, readonly) AVPacket * _Nonnull core;

/**
 *
 */
@property (nonatomic, copy) SGCodecDescription * _Nullable codecDescription;

/**
 *
 */
- (void)fill;

@end
