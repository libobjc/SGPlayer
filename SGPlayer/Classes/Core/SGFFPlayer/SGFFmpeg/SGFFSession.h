//
//  SGFFSession.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFSessionConfiguration.h"

typedef NS_ENUM(NSUInteger, SGFFSessionState)
{
    SGFFSessionStateIdle,
    SGFFSessionStateOpened,
    SGFFSessionStateReading,
    SGFFSessionStateClosed,
    SGFFSessionStateFinished,
    SGFFSessionStateFailed,
};

@class SGFFSession;

@protocol SGFFSessionDelegate <NSObject>

- (void)sessionDidOpened:(SGFFSession *)session;
- (void)sessionDidFailed:(SGFFSession *)session;
- (void)sessionDidFinished:(SGFFSession *)session;

@optional
- (void)sessionDidChangeCapacity:(SGFFSession *)session;

@end

@interface SGFFSession : NSObject

@property (nonatomic, copy) NSURL * URL;
@property (nonatomic, weak) id <SGFFSessionDelegate> delegate;
@property (nonatomic, strong) SGFFSessionConfiguration * configuration;

- (SGFFSessionState)state;
- (CMTime)duration;
- (CMTime)loadedDuration;
- (long long)loadedSize;
- (NSError *)error;

- (BOOL)videoEnable;
- (BOOL)audioEnable;
- (BOOL)seekEnable;

- (void)openStreams;
- (void)startReading;
- (void)closeStreams;

- (void)seekToTime:(CMTime)time completionHandler:(void(^)(BOOL success))completionHandler;

@end
