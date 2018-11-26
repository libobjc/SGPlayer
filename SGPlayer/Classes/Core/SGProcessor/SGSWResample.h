//
//  SGSWResample.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/30.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGSWResample : NSObject

@property (nonatomic) SInt32 i_format;         // AVSampleFormat
@property (nonatomic) SInt32 i_sample_rate;
@property (nonatomic) SInt32 i_channels;
@property (nonatomic) UInt64 i_channel_layout;

@property (nonatomic) SInt32 o_format;         // AVSampleFormat
@property (nonatomic) SInt32 o_sample_rate;
@property (nonatomic) SInt32 o_channels;
@property (nonatomic) UInt64 o_channel_layout;

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (SInt32)convert:(UInt8 **)data nb_samples:(SInt32)nb_samples;

/**
 *
 */
- (SInt32)copy:(UInt8 *)data linesize:(SInt32)linesize planar:(SInt32)planar;

@end
