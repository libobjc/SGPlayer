//
//  SGSession.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGSessionConfiguration.h"
#import "SGDefines.h"

typedef NS_ENUM(NSUInteger, SGSessionState)
{
    SGSessionStateNone,
    SGSessionStateOpening,
    SGSessionStateOpened,
    SGSessionStateReading,
    SGSessionStateClosed,
    SGSessionStateFinished,
    SGSessionStateFailed,
};

@class SGSession;

@protocol SGSessionDelegate <NSObject>

- (void)sessionDidChangeState:(SGSession *)session;
- (void)sessionDidChangeCapacity:(SGSession *)session;

@end

@interface SGSession : NSObject

@property (nonatomic, copy) NSURL * URL;
@property (nonatomic, weak) id <SGSessionDelegate> delegate;
@property (nonatomic, strong) SGSessionConfiguration * configuration;

@property (nonatomic, assign, readonly) SGSessionState state;
@property (nonatomic, copy, readonly) NSError * error;

/**
 *  Time.
 */
@property (nonatomic, assign, readonly) CMTime duration;

- (CMTime)loadedDuration;       // Main media type is Audio.
- (CMTime)loadedDurationWithMainMediaType:(SGMediaType)mainMediaType;

- (long long)loadedSize;        // Main media type is Audio.
- (long long)loadedSizeWithMainMediaType:(SGMediaType)mainMediaType;

/**
 *  Audio.
 */
@property (nonatomic, assign, readonly) BOOL audioEnable;
@property (nonatomic, assign, readonly) CMTime audioLoadedDuration;
@property (nonatomic, assign, readonly) long long audioLoadedSize;

/**
 *  Video.
 */
@property (nonatomic, assign, readonly) BOOL videoEnable;
@property (nonatomic, assign, readonly) CMTime videoLoadedDuration;
@property (nonatomic, assign, readonly) long long videoLoadedSize;

/**
 *  Streams.
 */
- (void)open;
- (void)read;
- (void)close;

/**
 *  Seek.
 */
- (BOOL)seekable;
- (BOOL)seekableToTime:(CMTime)time;
- (BOOL)seekToTime:(CMTime)time completionHandler:(void(^)(BOOL success, CMTime time))completionHandler;

@end
