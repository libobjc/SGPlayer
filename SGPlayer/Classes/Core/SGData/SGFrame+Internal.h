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
@property (nonatomic, readonly) AVFrame * _Nonnull core;

/**
 *
 */
@property (nonatomic, strong) SGCodecDescription * _Nullable codecDescription;

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
+ (instancetype _Nonnull)audioFrameWithDescription:(SGAudioDescription * _Nonnull)description numberOfSamples:(int)numberOfSamples;

@end
