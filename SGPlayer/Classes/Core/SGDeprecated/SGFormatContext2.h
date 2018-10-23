//
//  SGFormatContext.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/13.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGStream.h"
#import "avformat.h"

@interface SGFormatContext2 : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithURL:(NSURL *)URL scale:(CMTime)scale startTime:(CMTime)startTime preferredTimeRange:(CMTimeRange)preferredTimeRange;

@property (nonatomic, strong, readonly) NSURL * URL;

@property (nonatomic, assign, readonly) CMTime scale;
@property (nonatomic, assign, readonly) CMTime startTime;
@property (nonatomic, assign, readonly) CMTimeRange actualTimeRange;
@property (nonatomic, assign, readonly) CMTimeRange preferredTimeRange;

@property (nonatomic, assign, readonly) CMTime duration;
@property (nonatomic, assign, readonly) CMTime originalDuration;
@property (nonatomic, assign, readonly) BOOL seekable;
@property (nonatomic, assign, readonly) BOOL audioEnable;
@property (nonatomic, assign, readonly) BOOL videoEnable;
@property (nonatomic, copy, readonly) NSError * error;
@property (nonatomic, copy, readonly) NSDictionary * metadata;

@property (nonatomic, assign, readonly) AVFormatContext * coreFormatContext;
@property (nonatomic, strong, readonly) NSArray <SGStream *> * streams;
@property (nonatomic, strong, readonly) NSArray <SGStream *> * videoStreams;
@property (nonatomic, strong, readonly) NSArray <SGStream *> * audioStreams;
@property (nonatomic, strong, readonly) NSArray <SGStream *> * subtitleStreams;
@property (nonatomic, strong, readonly) NSArray <SGStream *> * otherStreams;

- (BOOL)openWithOptions:(NSDictionary *)options opaque:(void *)opaque callback:(int (*)(void *))callback;
- (void)destory;

@end
