//
//  SGPacket+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPacket.h"
#import "SGTimeTransform.h"
#import "avcodec.h"

@interface SGPacket (Internal)

@property (nonatomic, readonly) AVPacket * core;
@property (nonatomic, readonly) AVRational timebase;
@property (nonatomic, readonly) AVCodecParameters * codecpar;
@property (nonatomic, strong, readonly) NSArray <SGTimeTransform *> * timeTransforms;

- (void)configurateWithType:(SGMediaType)type timebase:(AVRational)timebase codecpar:(AVCodecParameters *)codecpar;

- (void)applyTimeTransforms:(NSArray <SGTimeTransform *> *)timeTransforms;
- (void)applyTimeTransform:(SGTimeTransform *)timeTransform;

@end
