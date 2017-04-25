//
//  SGFFVideoDecoder.m
//  SGPlayer
//
//  Created by Single on 2017/2/17.
//  Copyright © 2017年 single. All rights reserved.
//

#import <SGPlatform/SGPlatform.h>
#import "SGFFVideoDecoder.h"
#import "SGFFPacketQueue.h"
#import "SGFFFrameQueue.h"
#import "SGFFFramePool.h"
#import "SGFFTools.h"

#if SGPLATFORM_TARGET_OS_IPHONE
#import "SGFFVideoToolBox.h"
#endif

static AVPacket flush_packet;

@interface SGFFVideoDecoder ()

{
    AVCodecContext * _codec_context;
    AVFrame * _temp_frame;
}

@property (nonatomic, assign) NSInteger preferredFramesPerSecond;

@property (nonatomic, assign) BOOL canceled;

@property (nonatomic, strong) SGFFPacketQueue * packetQueue;
@property (nonatomic, strong) SGFFFrameQueue * frameQueue;

@property (nonatomic, strong) SGFFFramePool * framePool;

#if SGPLATFORM_TARGET_OS_IPHONE
@property (nonatomic, strong) SGFFVideoToolBox * videoToolBox;
#endif

@end

@implementation SGFFVideoDecoder

+ (instancetype)decoderWithCodecContext:(AVCodecContext *)codec_context
                               timebase:(NSTimeInterval)timebase
                                    fps:(NSTimeInterval)fps
                      codecContextAsync:(BOOL)codecContextAsync
                     videoToolBoxEnable:(BOOL)videoToolBoxEnable
                             rotateType:(SGFFVideoFrameRotateType)rotateType
                               delegate:(id<SGFFVideoDecoderDlegate>)delegate
{
    return [[self alloc] initWithCodecContext:codec_context
                                     timebase:timebase
                                          fps:fps
                            codecContextAsync:codecContextAsync
                           videoToolBoxEnable:videoToolBoxEnable
                                   rotateType:rotateType
                                     delegate:delegate];
}

- (instancetype)initWithCodecContext:(AVCodecContext *)codec_context
                            timebase:(NSTimeInterval)timebase
                                 fps:(NSTimeInterval)fps
                   codecContextAsync:(BOOL)codecContextAsync
                  videoToolBoxEnable:(BOOL)videoToolBoxEnable
                          rotateType:(SGFFVideoFrameRotateType)rotateType
                            delegate:(id<SGFFVideoDecoderDlegate>)delegate
{
    if (self = [super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            av_init_packet(&flush_packet);
            flush_packet.data = (uint8_t *)&flush_packet;
            flush_packet.duration = 0;
        });
        self.delegate = delegate;
        self->_codec_context = codec_context;
        self->_timebase = timebase;
        self->_fps = fps;
        self->_codecContextAsync = codecContextAsync;
        self->_videoToolBoxEnable = videoToolBoxEnable;
        self->_rotateType = rotateType;
        [self setupCodecContext];
    }
    return self;
}

- (void)setupCodecContext
{
    self.preferredFramesPerSecond = 60;
    self->_temp_frame = av_frame_alloc();
    self.packetQueue = [SGFFPacketQueue packetQueueWithTimebase:self.timebase];
    self.videoToolBoxMaxDecodeFrameCount = 20;
    self.codecContextMaxDecodeFrameCount = 3;
#if SGPLATFORM_TARGET_OS_IPHONE
    if (self.videoToolBoxEnable && _codec_context->codec_id == AV_CODEC_ID_H264) {
        self.videoToolBox = [SGFFVideoToolBox videoToolBoxWithCodecContext:self->_codec_context];
        if ([self.videoToolBox trySetupVTSession]) {
            self->_videoToolBoxDidOpen = YES;
        } else {
            [self.videoToolBox flush];
            self.videoToolBox = nil;
        }
    }
#endif
    if (self.videoToolBoxDidOpen) {
        self.frameQueue = [SGFFFrameQueue frameQueue];
        self.frameQueue.minFrameCountForGet = 4;
        self->_decodeAsync = YES;
    } else if (self.codecContextAsync) {
        self.frameQueue = [SGFFFrameQueue frameQueue];
        self.framePool = [SGFFFramePool videoPool];
        self->_decodeAsync = YES;
    } else {
        self.framePool = [SGFFFramePool videoPool];
        self->_decodeSync = YES;
        self->_decodeOnMainThread = YES;
    }
}

- (SGFFVideoFrame *)getFrameAsync
{
    if (self.videoToolBoxDidOpen || self.codecContextAsync) {
        return [self.frameQueue getFrameAsync];
    } else {
        return [self codecContextDecodeSync];
    }
}

- (SGFFVideoFrame *)getFrameAsyncPosistion:(NSTimeInterval)position
{
    if (self.videoToolBoxDidOpen || self.codecContextAsync) {
        NSMutableArray <SGFFFrame *> * discardFrames = nil;
        SGFFVideoFrame * videoFrame = [self.frameQueue getFrameAsyncPosistion:position discardFrames:&discardFrames];
        for (SGFFVideoFrame * obj in discardFrames) {
            [obj cancel];
        }
        return videoFrame;
    } else {
        return [self codecContextDecodeSync];
    }
}

- (void)discardFrameBeforPosition:(NSTimeInterval)position
{
    if (self.videoToolBoxDidOpen || self.codecContextAsync) {
        NSMutableArray <SGFFFrame *> * discardFrames = [self.frameQueue discardFrameBeforPosition:position];
        for (SGFFVideoFrame * obj in discardFrames) {
            [obj cancel];
        }
    }
}

- (void)putPacket:(AVPacket)packet
{
    NSTimeInterval duration = 0;
    if (packet.duration <= 0 && packet.size > 0 && packet.data != flush_packet.data) {
        duration = 1.0 / self.fps;
    }
    [self.packetQueue putPacket:packet duration:duration];
}


#pragma mark - start decode thread

- (void)startDecodeThread
{
    if (self.videoToolBoxDidOpen) {
        [self videoToolBoxDecodeAsyncThread];
    } else if (self.codecContextAsync) {
        [self codecContextDecodeAsyncThread];
    }
}


#pragma mark - FFmpeg

- (void)codecContextDecodeAsyncThread
{
    while (YES) {
        if (!self.codecContextAsync) {
            break;
        }
        if (self.canceled || self.error) {
            SGFFThreadLog(@"decode video thread quit");
            break;
        }
        if (self.endOfFile && self.packetQueue.count <= 0) {
            SGFFThreadLog(@"decode video finished");
            break;
        }
        if (self.paused) {
            SGFFSleepLog(@"decode video thread pause sleep");
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        if (self.frameQueue.count >= self.codecContextMaxDecodeFrameCount) {
            SGFFSleepLog(@"decode video thread sleep");
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        
        AVPacket packet = [self.packetQueue getPacketSync];
        if (packet.data == flush_packet.data) {
            SGFFDecodeLog(@"video codec flush");
            avcodec_flush_buffers(_codec_context);
            [self.frameQueue flush];
            continue;
        }
        if (packet.stream_index < 0 || packet.data == NULL) continue;
        
        SGFFVideoFrame * videoFrame = nil;
        int result = avcodec_send_packet(_codec_context, &packet);
        if (result < 0) {
            if (result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
                self->_error = SGFFCheckError(result);
                [self delegateErrorCallback];
            }
        } else {
            while (result >= 0) {
                result = avcodec_receive_frame(_codec_context, _temp_frame);
                if (result < 0) {
                    if (result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
                        self->_error = SGFFCheckError(result);
                        [self delegateErrorCallback];
                    }
                } else {
                    videoFrame = [self videoFrameFromTempFrame:packet.size];
                    if (videoFrame) {
                        [self.frameQueue putSortFrame:videoFrame];
                    }
                }
            }
        }
        av_packet_unref(&packet);
    }
}

- (SGFFVideoFrame *)codecContextDecodeSync
{
    if (self.canceled || self.error) {
        return nil;
    }
    if (self.paused) {
        return nil;
    }
    if (self.endOfFile && self.packetQueue.count <= 0) {
        return nil;
    }
    
    AVPacket packet = [self.packetQueue getPacketAsync];
    if (packet.data == flush_packet.data) {
        avcodec_flush_buffers(_codec_context);
        return nil;
    }
    if (packet.stream_index < 0 || packet.data == NULL) {
        return nil;
    }

    SGFFVideoFrame * videoFrame = nil;
    int result = avcodec_send_packet(_codec_context, &packet);
    if (result < 0) {
        if (result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
            self->_error = SGFFCheckError(result);
            [self delegateErrorCallback];
        }
    } else {
        while (result >= 0) {
            result = avcodec_receive_frame(_codec_context, _temp_frame);
            if (result < 0) {
                if (result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
                    self->_error = SGFFCheckError(result);
                    [self delegateErrorCallback];
                }
            } else {
                videoFrame = [self videoFrameFromTempFrame:packet.size];
            }
        }
    }
    av_packet_unref(&packet);
    return videoFrame;
}

- (SGFFAVYUVVideoFrame *)videoFrameFromTempFrame:(int)packetSize
{
    if (!_temp_frame->data[0] || !_temp_frame->data[1] || !_temp_frame->data[2]) return nil;
    
    SGFFAVYUVVideoFrame * videoFrame = [self.framePool getUnuseFrame];
    videoFrame.rotateType = self.rotateType;
    
    [videoFrame setFrameData:_temp_frame width:_codec_context->width height:_codec_context->height];
    videoFrame.position = av_frame_get_best_effort_timestamp(_temp_frame) * self.timebase;
    videoFrame.packetSize = packetSize;
    
    const int64_t frame_duration = av_frame_get_pkt_duration(_temp_frame);
    if (frame_duration) {
        videoFrame.duration = frame_duration * self.timebase;
        videoFrame.duration += _temp_frame->repeat_pict * self.timebase * 0.5;
    } else {
        videoFrame.duration = 1.0 / self.fps;
    }
    return videoFrame;
}


#pragma mark - VideoToolBox

- (void)videoToolBoxDecodeAsyncThread
{
#if SGPLATFORM_TARGET_OS_IPHONE
    
    while (YES) {
        if (!self.videoToolBoxDidOpen) {
            break;
        }
        if (self.canceled || self.error) {
            SGFFThreadLog(@"decode video thread quit");
            break;
        }
        if (self.endOfFile && self.packetQueue.count <= 0) {
            SGFFThreadLog(@"decode video finished");
            break;
        }
        if (self.paused) {
            SGFFSleepLog(@"decode video thread pause sleep");
            [NSThread sleepForTimeInterval:0.01];
            continue;
        }
        if (self.frameQueue.count >= self.videoToolBoxMaxDecodeFrameCount) {
            SGFFSleepLog(@"decode video thread sleep");
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        
        AVPacket packet = [self.packetQueue getPacketSync];
        if (packet.data == flush_packet.data) {
            SGFFDecodeLog(@"video codec flush");
            [self.frameQueue flush];
            [self.videoToolBox flush];
            continue;
        }
        if (packet.stream_index < 0 || packet.data == NULL) continue;
        
        SGFFVideoFrame * videoFrame = nil;
        BOOL vtbEnable = [self.videoToolBox trySetupVTSession];
        if (vtbEnable) {
            BOOL needFlush = NO;
            BOOL result = [self.videoToolBox sendPacket:packet needFlush:&needFlush];
            if (result) {
                videoFrame = [self videoFrameFromVideoToolBox:packet];
            } else if (needFlush) {
                [self.videoToolBox flush];
                BOOL result2 = [self.videoToolBox sendPacket:packet needFlush:&needFlush];
                if (result2) {
                    videoFrame = [self videoFrameFromVideoToolBox:packet];
                }
            }
        }
        if (videoFrame) {
            [self.frameQueue putSortFrame:videoFrame];
        }
        av_packet_unref(&packet);
    }
    self.frameQueue.ignoreMinFrameCountForGetLimit = YES;
}

- (SGFFVideoFrame *)videoFrameFromVideoToolBox:(AVPacket)packet
{
    CVImageBufferRef imageBuffer = [self.videoToolBox imageBuffer];
    if (imageBuffer == NULL) return nil;
    
    SGFFCVYUVVideoFrame * videoFrame = [[SGFFCVYUVVideoFrame alloc] initWithAVPixelBuffer:imageBuffer];
    videoFrame.rotateType = self.rotateType;
    
    if (packet.pts != AV_NOPTS_VALUE) {
        videoFrame.position = packet.pts * self.timebase;
    } else {
        videoFrame.position = packet.dts;
    }
    videoFrame.packetSize = packet.size;
    
    const int64_t frame_duration = packet.duration;
    if (frame_duration) {
        videoFrame.duration = frame_duration * self.timebase;
    } else {
        videoFrame.duration = 1.0 / self.fps;
    }
    return videoFrame;
    
#endif
}

- (void)setPreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond
{
    if (_preferredFramesPerSecond != preferredFramesPerSecond) {
        _preferredFramesPerSecond = preferredFramesPerSecond;
        [self.delegate videoDecoder:self didChangePreferredFramesPerSecond:_preferredFramesPerSecond];
    }
}

- (int)size
{
    if (self.videoToolBoxDidOpen || self.codecContextAsync) {
        return self.packetQueue.size + self.frameQueue.packetSize;
    } else {
        return self.packetQueue.size;
    }
}

- (BOOL)empty
{
    if (self.videoToolBoxDidOpen || self.codecContextAsync) {
        return self.packetQueue.count <= 0 && self.frameQueue.count <= 0;
    } else {
        return self.packetQueue.count <= 0;
    }
}

- (NSTimeInterval)duration
{
    if (self.videoToolBoxDidOpen || self.codecContextAsync) {
        return self.packetQueue.duration + self.frameQueue.duration;
    } else {
        return self.packetQueue.duration;
    }
}

- (void)delegateErrorCallback
{
    if (self.error) {
        [self.delegate videoDecoder:self didError:self.error];
    }
}

- (void)flush
{
    [self.packetQueue flush];
    [self.frameQueue flush];
    [self.framePool flush];
    [self putPacket:flush_packet];
}

- (void)destroy
{
    self.canceled = YES;
    
    [self.frameQueue destroy];
    [self.packetQueue destroy];
    [self.framePool flush];
}

- (void)dealloc
{
    if (_temp_frame) {
        av_free(_temp_frame);
        _temp_frame = NULL;
    }
    SGPlayerLog(@"SGFFVideoDecoder release");
}

@end
