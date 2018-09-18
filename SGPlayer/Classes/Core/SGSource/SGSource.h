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
    SGSourceStateNone,
    SGSourceStateOpening,
    SGSourceStateOpened,
    SGSourceStateReading,
    SGSourceStatePaused,
    SGSourceStateSeeking,
    SGSourceStateFinished,
    SGSourceStateClosed,
    SGSourceStateFailed,
};

@protocol SGSource <NSObject>

@property (nonatomic, weak) id <SGSourceDelegate> delegate;
@property (nonatomic, copy) NSDictionary * options;

- (SGSourceState)state;
- (NSError *)error;
- (CMTime)duration;
- (NSDictionary *)metadata;

- (BOOL)audioEnable;
- (BOOL)videoEnable;

- (void)open;
- (void)read;
- (void)pause;
- (void)resume;
- (void)close;

- (BOOL)seekable;
- (BOOL)seekableToTime:(CMTime)time;
- (BOOL)seekToTime:(CMTime)time completionHandler:(void(^)(CMTime time, NSError * error))completionHandler;

@end

@protocol SGSourceDelegate <NSObject>

- (void)sourceDidChangeState:(id <SGSource>)source;
- (void)source:(id <SGSource>)source hasNewPacket:(SGPacket *)packet;

@end

#endif /* SGSource_h */
