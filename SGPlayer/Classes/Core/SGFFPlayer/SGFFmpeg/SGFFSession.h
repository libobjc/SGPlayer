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

- (void)session:(SGFFSession *)session didFailed:(NSError *)error;

@end

@interface SGFFSession : NSObject

+ (instancetype)sessionWithContentURL:(NSURL *)contentURL
                             delegate:(id <SGFFSessionDelegate>)delegate
                        configuration:(SGFFSessionConfiguration *)configuration;

@property (nonatomic, copy, readonly) NSURL * contentURL;
@property (nonatomic, weak, readonly) id <SGFFSessionDelegate> delegate;
@property (nonatomic, strong, readonly) SGFFSessionConfiguration * configuration;
@property (nonatomic, copy, readonly) NSError * error;

- (void)open;
- (void)close;

- (void)seekToTime:(NSTimeInterval)time completionHandler:(void(^)(BOOL success))completionHandler;

@end
