//
//  SGFrame+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrame.h"
#import "SGAudioFrame.h"
#import "SGVideoFrame.h"
#import "SGCodecDescriptor.h"

@interface SGFrame ()

/**
 *
 */
+ (instancetype)frame;

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
- (void)fillWithFrame:(SGFrame *)frame;

/**
 *
 */
- (void)fillWithTimeStamp:(CMTime)timeStamp decodeTimeStamp:(CMTime)decodeTimeStamp duration:(CMTime)duration;

@end

@interface SGAudioFrame ()

/**
 *
 */
+ (instancetype)frameWithDescriptor:(SGAudioDescriptor *)descriptor numberOfSamples:(int)numberOfSamples;

@end

@interface SGVideoFrame ()

/**
 *
 */
+ (instancetype)frameWithDescriptor:(SGVideoDescriptor *)descriptor;

@end
