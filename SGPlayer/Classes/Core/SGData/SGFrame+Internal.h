//
//  SGFrame+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrame.h"
#import "SGAudioFrame.h"
#import "SGCodecDescriptor.h"

@interface SGFrame ()

/**
 *
 */
@property (nonatomic, readonly) AVFrame *core;

/**
 *
 */
@property (nonatomic, strong) SGCodecDescriptor *codecDescriptor;

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
+ (instancetype)audioFrameWithDescriptor:(SGAudioDescriptor *)descriptor numberOfSamples:(int)numberOfSamples;

@end
