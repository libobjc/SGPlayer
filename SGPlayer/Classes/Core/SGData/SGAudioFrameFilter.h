//
//  SGAudioFrameFilter.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/30.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrameFilter.h"

@interface SGAudioFrameFilter : SGFrameFilter

@property (nonatomic, assign) int format;         // AVSampleFormat
@property (nonatomic, assign) int sample_rate;
@property (nonatomic, assign) int channels;
@property (nonatomic, assign) uint64_t channel_layout;

@end
