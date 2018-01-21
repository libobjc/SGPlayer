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

- (SGFFSourceState)state;
- (NSURL *)contentURL;
- (id <SGFFSourceDelegate>)delegate;
- (NSError *)error;
- (NSArray <SGFFStream *> *)streams;

- (void)open;
- (void)read;
- (void)pause;
- (void)resume;
- (void)close;

- (void)seekToTime:(NSTimeInterval)timestamp;

@end


@protocol SGFFSourceDelegate <NSObject>

- (void)sourceDidOpened:(id <SGFFSource>)source;
- (void)sourceDidFailed:(id <SGFFSource>)source;
- (void)sourceDidFinishedSeeking:(id <SGFFSource>)source;
- (void)source:(id <SGFFSource>)source didOutputPacket:(AVPacket)packet;

@end


#endif /* SGFFSource_h */
