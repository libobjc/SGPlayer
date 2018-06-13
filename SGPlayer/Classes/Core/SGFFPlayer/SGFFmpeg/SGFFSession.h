//
//  SGFFSession.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFSessionConfiguration.h"

@class SGFFSession;


typedef NS_ENUM(NSUInteger, SGFFSessionState)
{
    SGFFSessionStateIdle,
    SGFFSessionStateOpened,
    SGFFSessionStateReading,
    SGFFSessionStateClosed,
    SGFFSessionStateFinished,
    SGFFSessionStateFailed,
};


@protocol SGFFSessionDelegate <NSObject>

- (void)sessionDidOpened:(SGFFSession *)session;
- (void)sessionDidFailed:(SGFFSession *)session;
- (void)sessionDidFinished:(SGFFSession *)session;

@optional
- (void)sessionDidChangeCapacity:(SGFFSession *)session;

@end


@interface SGFFSession : NSObject

+ (instancetype)sessionWithContentURL:(NSURL *)contentURL
                             delegate:(id <SGFFSessionDelegate>)delegate
                        configuration:(SGFFSessionConfiguration *)configuration;

- (NSURL *)contentURL;
- (id <SGFFSessionDelegate>)delegate;
- (SGFFSessionConfiguration *)configuration;

- (SGFFSessionState)state;
- (CMTime)duration;
- (CMTime)loadedDuration;
- (long long)loadedSize;
- (NSError *)error;

- (BOOL)videoEnable;
- (BOOL)audioEnable;
- (BOOL)seekEnable;

- (void)open;
- (void)read;
- (void)close;

- (void)seekToTime:(CMTime)time completionHandler:(void(^)(BOOL success))completionHandler;

@end
