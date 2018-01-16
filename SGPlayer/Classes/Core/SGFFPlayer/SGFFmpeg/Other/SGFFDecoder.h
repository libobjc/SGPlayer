//
//  SGFFDecoder.h
//  SGPlayer
//
//  Created by Single on 05/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "SGFFAudioFrame.h"
#import "SGFFVideoFrame.h"
#import "SGFFTrack.h"

@class SGFFDecoder;


@protocol SGFFDecoderDelegate <NSObject>

@optional

- (void)decoderWillOpenInputStream:(SGFFDecoder *)decoder;      // open input stream
- (void)decoderDidPrepareToDecodeFrames:(SGFFDecoder *)decoder;     // prepare decode frames
- (void)decoderDidEndOfFile:(SGFFDecoder *)decoder;     // end of file
- (void)decoderDidPlaybackFinished:(SGFFDecoder *)decoder;
- (void)decoder:(SGFFDecoder *)decoder didError:(NSError *)error;       // error callback

// value change
- (void)decoder:(SGFFDecoder *)decoder didChangeValueOfBuffering:(BOOL)buffering;
- (void)decoder:(SGFFDecoder *)decoder didChangeValueOfBufferedDuration:(NSTimeInterval)bufferedDuration;
- (void)decoder:(SGFFDecoder *)decoder didChangeValueOfProgress:(NSTimeInterval)progress;

@end


@protocol SGFFDecoderAudioOutput <NSObject>

- (SGFFAudioFrame *)decoderAudioOutputGetAudioFrame;

@end

@protocol SGFFDecoderAudioOutputConfig <NSObject>

- (Float64)decoderAudioOutputConfigGetSamplingRate;
- (UInt32)decoderAudioOutputConfigGetNumberOfChannels;

@end


@protocol SGFFDecoderVideoOutput <NSObject>

- (SGFFVideoFrame *)decoderVideoOutputGetVideoFrameWithCurrentPostion:(NSTimeInterval)currentPostion
                                                      currentDuration:(NSTimeInterval)currentDuration;

@end

@protocol SGFFDecoderVideoOutputConfig <NSObject>

- (void)decoderVideoOutputConfigDidUpdateMaxPreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond;
- (BOOL)decoderVideoOutputConfigAVCodecContextDecodeAsync;

@end


@interface SGFFDecoder : NSObject <SGFFDecoderAudioOutput, SGFFDecoderVideoOutput>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)decoderWithContentURL:(NSURL *)contentURL
                             delegate:(id <SGFFDecoderDelegate>)delegate
                    videoOutputConfig:(id <SGFFDecoderVideoOutputConfig>)videoOutputConfig
                    audioOutputConfig:(id <SGFFDecoderAudioOutputConfig>)audioOutputConfig;

@property (nonatomic, strong, readonly) NSError * error;

@property (nonatomic, copy, readonly) NSURL * contentURL;

@property (nonatomic, copy, readonly) NSDictionary * metadata;
@property (nonatomic, assign, readonly) CGSize presentationSize;
@property (nonatomic, assign, readonly) CGFloat aspect;
@property (nonatomic, assign, readonly) NSTimeInterval bitrate;
@property (nonatomic, assign, readonly) NSTimeInterval progress;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSTimeInterval bufferedDuration;

@property (nonatomic, assign) NSTimeInterval minBufferedDruation;
@property (nonatomic, assign) BOOL hardwareAccelerateEnable;       // default is YES;

@property (nonatomic, assign, readonly) BOOL buffering;

@property (nonatomic, assign, readonly) BOOL playbackFinished;
@property (atomic, assign, readonly) BOOL closed;
@property (atomic, assign, readonly) BOOL endOfFile;
@property (atomic, assign, readonly) BOOL paused;
@property (atomic, assign, readonly) BOOL seeking;
@property (atomic, assign, readonly) BOOL reading;
@property (atomic, assign, readonly) BOOL prepareToDecode;

@property (nonatomic, assign, readonly) BOOL videoDecodeOnMainThread;

@property (nonatomic, strong) NSDictionary * formatContextOptions;
@property (nonatomic, strong) NSDictionary * codecContextOptions;

- (void)pause;
- (void)resume;

@property (nonatomic, assign, readonly) BOOL seekEnable;
- (void)seekToTime:(NSTimeInterval)time;
- (void)seekToTime:(NSTimeInterval)time completeHandler:(void (^)(BOOL finished))completeHandler;

- (void)open;
- (void)closeFile;      // when release of active calls, or when called in dealloc might block the thread


#pragma mark - track info

@property (nonatomic, assign, readonly) BOOL videoEnable;
@property (nonatomic, assign, readonly) BOOL audioEnable;

@property (nonatomic, strong, readonly) SGFFTrack * videoTrack;
@property (nonatomic, strong, readonly) SGFFTrack * audioTrack;

@property (nonatomic, strong, readonly) NSArray <SGFFTrack *> * videoTracks;
@property (nonatomic, strong, readonly) NSArray <SGFFTrack *> * audioTracks;

- (void)selectAudioTrackIndex:(int)audioTrackIndex;

@end
