//
//  SGPlayerDecoder.h
//  SGPlayer
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>

// decode type
typedef NS_ENUM(NSUInteger, SGDecoderType) {
    SGDecoderTypeError,
    SGDecoderTypeAVPlayer,
    SGDecoderTypeFFmpeg,
};

// video format
typedef NS_ENUM(NSUInteger, SGVideoFormat) {
    SGVideoFormatError,
    SGVideoFormatUnknown,
    SGVideoFormatMPEG4,
    SGVideoFormatFLV,
    SGVideoFormatM3U8,
    SGVideoFormatRTMP,
    SGVideoFormatRTSP,
};

@interface SGPlayerDecoder : NSObject

+ (instancetype)defaultDecoder;
+ (instancetype)AVPlayerDecoder;
+ (instancetype)FFmpegDecoder;

- (SGVideoFormat)formatForContentURL:(NSURL *)contentURL;
- (SGDecoderType)decoderTypeForContentURL:(NSURL *)contentURL;

@property (nonatomic, assign) BOOL ffmpegHardwareDecoderEnable; // default is YES

@property (nonatomic, assign) SGDecoderType unkonwnFormat;      // default is SGDecodeTypeFFmpeg
@property (nonatomic, assign) SGDecoderType mpeg4Format;        // default is SGDecodeTypeAVPlayer
@property (nonatomic, assign) SGDecoderType flvFormat;          // default is SGDecodeTypeFFmpeg
@property (nonatomic, assign) SGDecoderType m3u8Format;         // default is SGDecodeTypeAVPlayer
@property (nonatomic, assign) SGDecoderType rtmpFormat;         // default is SGDecodeTypeFFmpeg
@property (nonatomic, assign) SGDecoderType rtspFormat;         // default is SGDecodeTypeFFmpeg

@end
