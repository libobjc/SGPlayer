//
//  SGFFSession.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPLFView.h"

@class SGFFSession;

@protocol SGFFSessionDelegate <NSObject>

- (void)session:(SGFFSession *)session didFailed:(NSError *)error;

@end

@interface SGFFSession : NSObject

- (instancetype)initWithContentURL:(NSURL *)contentURL delegate:(id <SGFFSessionDelegate>)delegate;

@property (nonatomic, strong) SGPLFView * view;
@property (nonatomic, copy) NSError * error;

- (void)open;
- (void)close;

- (void)seekToTime:(NSTimeInterval)timestamp;

@end
