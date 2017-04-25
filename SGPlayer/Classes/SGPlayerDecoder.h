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

// media format
typedef NS_ENUM(NSUInteger, SGMediaFormat) {
    SGMediaFormatError,
    SGMediaFormatUnknown,
    SGMediaFormatMP3,
    SGMediaFormatMPEG4,
    SGMediaFormatMOV,
    SGMediaFormatFLV,
    SGMediaFormatM3U8,
    SGMediaFormatRTMP,
    SGMediaFormatRTSP,
};

@interface SGPlayerDecoder : NSObject

+ (instancetype)decoderByDefault;
+ (instancetype)decoderByAVPlayer;
+ (instancetype)decoderByFFmpeg;

@property (nonatomic, assign) BOOL hardwareAccelerateEnableForFFmpeg;  // default is YES

@property (nonatomic, assign) SGDecoderType decodeTypeForUnknown;      // default is SGDecodeTypeFFmpeg
@property (nonatomic, assign) SGDecoderType decodeTypeForMP3;          // default is SGDecodeTypeAVPlayer
@property (nonatomic, assign) SGDecoderType decodeTypeForMPEG4;        // default is SGDecodeTypeAVPlayer
@property (nonatomic, assign) SGDecoderType decodeTypeForMOV;          // default is SGDecodeTypeAVPlayer
@property (nonatomic, assign) SGDecoderType decodeTypeForFLV;          // default is SGDecodeTypeFFmpeg
@property (nonatomic, assign) SGDecoderType decodeTypeForM3U8;         // default is SGDecodeTypeAVPlayer
@property (nonatomic, assign) SGDecoderType decodeTypeForRTMP;         // default is SGDecodeTypeFFmpeg
@property (nonatomic, assign) SGDecoderType decodeTypeForRTSP;         // default is SGDecodeTypeFFmpeg

- (SGMediaFormat)mediaFormatForContentURL:(NSURL *)contentURL;
- (SGDecoderType)decoderTypeForContentURL:(NSURL *)contentURL;


#pragma mark - FFmpeg optioins

- (NSDictionary *)FFmpegFormatContextOptions;
- (void)setFFmpegFormatContextOptionIntValue:(int64_t)value forKey:(NSString *)key;
- (void)setFFmpegFormatContextOptionStringValue:(NSString *)value forKey:(NSString *)key;
- (void)removeFFmpegFormatContextOptionForKey:(NSString *)key;

- (NSDictionary *)FFmpegCodecContextOptions;
- (void)setFFmpegCodecContextOptionIntValue:(int64_t)value forKey:(NSString *)key;
- (void)setFFmpegCodecContextOptionStringValue:(NSString *)value forKey:(NSString *)key;
- (void)removeFFmpegCodecContextOptionForKey:(NSString *)key;

@end
