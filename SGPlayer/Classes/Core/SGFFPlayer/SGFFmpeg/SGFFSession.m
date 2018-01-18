//
//  SGFFSession.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFSession.h"
#import "SGFFFormatContext.h"
#import "SGFFStreamManager.h"
#import "SGFFCodecManager.h"
#import "SGPlayerMacro.h"

@interface SGFFSession () <SGFFSourceDelegate, SGFFStreamManagerDelegate>

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, weak) id <SGFFSessionDelegate> delegate;

@property (nonatomic, strong) id <SGFFSource> source;
@property (nonatomic, strong) SGFFStreamManager * streamManager;
@property (nonatomic, strong) SGFFCodecManager * codecManager;

@end

@implementation SGFFSession

- (instancetype)initWithContentURL:(NSURL *)contentURL delegate:(id <SGFFSessionDelegate>)delegate
{
    if (self = [super init])
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
//            av_log_set_callback(SGFFLog);
            av_register_all();
            avformat_network_init();
        });
        
        self.contentURL = contentURL;
        self.delegate = delegate;
    }
    return self;
}

- (void)prepare
{
    self.source = [[SGFFFormatContext alloc] initWithContentURL:self.contentURL delegate:self];
    [self.source open];
}


#pragma mark - Callback

- (void)callbackForError
{
    if ([self.delegate respondsToSelector:@selector(session:didFailed:)]) {
        [self.delegate session:self didFailed:self.error];
    }
}


#pragma mark - SGFFSourceDelegate

- (void)sourceDidOpened:(id <SGFFSource>)source
{
    self.streamManager = [[SGFFStreamManager alloc] initWithStreams:self.source.streams delegate:self];
    [self.streamManager open];
}

- (void)sourceDidFailed:(id <SGFFSource>)source
{
    self.error = source.error;
    [self callbackForError];
}

- (NSTimeInterval)sourceSleepPeriodForReading:(id<SGFFSource>)source
{
    long long bufferedDuration = [self.streamManager bufferedDuration];
    long long bufferedSize = [self.streamManager bufferedSize];
    if (bufferedDuration > 10 * 1000 || bufferedSize > 15 * 1024 * 1024) {
        return 0.1;
    }
    return 0;
}

- (void)source:(id <SGFFSource>)source didOutputPacket:(AVPacket)packet
{
    [self.streamManager putPacket:packet];
}


#pragma mark - SGFFStreamManagerDelegate

- (void)streamManagerDidOpened:(SGFFStreamManager *)streamManager
{
    [self.source read];
}

- (void)streamManagerDidFailed:(SGFFStreamManager *)streamManager
{
    
}

- (id <SGFFCodec>)streamManager:(SGFFStreamManager *)streamManager codecForStream:(SGFFStream *)stream
{
    if (!self.codecManager) {
        self.codecManager = [[SGFFCodecManager alloc] init];
    }
    return [self.codecManager codecForStream:stream.stream];
}


@end
