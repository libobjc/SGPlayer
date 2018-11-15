//
//  SGFrame+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrame.h"
#import "SGTimeTransform.h"
#import "frame.h"

@interface SGFrame (Internal)

@property (nonatomic, readonly) AVFrame * core;
@property (nonatomic, readonly) AVRational timebase;
@property (nonatomic, strong, readonly) NSArray <SGTimeTransform *> * timeTransforms;

- (void)configurateWithType:(SGMediaType)type timebase:(AVRational)timebase index:(int32_t)index;

- (void)applyTimeTransforms:(NSArray <SGTimeTransform *> *)timeTransforms;
- (void)applyTimeTransform:(SGTimeTransform *)timeTransform;

@end
