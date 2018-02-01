//
//  SGFFSource.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#ifndef SGFFSource_h
#define SGFFSource_h


#import <Foundation/Foundation.h>
#import "SGFFStream.h"
#import "SGFFPacket.h"


@protocol SGFFSource;
@protocol SGFFSourceDelegate;


typedef NS_ENUM(NSUInteger, SGFFSourceState)
{
    SGFFSourceStateIdle,
    SGFFSourceStateOpening,
    SGFFSourceStateOpened,
    SGFFSourceStateReading,
    SGFFSourceStatePaused,
    SGFFSourceStateSeeking,
    SGFFSourceStateFinished,
    SGFFSourceStateClosed,
    SGFFSourceStateFailed,
};


@protocol SGFFSource <NSObject>

- (instancetype)initWithContentURL:(NSURL *)contentURL delegate:(id <SGFFSourceDelegate>)delegate;

@property (nonatomic, copy, readonly) NSURL * contentURL;
@property (nonatomic, weak, readonly) id <SGFFSourceDelegate> delegate;

- (SGFFSourceState)state;
- (NSTimeInterval)duration;
- (NSTimeInterval)loadedDuration;
- (long long)loadedSize;
- (NSError *)error;

- (NSArray <SGFFStream *> *)streams;
- (NSArray <SGFFStream *> *)audioStreams;
- (NSArray <SGFFStream *> *)videoStreams;
- (NSArray <SGFFStream *> *)subtitleStreams;
- (SGFFStream *)currentAudioStream;
- (SGFFStream *)currentVideoStream;
- (SGFFStream *)currentSubtitleStream;

- (void)open;
- (void)read;
- (void)pause;
- (void)resume;
- (void)close;

- (BOOL)seekable;
- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^)(BOOL))completionHandler;

@end


@protocol SGFFSourceDelegate <NSObject>

- (id <SGFFCodec>)source:(id <SGFFSource>)source codecForStream:(SGFFStream *)stream;
- (void)sourceDidOpened:(id <SGFFSource>)source;
- (void)sourceDidFailed:(id <SGFFSource>)source;
- (void)sourceDidFinished:(id <SGFFSource>)source;

@end


#endif /* SGFFSource_h */
