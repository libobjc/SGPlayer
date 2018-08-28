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

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithURL:(NSURL *)URL;
- (instancetype)initWithURL:(NSURL *)URL offset:(CMTime)offset scale:(CMTime)scale;

@property (nonatomic, strong, readonly) NSURL * URL;
@property (nonatomic, assign, readonly) CMTime offset;
@property (nonatomic, assign, readonly) CMTime scale;
@property (nonatomic, assign, readonly) CMTime duration;
@property (nonatomic, assign, readonly) CMTime originalDuration;
@property (nonatomic, assign, readonly) BOOL seekable;
@property (nonatomic, assign, readonly) BOOL audioEnable;
@property (nonatomic, assign, readonly) BOOL videoEnable;
@property (nonatomic, strong, readonly) NSError * error;

@property (nonatomic, assign, readonly) AVFormatContext * coreFormatContext;
@property (nonatomic, strong, readonly) NSArray <SGStream *> * streams;
@property (nonatomic, strong, readonly) NSArray <SGStream *> * videoStreams;
@property (nonatomic, strong, readonly) NSArray <SGStream *> * audioStreams;
@property (nonatomic, strong, readonly) NSArray <SGStream *> * subtitleStreams;
@property (nonatomic, strong, readonly) NSArray <SGStream *> * otherStreams;

- (BOOL)openWithOptions:(NSDictionary *)options opaque:(void *)opaque callback:(int (*)(void *))callback;
- (void)destory;

@end
