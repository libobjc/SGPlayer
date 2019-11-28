//
//  SGDecoderOptions.h
//  SGPlayer
//
//  Created by Single on 2019/6/14.
//  Copyright © 2019 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGAudioDescriptor.h"
#import "SGTime.h"

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

/*!
 @property supportedPixelFormats
 @abstract
    Indicates the supported pixel formats.
 */
@property (nonatomic, copy) NSArray<NSNumber *> *supportedPixelFormats;

/*!
 @property supportedAudioDescriptors
 @abstract
    Indicates the supported audio descriptors.
 */
@property (nonatomic, copy) NSArray<SGAudioDescriptor *> *supportedAudioDescriptors;

/*!
 @property resetFrameRate
 @abstract
    Indicates whether video decoder needs reset frame rate.
    Default is NO.
 */
@property (nonatomic) BOOL resetFrameRate;

/*!
 @property preferredFrameRate
 @abstract
    Indicates the preferred video track frame rate.
    Default is (1, 25).
 */
@property (nonatomic) CMTime preferredFrameRate;

@end
