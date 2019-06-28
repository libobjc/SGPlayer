//
//  SGPacket+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPacket.h"
#import "SGCodecDescriptor.h"

@interface SGPacket ()

/**
 *
 */
@property (nonatomic, readonly) AVPacket *core;

/**
 *
 */
@property (nonatomic, strong) SGCodecDescriptor *codecDescriptor;

/**
 *
 */
- (void)fill;

@end
