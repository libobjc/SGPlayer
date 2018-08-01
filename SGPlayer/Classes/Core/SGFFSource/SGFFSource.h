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
#import "SGStream.h"
#import "SGPacket.h"

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
    SGFFSourceStateStoped,
    SGFFSourceStateFailed,
};

@protocol SGFFSource <NSObject>

@property (nonatomic, copy) NSURL * URL;
@property (nonatomic, weak) id <SGFFSourceDelegate> delegate;

- (SGFFSourceState)state;

- (CMTime)duration;
- (NSError *)error;

- (NSArray <SGStream *> *)streams;
- (NSArray <SGStream *> *)audioStreams;
- (NSArray <SGStream *> *)videoStreams;
- (NSArray <SGStream *> *)subtitleStreams;
- (NSArray <SGStream *> *)otherStreams;

- (void)openStreams;

- (void)startReading;
- (void)pauseReading;
- (void)resumeReading;
- (void)stopReading;

- (BOOL)seekable;
- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler;

@end

@protocol SGFFSourceDelegate <NSObject>

- (void)source:(id <SGFFSource>)source hasNewPacket:(SGPacket *)packet;
- (void)sourceDidOpened:(id <SGFFSource>)source;
- (void)sourceDidFailed:(id <SGFFSource>)source;
- (void)sourceDidFinished:(id <SGFFSource>)source;

@end

#endif /* SGFFSource_h */
