//
//  SGFFFormatContext.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFFormatContext.h"
#import "SGFFPacket.h"
#import "SGFFError.h"
#import "avformat.h"

static int SGFFFormatContextInterruptHandler(void * context)
{
    SGFFFormatContext * obj = (__bridge SGFFFormatContext *)context;
    switch (obj.state)
    {
        case SGFFSourceStateFinished:
        case SGFFSourceStateClosed:
        case SGFFSourceStateFailed:
            return YES;
        default:
            return NO;
    }
}

@interface SGFFFormatContext ()

@property (nonatomic, assign) AVFormatContext * formatContext;

@property (nonatomic, assign) SGFFSourceState state;
@property (nonatomic, copy) NSError * error;

@property (nonatomic, strong) NSArray <SGFFStream *> * streams;
@property (nonatomic, strong) NSArray <SGFFStream *> * videoStreams;
@property (nonatomic, strong) NSArray <SGFFStream *> * audioStreams;
@property (nonatomic, strong) NSArray <SGFFStream *> * subtitleStreams;
@property (nonatomic, strong) NSArray <SGFFStream *> * otherStreams;

@property (nonatomic, strong) NSOperationQueue * operationQueue;
@property (nonatomic, strong) NSInvocationOperation * openStreamsOperation;
@property (nonatomic, strong) NSInvocationOperation * readingOperation;
@property (nonatomic, strong) NSCondition * readingCondition;

@property (nonatomic, assign) long long seekingTimestamp;
@property (nonatomic, copy) void(^seekingCompletionHandler)(BOOL);

@end

@implementation SGFFFormatContext

@synthesize URL = _URL;
@synthesize delegate = _delegate;

#pragma mark - Setter/Getter

- (CMTime)duration
{
    if (!self.formatContext)
    {
        return kCMTimeZero;
    }
    int64_t duration = self.formatContext->duration;
    if (duration < 0)
    {
        return kCMTimeZero;
    }
    return CMTimeMake(duration, AV_TIME_BASE);
}

#pragma mark - Interface

- (void)openStreams
{
    self.state = SGFFSourceStateOpening;
    [self startOpenStreamsThread];
}

- (void)startReading
{
    self.state = SGFFSourceStateReading;
    [self startReadingThread];
}

- (void)pauseReading
{
    if (self.state == SGFFSourceStateReading)
    {
        self.state = SGFFSourceStatePaused;
    }
}

- (void)resumeReading
{
    if (self.state == SGFFSourceStatePaused)
    {
        self.state = SGFFSourceStateReading;
        [self.readingCondition lock];
        [self.readingCondition broadcast];
        [self.readingCondition unlock];
    }
}

- (void)stopReading
{
    self.state = SGFFSourceStateClosed;
    [self.readingCondition lock];
    [self.readingCondition broadcast];
    [self.readingCondition unlock];
    [self.operationQueue cancelAllOperations];
    [self.operationQueue waitUntilAllOperationsAreFinished];
    if (self.formatContext)
    {
        avformat_close_input(&_formatContext);
        self.formatContext = NULL;
    }
}

#pragma mark - Seeking

- (BOOL)seekable
{
    if (!self.formatContext)
    {
        return NO;
    }
    BOOL seekable = YES;
    if (self.formatContext->pb)
    {
        seekable = self.formatContext->pb->seekable;
    }
    if (seekable && CMTimeCompare(self.duration, kCMTimeZero) > 0)
    {
        return YES;
    }
    return NO;
}

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler
{
    void (^seek)(void) = ^{
        self.seekingTimestamp = time.value * AV_TIME_BASE / time.timescale;
        self.seekingCompletionHandler = completionHandler;
        self.state = SGFFSourceStateSeeking;
    };
    if (self.state == SGFFSourceStatePaused)
    {
        seek();
        [self.readingCondition lock];
        [self.readingCondition broadcast];
        [self.readingCondition unlock];
    }
    else if (self.state == SGFFSourceStateReading)
    {
        seek();
    }
    else if (self.state == SGFFSourceStateFinished)
    {
        seek();
        [self startReadingThread];
    }
}

#pragma mark - Open

- (void)startOpenStreamsThread
{
    if (!self.operationQueue)
    {
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 2;
        self.operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    }
    self.openStreamsOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(openStreamsThread) object:nil];
    self.openStreamsOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.openStreamsOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    [self.operationQueue addOperation:self.openStreamsOperation];
}

- (void)openStreamsThread
{
    self.formatContext = avformat_alloc_context();
    
    if (!self.formatContext)
    {
        self.error = SGFFCreateErrorCode(SGFFErrorCodeFormatCreate);
        [self callbackForError];
        return;
    }
    
    self.formatContext->interrupt_callback.callback = SGFFFormatContextInterruptHandler;
    self.formatContext->interrupt_callback.opaque = (__bridge void *)self;
    
    NSString * URLString = self.URL.isFileURL ? self.URL.path : self.URL.absoluteString;
    int reslut = avformat_open_input(&_formatContext, URLString.UTF8String, NULL, NULL);
    self.error = SGFFGetErrorCode(reslut, SGFFErrorCodeFormatOpenInput);
    if (self.error)
    {
        if (self.formatContext)
        {
            avformat_free_context(self.formatContext);
        }
        [self callbackForError];
        return;
    }
    
    reslut = avformat_find_stream_info(self.formatContext, NULL);
    self.error = SGFFGetErrorCode(reslut, SGFFErrorCodeFormatFindStreamInfo);
    if (self.error)
    {
        if (self.formatContext)
        {
            avformat_close_input(&_formatContext);
            avformat_free_context(self.formatContext);
        }
        [self callbackForError];
        return;
    }
    
    NSMutableArray <SGFFStream *> * streams = [NSMutableArray array];
    NSMutableArray <SGFFStream *> * audioStreams = [NSMutableArray array];
    NSMutableArray <SGFFStream *> * videoStreams = [NSMutableArray array];
    NSMutableArray <SGFFStream *> * subtitleStreams = [NSMutableArray array];
    NSMutableArray <SGFFStream *> * otherStreams = [NSMutableArray array];
    for (int i = 0; i < self.formatContext->nb_streams; i++)
    {
        SGFFStream * obj = [[SGFFStream alloc] init];
        obj.coreStream = self.formatContext->streams[i];
        [streams addObject:obj];
        switch (obj.coreStream->codecpar->codec_type)
        {
            case AVMEDIA_TYPE_AUDIO:
                [audioStreams addObject:obj];
                break;
            case AVMEDIA_TYPE_VIDEO:
                [videoStreams addObject:obj];
                break;
            case AVMEDIA_TYPE_SUBTITLE:
                [subtitleStreams addObject:obj];
                break;
            default:
                [otherStreams addObject:obj];
                break;
        }
    }
    self.streams = [streams copy];
    self.audioStreams = [audioStreams copy];
    self.videoStreams = [videoStreams copy];
    self.subtitleStreams = [subtitleStreams copy];
    self.otherStreams = [otherStreams copy];
    
    if (self.audioStreams.count > 0 || self.videoStreams.count > 0)
    {
        self.state = SGFFSourceStateOpened;
        if ([self.delegate respondsToSelector:@selector(sourceDidOpened:)])
        {
            [self.delegate sourceDidOpened:self];
        }
    }
    else
    {
        [self callbackForError];
    }
}

#pragma mark - Reading

- (void)startReadingThread
{
    if (!self.readingCondition)
    {
        self.readingCondition = [[NSCondition alloc] init];
    }
    self.readingOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(readingThread) object:nil];
    self.readingOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.readingOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    [self.readingOperation addDependency:self.openStreamsOperation];
    [self.operationQueue addOperation:self.readingOperation];
}

- (void)readingThread
{
    while (YES)
    {
        if (self.state == SGFFSourceStateFinished ||
            self.state == SGFFSourceStateClosed ||
            self.state == SGFFSourceStateFailed)
        {
            break;
        }
        else if (self.state == SGFFSourceStatePaused)
        {
            [self.readingCondition lock];
            if (self.state == SGFFSourceStatePaused)
            {
                [self.readingCondition wait];
            }
            [self.readingCondition unlock];
            continue;
        }
        else if (self.state == SGFFSourceStateSeeking)
        {
            int success = av_seek_frame(self.formatContext, -1, self.seekingTimestamp, AVSEEK_FLAG_BACKWARD);
            if (self.state == SGFFSourceStateSeeking)
            {
                if (self.seekingCompletionHandler)
                {
                    self.seekingCompletionHandler(success >= 0);
                }
                self.seekingTimestamp = 0;
                self.seekingCompletionHandler = nil;
                self.state = SGFFSourceStateReading;
            }
            else
            {
                self.seekingTimestamp = 0;
                self.seekingCompletionHandler = nil;
            }
            continue;
        }
        else if (self.state == SGFFSourceStateReading)
        {
            SGFFPacket * packet = [[SGFFObjectPool sharePool] objectWithClass:[SGFFPacket class]];
            int readResult = av_read_frame(self.formatContext, packet.corePacket);
            if (readResult < 0)
            {
                self.state = SGFFSourceStateFinished;
                [packet unlock];
                if ([self.delegate respondsToSelector:@selector(sourceDidFinished:)])
                {
                    [self.delegate sourceDidFinished:self];
                }
                break;
            }
            [self.delegate source:self hasNewPacket:packet];
            [packet unlock];
            continue;
        }
    }
}

#pragma mark - Callback

- (void)callbackForError
{
    self.state = SGFFSourceStateFailed;
    if ([self.delegate respondsToSelector:@selector(sourceDidFailed:)])
    {
        [self.delegate sourceDidFailed:self];
    }
}

@end
