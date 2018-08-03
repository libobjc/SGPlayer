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
- (NSError *)error;
- (CMTime)duration;

- (NSArray <SGStream *> *)streams;
- (NSArray <SGStream *> *)audioStreams;
- (NSArray <SGStream *> *)videoStreams;
- (NSArray <SGStream *> *)subtitleStreams;
- (NSArray <SGStream *> *)otherStreams;

- (void)open;
- (void)read;
- (void)pause;
- (void)resume;
- (void)close;

- (BOOL)seekable;
- (BOOL)seekableToTime:(CMTime)time;
- (BOOL)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL success))completionHandler;

@end

@protocol SGSourceDelegate <NSObject>

- (void)sourceDidChangeState:(id <SGSource>)source;
- (void)source:(id <SGSource>)source hasNewPacket:(SGPacket *)packet;

@end

#endif /* SGSource_h */
