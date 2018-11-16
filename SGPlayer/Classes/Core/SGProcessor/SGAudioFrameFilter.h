//
//  SGAudioFrameFilter.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/30.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrameFilter.h"

@interface SGAudioFrameFilter : SGFrameFilter

@property (nonatomic) int format;         // AVSampleFormat
@property (nonatomic) int sample_rate;
@property (nonatomic) int channels;
@property (nonatomic) uint64_t channel_layout;

@end
