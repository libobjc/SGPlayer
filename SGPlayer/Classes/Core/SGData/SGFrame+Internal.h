//
//  SGFrame+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrame.h"
#import "SGCodecpar.h"

@interface SGFrame (Internal)

@property (nonatomic, readonly) AVFrame * core;
@property (nonatomic, readonly, copy) SGCodecpar * codecpar;

- (void)setTimebase:(AVRational)timebase codecpar:(AVCodecParameters *)codecpar;
- (void)setTimeLayout:(SGTimeLayout *)timeLayout;

@end
