//
//  SGAudioFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFrame.h"

@interface SGAudioFrame : SGFrame

{
@public
    uint8_t * _data[SGFramePlaneCount];
    int _linesize[SGFramePlaneCount];
}

@property (nonatomic, readonly) int format;         // AVSampleFormat
@property (nonatomic, readonly) int is_planar;
@property (nonatomic, readonly) int nb_samples;
@property (nonatomic, readonly) int sample_rate;
@property (nonatomic, readonly) int channels;
@property (nonatomic, readonly) uint64_t channel_layout;

@end
