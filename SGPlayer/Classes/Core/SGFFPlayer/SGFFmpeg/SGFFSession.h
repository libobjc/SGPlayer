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

- (NSTimeInterval)duration;
- (NSTimeInterval)loadedDuration;
- (long long)loadedSize;

- (NSError *)error;

- (void)open;
- (void)read;
- (void)close;

- (void)seekToTime:(NSTimeInterval)time completionHandler:(void(^)(BOOL success))completionHandler;

@end
