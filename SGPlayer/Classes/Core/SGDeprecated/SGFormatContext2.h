//
//  SGURLDemuxer.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/13.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTrack.h"
#import "avformat.h"

@interface SGURLDemuxer2 : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithURL:(NSURL *)URL scale:(CMTime)scale startTime:(CMTime)startTime preferredTimeRange:(CMTimeRange)preferredTimeRange;

@property (nonatomic, strong, readonly) NSURL * URL;

@property (nonatomic, readonly) CMTime scale;
@property (nonatomic, readonly) CMTime startTime;
@property (nonatomic, readonly) CMTimeRange actualTimeRange;
@property (nonatomic, readonly) CMTimeRange preferredTimeRange;

@property (nonatomic, readonly) CMTime duration;
@property (nonatomic, readonly) CMTime originalDuration;
@property (nonatomic, readonly) BOOL seekable;
@property (nonatomic, readonly) BOOL audioEnable;
@property (nonatomic, readonly) BOOL videoEnable;
@property (nonatomic, copy, readonly) NSError * error;
@property (nonatomic, copy, readonly) NSDictionary * metadata;

@property (nonatomic, readonly) AVFormatContext * coreFormatContext;
@property (nonatomic, strong, readonly) NSArray <SGTrack *> * tracks;
@property (nonatomic, strong, readonly) NSArray <SGTrack *> * videoTracks;
@property (nonatomic, strong, readonly) NSArray <SGTrack *> * audioTracks;
@property (nonatomic, strong, readonly) NSArray <SGTrack *> * subtitleTracks;
@property (nonatomic, strong, readonly) NSArray <SGTrack *> * otherTracks;

- (BOOL)openWithOptions:(NSDictionary *)options opaque:(void *)opaque callback:(int (*)(void *))callback;
- (void)destroy;

@end
