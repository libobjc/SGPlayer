//
//  SGSource.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#ifndef SGSource_h
#define SGSource_h

#import <Foundation/Foundation.h>
#import "SGStream.h"
#import "SGPacket.h"

@protocol SGSource;
@protocol SGSourceDelegate;

typedef NS_ENUM(NSUInteger, SGSourceState)
{
    SGSourceStateIdle,
    SGSourceStateOpening,
    SGSourceStateOpened,
    SGSourceStateReading,
    SGSourceStatePaused,
    SGSourceStateSeeking,
    SGSourceStateFinished,
    SGSourceStateStoped,
    SGSourceStateFailed,
};

@protocol SGSource <NSObject>

@property (nonatomic, copy) NSURL * URL;
@property (nonatomic, weak) id <SGSourceDelegate> delegate;

- (SGSourceState)state;

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

@protocol SGSourceDelegate <NSObject>

- (void)source:(id <SGSource>)source hasNewPacket:(SGPacket *)packet;
- (void)sourceDidOpened:(id <SGSource>)source;
- (void)sourceDidFailed:(id <SGSource>)source;
- (void)sourceDidFinished:(id <SGSource>)source;

@end

#endif /* SGSource_h */
