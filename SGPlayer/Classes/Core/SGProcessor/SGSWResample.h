//
//  SGSWResample.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/30.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGSWResample : NSObject

@property (nonatomic) int i_format;         // AVSampleFormat
@property (nonatomic) int i_sample_rate;
@property (nonatomic) int i_channels;
@property (nonatomic) uint64_t i_channel_layout;

@property (nonatomic) int o_format;         // AVSampleFormat
@property (nonatomic) int o_sample_rate;
@property (nonatomic) int o_channels;
@property (nonatomic) uint64_t o_channel_layout;

- (BOOL)open;

- (int)convert:(uint8_t **)data nb_samples:(int)nb_samples;
- (int)copy:(uint8_t *)data linesize:(int)linesize planar:(int)planar;

@end
