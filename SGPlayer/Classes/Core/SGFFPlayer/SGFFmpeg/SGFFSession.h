//
//  SGFFSession.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFSessionConfiguration.h"
#import "SGDefines.h"

typedef NS_ENUM(NSUInteger, SGFFSessionState)
{
    SGFFSessionStateIdle,
    SGFFSessionStateOpening,
    SGFFSessionStateOpened,
    SGFFSessionStateReading,
    SGFFSessionStateClosed,
    SGFFSessionStateFinished,
    SGFFSessionStateFailed,
};

@class SGFFSession;

@protocol SGFFSessionDelegate <NSObject>

- (void)sessionDidChangeState:(SGFFSession *)session;
- (void)sessionDidChangeCapacity:(SGFFSession *)session;

@end

@interface SGFFSession : NSObject

@property (nonatomic, copy) NSURL * URL;
@property (nonatomic, weak) id <SGFFSessionDelegate> delegate;
@property (nonatomic, strong) SGFFSessionConfiguration * configuration;

@property (nonatomic, assign, readonly) SGFFSessionState state;
@property (nonatomic, copy, readonly) NSError * error;

/**
 *  Time.
 */
@property (nonatomic, assign, readonly) CMTime duration;
@property (nonatomic, assign, readonly) CMTime currentTime;

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
- (void)openStreams;
- (void)startReading;
- (void)closeStreams;

/**
 *  Seek.
 */
- (BOOL)seekable;
- (void)seekToTime:(CMTime)time completionHandler:(void(^)(BOOL success))completionHandler;

@end
