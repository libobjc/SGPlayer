//
//  SGCommonSource.h
//  SGPlayer
//
//  Created by Single on 2017/2/17.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "SGVideoFrame2.h"
#import "SGFFTrack.h"

@class SGFFFormatContext2;

@protocol SGFFFormatContext2Delegate <NSObject>

- (BOOL)formatContext2NeedInterrupt:(SGFFFormatContext2 *)formatContext;

@end

@interface SGFFFormatContext2 : NSObject

{
@public
    AVFormatContext * _format_context;
    AVCodecContext * _video_codec_context;
    AVCodecContext * _audio_codec_context;
}

+ (instancetype)formatContextWithContentURL:(NSURL *)contentURL delegate:(id <SGFFFormatContext2Delegate>)delegate;

@property (nonatomic, weak) id <SGFFFormatContext2Delegate> delegate;

@property (nonatomic, copy, readonly) NSError * error;

@property (nonatomic, copy, readonly) NSDictionary * metadata;
@property (nonatomic, assign, readonly) NSTimeInterval bitrate;
@property (nonatomic, assign, readonly) NSTimeInterval duration;

@property (nonatomic, assign, readonly) BOOL videoEnable;
@property (nonatomic, assign, readonly) BOOL audioEnable;

@property (nonatomic, strong, readonly) SGFFTrack * videoTrack;
@property (nonatomic, strong, readonly) SGFFTrack * audioTrack;

@property (nonatomic, strong, readonly) NSArray <SGFFTrack *> * videoTracks;
@property (nonatomic, strong, readonly) NSArray <SGFFTrack *> * audioTracks;

@property (nonatomic, assign, readonly) NSTimeInterval videoTimebase;
@property (nonatomic, assign, readonly) NSTimeInterval videoFPS;
@property (nonatomic, assign, readonly) CGSize videoPresentationSize;
@property (nonatomic, assign, readonly) CGFloat videoAspect;
@property (nonatomic, assign, readonly) SGVideoFrameRotateType videoFrameRotateType;

@property (nonatomic, assign, readonly) NSTimeInterval audioTimebase;

@property (nonatomic, strong) NSDictionary * formatContextOptions;
@property (nonatomic, strong) NSDictionary * codecContextOptions;

- (void)setupSync;
- (void)destroy;

- (BOOL)seekEnable;
- (void)seekFileWithFFTimebase:(NSTimeInterval)time;

- (int)readFrame:(AVPacket *)packet;

- (BOOL)containAudioTrack:(int)audioTrackIndex;
- (NSError *)selectAudioTrackIndex:(int)audioTrackIndex;

@end
