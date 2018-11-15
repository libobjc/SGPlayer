//
//  SGPacket+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPacket.h"
#import "SGCodecpar.h"

@interface SGPacket (Internal)

@property (nonatomic, readonly) AVPacket * core;
@property (nonatomic, readonly, copy) SGCodecpar * codecpar;

- (void)setTimebase:(AVRational)timebase codecpar:(AVCodecParameters *)codecpar;
- (void)setTimeLayout:(SGTimeLayout *)timeLayout;

@end
