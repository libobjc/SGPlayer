//
//  SGFFSession.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFSession.h"
#import "SGFFFormatContext.h"
#import "SGFFCodecManager.h"

@interface SGFFSession () <SGFFSourceDelegate, SGFFCodecManagerDelegate>

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, weak) id <SGFFSessionDelegate> delegate;

@property (nonatomic, strong) id <SGFFSource> source;
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
    self.codecManager = [[SGFFCodecManager alloc] initWithStreams:self.source.streams delegate:self];
    [self.codecManager open];
}

- (void)sourceDidFailed:(id <SGFFSource>)source
{
    self.error = source.error;
    [self callbackForError];
}


#pragma mark - SGFFCodecManagerDelegate

- (void)codecManagerDidOpened:(SGFFCodecManager *)codecManager
{
    [self.source read];
}

- (void)codecManagerDidFailed:(SGFFCodecManager *)codecManager
{
    self.error = codecManager.error;
    [self callbackForError];
}


@end
