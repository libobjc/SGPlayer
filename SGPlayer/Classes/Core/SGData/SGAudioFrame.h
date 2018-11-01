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

@property (nonatomic, assign, readonly) int format;         // AVSampleFormat
@property (nonatomic, assign, readonly) int is_planar;
@property (nonatomic, assign, readonly) int nb_samples;
@property (nonatomic, assign, readonly) int sample_rate;
@property (nonatomic, assign, readonly) int channels;
@property (nonatomic, assign, readonly) uint64_t channel_layout;

@end
