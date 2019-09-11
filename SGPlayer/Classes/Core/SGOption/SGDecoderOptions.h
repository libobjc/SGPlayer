//
//  SGDecoderOptions.h
//  SGPlayer
//
//  Created by Single on 2019/6/14.
//  Copyright © 2019 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGDecoderOptions : NSObject <NSCopying>

/*!
 @property options
 @abstract
    The options for avformat_open_input.
    Default is nil.
 */
@property (nonatomic, copy) NSDictionary *options;

/*!
 @property threadsAuto
 @abstract
    The option for avformat_open_input.
    Default is YES.
 */
@property (nonatomic) BOOL threadsAuto;

/*!
 @property refcountedFrames
 @abstract
    The option for avformat_open_input.
    Default is YES.
 */
@property (nonatomic) BOOL refcountedFrames;

/*!
 @property hardwareDecodeH264
 @abstract
    Indicates whether hardware decoding is enabled for H264.
    Default is YES.
 */
@property (nonatomic) BOOL hardwareDecodeH264;

/*!
 @property hardwareDecodeH265
 @abstract
    Indicates whether hardware decoding is enabled for H265.
    Default is YES.
 */
@property (nonatomic) BOOL hardwareDecodeH265;

/*!
 @property preferredPixelFormat
 @abstract
    Indicates the default hardware decoding output format.
    Default is kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange.
 */
@property (nonatomic) OSType preferredPixelFormat;

@end
