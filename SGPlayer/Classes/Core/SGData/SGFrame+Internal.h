//
//  SGFrame+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrame.h"
#import "SGAudioFrame.h"
#import "SGCodecDescription.h"

@interface SGFrame ()

/**
 *
 */
@property (nonatomic, readonly) AVFrame *core;

/**
 *
 */
@property (nonatomic, strong) SGCodecDescription *codecDescription;

/**
 *
 */
- (void)fill;

/**
 *
 */
- (void)fillWithDuration:(CMTime)duration timeStamp:(CMTime)timeStamp decodeTimeStamp:(CMTime)decodeTimeStamp;

@end

@interface SGAudioFrame ()

/**
 *
 */
+ (instancetype)audioFrameWithDescription:(SGAudioDescription *)description numberOfSamples:(int)numberOfSamples;

@end
