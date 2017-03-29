    //
//  SGFFDecoder.m
//  SGPlayer
//
//  Created by Single on 05/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFDecoder.h"
#import "SGFFFormatContext.h"
#import "SGFFAudioDecoder.h"
#import "SGFFVideoDecoder.h"
#import "SGFFTools.h"

@interface SGFFDecoder () <SGFFFormatContextDelegate, SGFFAudioDecoderDelegate, SGFFVideoDecoderDlegate>

@property (nonatomic, weak) id <SGFFDecoderDelegate> delegate;
@property (nonatomic, weak) id <SGFFDecoderVideoOutput> videoOutput;
@property (nonatomic, weak) id <SGFFDecoderAudioOutput> audioOutput;

@property (nonatomic, strong) NSOperationQueue * ffmpegOperationQueue;
@property (nonatomic, strong) NSInvocationOperation * openFileOperation;
@property (nonatomic, strong) NSInvocationOperation * readPacketOperation;
@property (nonatomic, strong) NSInvocationOperation * decodeFrameOperation;

@property (nonatomic, strong) SGFFFormatContext * formatContext;
@property (nonatomic, strong) SGFFAudioDecoder * audioDecoder;
@property (nonatomic, strong) SGFFVideoDecoder * videoDecoder;

@property (nonatomic, strong) NSError * error;

@property (nonatomic, copy) NSURL * contentURL;

@property (nonatomic, assign) NSTimeInterval progress;
@property (nonatomic, assign) NSTimeInterval bufferedDuration;

@property (nonatomic, assign) BOOL buffering;

@property (nonatomic, assign) BOOL playbackFinished;
@property (atomic, assign) BOOL closed;
@property (atomic, assign) BOOL endOfFile;
@property (atomic, assign) BOOL paused;
@property (atomic, assign) BOOL seeking;
@property (atomic, assign) BOOL reading;
@property (atomic, assign) BOOL prepareToDecode;

@property (nonatomic, assign) NSTimeInterval seekToTime;
@property (nonatomic, assign) NSTimeInterval seekMinTime;       // default is 0
@property (nonatomic, copy) void (^seekCompleteHandler)(BOOL finished);

@property (nonatomic, assign) BOOL selectAudioTrack;
@property (nonatomic, assign) BOOL selectAudioTrackIndex;

@property (nonatomic, strong) SGFFVideoFrame * currentVideoFrame;
@property (nonatomic, strong) SGFFAudioFrame * currentAudioFrame;

@property (atomic, assign) NSTimeInterval audioTimeClock;
@property (atomic, assign) NSTimeInterval videoTimeToken;
@property (atomic, assign) BOOL needUpdateVideo;

@end

@implementation SGFFDecoder

+ (instancetype)decoderWithContentURL:(NSURL *)contentURL delegate:(id<SGFFDecoderDelegate>)delegate videoOutput:(id<SGFFDecoderVideoOutput>)videoOutput audioOutput:(id<SGFFDecoderAudioOutput>)audioOutput
{
    return [[self alloc] initWithContentURL:contentURL delegate:delegate videoOutput:videoOutput audioOutput:audioOutput];
}

- (instancetype)initWithContentURL:(NSURL *)contentURL delegate:(id<SGFFDecoderDelegate>)delegate videoOutput:(id<SGFFDecoderVideoOutput>)videoOutput audioOutput:(id<SGFFDecoderAudioOutput>)audioOutput
{
    if (self = [super init]) {
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            av_log_set_callback(SGFFLog);
            av_register_all();
            avformat_network_init();
        });
        
        self.contentURL = contentURL;
        self.delegate = delegate;
        self.videoOutput = videoOutput;
        self.audioOutput = audioOutput;
        
        self.hardwareDecoderEnable = YES;
    }
    return self;
}

#pragma mark - setup operations

- (void)open
{
    [self setupOperationQueue];
}

- (void)setupOperationQueue
{
    self.ffmpegOperationQueue = [[NSOperationQueue alloc] init];
    self.ffmpegOperationQueue.maxConcurrentOperationCount = 2;
    self.ffmpegOperationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    
    [self setupOpenFileOperation];
}

- (void)setupOpenFileOperation
{
    self.openFileOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(openFormatContext) object:nil];
    self.openFileOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.openFileOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    [self.ffmpegOperationQueue addOperation:self.openFileOperation];
}

- (void)setupReadPacketOperation
{
    if (self.error) {
        [self delegateErrorCallback];
        return;
    }
    
    if (!self.readPacketOperation || self.readPacketOperation.isFinished) {
        self.readPacketOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(readPacketThread) object:nil];
        self.readPacketOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
        self.readPacketOperation.qualityOfService = NSQualityOfServiceUserInteractive;
        [self.readPacketOperation addDependency:self.openFileOperation];
        [self.ffmpegOperationQueue addOperation:self.readPacketOperation];
    }
    
    if (self.formatContext.videoEnable) {
        if (!self.decodeFrameOperation || self.decodeFrameOperation.isFinished) {
            self.decodeFrameOperation = [[NSInvocationOperation alloc] initWithTarget:self.videoDecoder selector:@selector(decodeFrameThread) object:nil];
            self.decodeFrameOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
            self.decodeFrameOperation.qualityOfService = NSQualityOfServiceUserInteractive;
            [self.decodeFrameOperation addDependency:self.openFileOperation];
            [self.ffmpegOperationQueue addOperation:self.decodeFrameOperation];
        }
    }
}

#pragma mark - open stream

- (void)openFormatContext
{
    if ([self.delegate respondsToSelector:@selector(decoderWillOpenInputStream:)]) {
        [self.delegate decoderWillOpenInputStream:self];
    }
    
    self.formatContext = [SGFFFormatContext formatContextWithContentURL:self.contentURL delegate:self];
    [self.formatContext setupSync];
    
    if (self.formatContext.error) {
        self.error = self.formatContext.error;
        [self delegateErrorCallback];
        return;
    }
    
    self.prepareToDecode = YES;
    if ([self.delegate respondsToSelector:@selector(decoderDidPrepareToDecodeFrames:)]) {
        [self.delegate decoderDidPrepareToDecodeFrames:self];
    }
    
    if (self.formatContext.videoEnable) {
        self.videoDecoder = [SGFFVideoDecoder decoderWithCodecContext:self.formatContext->_video_codec_context
                                                             timebase:self.formatContext.videoTimebase
                                                                  fps:self.formatContext.videoFPS
                                                             delegate:self];
        self.videoDecoder.videoToolBoxEnable = self.hardwareDecoderEnable;
    }
    if (self.formatContext.audioEnable) {
        self.audioDecoder = [SGFFAudioDecoder decoderWithCodecContext:self.formatContext->_audio_codec_context
                                                             timebase:self.formatContext.audioTimebase
                                                             delegate:self];
    }
    
    [self setupReadPacketOperation];
}


#pragma mark - operation thread

static int max_packet_buffer_size = 20 * 1024 * 1024;
static NSTimeInterval max_packet_buffer_time_interval = 10;
static NSTimeInterval max_packet_sleep_full_time_interval = 0.1;
static NSTimeInterval max_packet_sleep_full_and_pause_time_interval = 0.5;

- (void)readPacketThread
{
    [self.videoDecoder flush];
    [self.audioDecoder flush];
    
    self.reading = YES;
    BOOL finished = NO;
    AVPacket packet;
    while (!finished) {
        if (self.closed || self.error) {
            SGFFThreadLog(@"read packet thread quit");
            break;
        }
        if (self.seeking) {
            self.endOfFile = NO;
            self.playbackFinished = NO;

            [self.formatContext seekFileWithFFTimebase:self.seekToTime];
            
            self.buffering = YES;
            [self.audioDecoder flush];
            [self.videoDecoder flush];
            self.videoDecoder.paused = NO;
            self.videoDecoder.endOfFile = NO;
            self.seeking = NO;
            self.seekToTime = 0;
            if (self.seekCompleteHandler) {
                self.seekCompleteHandler(YES);
                self.seekCompleteHandler = nil;
            }
            self.audioTimeClock = self.progress;
            self.videoTimeToken = -1;
            self.currentVideoFrame = nil;
            self.currentAudioFrame = nil;
            self.needUpdateVideo = YES;
            [self updateBufferedDurationByVideo];
            [self updateBufferedDurationByAudio];
            continue;
        }
        if (self.selectAudioTrack) {
            NSError * selectResult = [self.formatContext selectAudioTrackIndex:self.selectAudioTrackIndex];
            if (!selectResult) {
                [self.audioDecoder destroy];
                self.audioDecoder = [SGFFAudioDecoder decoderWithCodecContext:self.formatContext->_audio_codec_context
                                                                     timebase:self.formatContext.audioTimebase
                                                                     delegate:self];
                if (!self.playbackFinished) {
                    [self seekToTime:self.audioTimeClock];
                }
            }
            self.selectAudioTrack = NO;
            self.selectAudioTrackIndex = 0;
            continue;
        }
        BOOL needSleep = NO;
        if (self.audioEnable) {
            needSleep = self.audioDecoder.duration >= max_packet_buffer_time_interval;
        } else {
            needSleep = self.videoDecoder.packetSize >= max_packet_buffer_size;
        }
        if (needSleep) {
            NSTimeInterval interval = 0;
            if (self.paused) {
                interval = max_packet_sleep_full_and_pause_time_interval;
            } else {
                interval = max_packet_sleep_full_time_interval;
            }
            SGFFSleepLog(@"read thread sleep : %f", interval);
            [NSThread sleepForTimeInterval:interval];
            continue;
        }
        
        // read frame
        int result = [self.formatContext readFrame:&packet];
        if (result < 0)
        {
            SGFFPacketLog(@"read packet finished");
            self.endOfFile = YES;
            self.videoDecoder.endOfFile = YES;
            finished = YES;
            if ([self.delegate respondsToSelector:@selector(decoderDidEndOfFile:)]) {
                [self.delegate decoderDidEndOfFile:self];
            }
            break;
        }
        if (packet.stream_index == self.formatContext.videoTrack.index)
        {
            SGFFPacketLog(@"video : put packet");
            [self.videoDecoder putPacket:packet];
            [self updateBufferedDurationByVideo];
        }
        else if (packet.stream_index == self.formatContext.audioTrack.index)
        {
            SGFFPacketLog(@"audio : put packet");
            int result = [self.audioDecoder putPacket:packet];
            if (result < 0) {
                self.error = SGFFCheckErrorCode(result, SGFFDecoderErrorCodeCodecAudioSendPacket);
                [self delegateErrorCallback];
                continue;
            }
            [self updateBufferedDurationByAudio];
        }
    }
    self.reading = NO;
    [self checkBufferingStatus];
}

- (void)pause
{
    self.paused = YES;
}

- (void)resume
{
    self.paused = NO;
    if (self.playbackFinished) {
        [self seekToTime:0];
    }
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completeHandler:nil];
}

- (void)seekToTime:(NSTimeInterval)time completeHandler:(void (^)(BOOL finished))completeHandler
{
    if (!self.seekEnable || self.error) {
        if (completeHandler) {
            completeHandler(NO);
        }
        return;
    }
    NSTimeInterval tempDuration = 8;
    if (!self.formatContext.audioEnable) {
        tempDuration = 15;
    }
    
    NSTimeInterval seekMaxTime = self.duration - (self.minBufferedDruation + tempDuration);
    if (seekMaxTime < self.seekMinTime) {
        seekMaxTime = self.seekMinTime;
    }
    if (time > seekMaxTime) {
        time = seekMaxTime;
    } else if (time < self.seekMinTime) {
        time = self.seekMinTime;
    }
    self.progress = time;
    self.seekToTime = time;
    self.seekCompleteHandler = completeHandler;
    self.seeking = YES;
    self.videoDecoder.paused = YES;
    
    if (self.endOfFile) {
        [self setupReadPacketOperation];
    }
}

- (SGFFAudioFrame *)fetchAudioFrame
{
    BOOL check = self.closed || self.seeking || self.buffering || self.paused || self.playbackFinished || !self.formatContext.audioEnable;
    if (check) return nil;
    if (self.audioDecoder.empty) {
        [self updateBufferedDurationByAudio];
        return nil;
    }
    self.currentAudioFrame = [self.audioDecoder getFrameSync];
    if (!self.currentAudioFrame) return nil;
    
    if (self.endOfFile) {
        [self updateBufferedDurationByAudio];
    }
    [self updateProgressByAudio];
    self.audioTimeClock = self.currentAudioFrame.position;
    BOOL videoOuputPuused = [self.videoOutput videoOutputPaused];
    BOOL background = NO;
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    background = [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
#endif
    if (background || videoOuputPuused) {
        [self.videoDecoder discardFrameBeforPosition:self.audioTimeClock];
    }
    return self.currentAudioFrame;
}

- (SGFFVideoFrame *)fetchVideoFrameWithCurrentPostion:(NSTimeInterval)currentPostion currentDuration:(NSTimeInterval)currentDuration
{
    if (self.closed || self.error) {
        return  nil;
    }
    if (self.seeking || self.buffering) {
        return  nil;
    }
    if (self.videoDecoder.frameEmpty) {
        return nil;
    }
    if (self.endOfFile && self.videoDecoder.empty) {
        return nil;
    }
    if (self.paused && !self.needUpdateVideo) {
        return nil;
    }
    
    SGFFVideoFrame * videoFrame = nil;
    if (self.formatContext.audioEnable)
    {
        NSTimeInterval firstPosition = [self.videoDecoder getFirstFramePositionAsync];
        NSTimeInterval audioTimeClock = self.audioTimeClock;
        NSTimeInterval currentStop = currentPostion + currentDuration;
        
        if (currentPostion >= audioTimeClock || currentStop > audioTimeClock) {
            if (firstPosition < currentPostion && firstPosition >= 0) {
                videoFrame = [self.videoDecoder getFrameAsync];
            }
        } else {
            videoFrame = [self.videoDecoder getFrameAsyncPosistion:self.audioTimeClock];
        }
    }
    else
    {
        NSTimeInterval timeInterval = [NSDate date].timeIntervalSince1970;
        if (timeInterval >= self.videoTimeToken || self.videoTimeToken < 0) {
            videoFrame = [self.videoDecoder getFrameAsync];
            if (videoFrame) {
                NSTimeInterval duration = videoFrame.duration;
                if (duration < 0.00001) {
                    duration = (1.0 / self.videoDecoder.fps);
                }
                self.videoTimeToken = timeInterval + duration;
            }
        }
    }
    if (videoFrame) {
        self.currentVideoFrame = videoFrame;
        [self updateProgressByVideo];
        if (self.endOfFile) {
            [self updateBufferedDurationByVideo];
        }
        self.needUpdateVideo = NO;
    }
    return videoFrame;
}

#pragma mark - close stream

- (void)closeFile
{
    [self closeFileAsync:YES];
}

- (void)closeFileAsync:(BOOL)async
{
    if (!self.closed) {
        self.closed = YES;
        [self.videoDecoder destroy];
        [self.audioDecoder destroy];
        if (async) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [self.ffmpegOperationQueue cancelAllOperations];
                [self.ffmpegOperationQueue waitUntilAllOperationsAreFinished];
                [self closePropertyValue];
                [self.formatContext destroy];
                [self closeOperation];
            });
        } else {
            [self.ffmpegOperationQueue cancelAllOperations];
            [self.ffmpegOperationQueue waitUntilAllOperationsAreFinished];
            [self closePropertyValue];
            [self.formatContext destroy];
            [self closeOperation];
        }
    }
}

- (void)closePropertyValue
{
    self.seeking = NO;
    self.buffering = NO;
    self.paused = NO;
    self.prepareToDecode = NO;
    self.endOfFile = NO;
    self.playbackFinished = NO;
    self.currentVideoFrame = nil;
    self.currentAudioFrame = nil;
    self.videoDecoder.paused = NO;
    self.videoDecoder.endOfFile = NO;
    self.selectAudioTrack = NO;
    self.selectAudioTrackIndex = 0;
    self.needUpdateVideo = NO;
}

- (void)closeOperation
{
    self.readPacketOperation = nil;
    self.openFileOperation = nil;
    self.decodeFrameOperation = nil;
    self.ffmpegOperationQueue = nil;
}

#pragma mark - setter/getter

- (void)setProgress:(NSTimeInterval)progress
{
    if (_progress != progress) {
        _progress = progress;
        if ([self.delegate respondsToSelector:@selector(decoder:didChangeValueOfProgress:)]) {
            [self.delegate decoder:self didChangeValueOfProgress:_progress];
        }
    }
}

- (void)setBuffering:(BOOL)buffering
{
    if (_buffering != buffering) {
        _buffering = buffering;
        if ([self.delegate respondsToSelector:@selector(decoder:didChangeValueOfBuffering:)]) {
            [self.delegate decoder:self didChangeValueOfBuffering:_buffering];
        }
    }
}

- (void)setPlaybackFinished:(BOOL)playbackFinished
{
    if (_playbackFinished != playbackFinished) {
        _playbackFinished = playbackFinished;
        if (_playbackFinished) {
            self.progress = self.duration;
            if ([self.delegate respondsToSelector:@selector(decoderDidPlaybackFinished:)]) {
                [self.delegate decoderDidPlaybackFinished:self];
            }
        }
    }
}

- (void)setBufferedDuration:(NSTimeInterval)bufferedDuration
{
    if (_bufferedDuration != bufferedDuration) {
        _bufferedDuration = bufferedDuration;
        if (_bufferedDuration <= 0.000001) {
            _bufferedDuration = 0;
        }
        if ([self.delegate respondsToSelector:@selector(decoder:didChangeValueOfBufferedDuration:)]) {
            [self.delegate decoder:self didChangeValueOfBufferedDuration:_bufferedDuration];
        }
        if (_bufferedDuration <= 0 && self.endOfFile) {
            self.playbackFinished = YES;
        }
        [self checkBufferingStatus];
    }
}

- (NSDictionary *)metadata
{
    return self.formatContext.metadata;
}

- (NSTimeInterval)duration
{
    return self.formatContext.duration;
}

- (NSTimeInterval)bitrate
{
    return self.formatContext.bitrate;
}

- (BOOL)seekEnable
{
    return self.duration > 0;
}

- (CGSize)presentationSize
{
    return self.formatContext.videoPresentationSize;
}

- (CGFloat)aspect
{
    return self.formatContext.videoAspect;
}

#pragma mark - delegate callback

- (void)checkBufferingStatus
{
    if (self.buffering) {
        if (self.bufferedDuration >= self.minBufferedDruation || self.endOfFile) {
            self.buffering = NO;
        }
    } else {
        if (self.bufferedDuration <= 0.2 && !self.endOfFile) {
            self.buffering = YES;
        }
    }
}

- (void)updateBufferedDurationByVideo
{
    if (!self.formatContext.audioEnable) {
        self.bufferedDuration = self.videoDecoder.duration;
    }
}

- (void)updateBufferedDurationByAudio
{
    if (self.formatContext.audioEnable) {
        self.bufferedDuration = self.audioDecoder.duration;
    }
}

- (void)updateProgressByVideo;
{
    if (!self.formatContext.audioEnable && self.formatContext.videoEnable) {
        self.progress = self.currentVideoFrame.position;
    }
}

- (void)updateProgressByAudio
{
    if (self.formatContext.audioEnable) {
        self.progress = self.currentAudioFrame.position;
    }
}

- (void)delegateErrorCallback
{
    if (self.error) {
        if ([self.delegate respondsToSelector:@selector(decoder:didError:)]) {
            [self.delegate decoder:self didError:self.error];
        }
    }
}

- (void)dealloc
{
    [self closeFileAsync:NO];
    SGPlayerLog(@"SGFFDecoder release");
}


#pragma delegate callback

- (BOOL)formatContextNeedInterrupt:(SGFFFormatContext *)formatContext
{
    return self.closed;
}

- (void)audioDecoder:(SGFFAudioDecoder *)audioDecoder samplingRate:(Float64 *)samplingRate
{
    * samplingRate = self.audioOutput.samplingRate;
}

- (void)audioDecoder:(SGFFAudioDecoder *)audioDecoder channelCount:(UInt32 *)channelCount
{
    * channelCount = self.audioOutput.numberOfChannels;
}

- (void)videoDecoderNeedUpdateBufferedDuration:(SGFFVideoDecoder *)videoDecoder
{
    [self updateBufferedDurationByVideo];
}

- (void)videoDecoderNeedCheckBufferingStatus:(SGFFVideoDecoder *)videoDecoder
{
    [self checkBufferingStatus];
}

- (void)videoDecoder:(SGFFVideoDecoder *)videoDecoder didError:(NSError *)error
{
    self.error = error;
    [self delegateErrorCallback];
}


#pragma mark - track info

- (BOOL)videoEnable
{
    return self.formatContext.videoEnable;
}

- (BOOL)audioEnable
{
    return self.formatContext.audioEnable;
}

- (SGFFTrack *)videoTrack
{
    return self.formatContext.videoTrack;
}

- (SGFFTrack *)audioTrack
{
    return self.formatContext.audioTrack;
}

- (NSArray<SGFFTrack *> *)videoTracks
{
    return self.formatContext.videoTracks;
}

- (NSArray<SGFFTrack *> *)audioTracks
{
    return self.formatContext.audioTracks;
}

- (void)selectAudioTrackIndex:(int)audioTrackIndex
{
    if (self.formatContext.audioTrack.index == audioTrackIndex) return;
    if (![self.formatContext containAudioTrack:audioTrackIndex]) return;
    self.selectAudioTrack = YES;
    self.selectAudioTrackIndex = audioTrackIndex;
    if (self.endOfFile) {
        [self setupReadPacketOperation];
    }
}

@end
