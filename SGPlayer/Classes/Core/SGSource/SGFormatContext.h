//
//  SGFormatContext.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/13.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGStream.h"

@interface SGFormatContext : NSObject

- (instancetype)initWithURL:(NSURL *)URL;

@property (nonatomic, strong, readonly) NSURL * URL;
@property (nonatomic, assign, readonly) AVFormatContext * coreFormatContext;
@property (nonatomic, strong, readonly) NSError * error;
@property (nonatomic, assign, readonly) CMTime duration;
@property (nonatomic, strong, readonly) NSArray <SGStream *> * streams;
@property (nonatomic, strong, readonly) NSArray <SGStream *> * videoStreams;
@property (nonatomic, strong, readonly) NSArray <SGStream *> * audioStreams;
@property (nonatomic, strong, readonly) NSArray <SGStream *> * subtitleStreams;
@property (nonatomic, strong, readonly) NSArray <SGStream *> * otherStreams;
@property (nonatomic, assign, readonly) BOOL seekable;

- (BOOL)openWithOpaque:(void *)opaque callback:(int (*)(void *))callback;
- (void)destory;

@end
