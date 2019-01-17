//
//  SGDemuxable.h
//  SGPlayer iOS
//
//  Created by Single on 2018/9/25.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPacket.h"

@protocol SGDemuxableDelegate;

NS_ASSUME_NONNULL_BEGIN

@protocol SGDemuxable <NSObject>

/**
 *
 */
@property (nonatomic, weak) id<SGDemuxableDelegate> _Nullable delegate;

/**
 *
 */
@property (nonatomic, copy) NSDictionary * _Nullable options;

/**
 *
 */
@property (nonatomic, copy, readonly) NSArray<SGTrack *> * _Nullable tracks;

/**
 *
 */
@property (nonatomic, copy, readonly) NSDictionary * _Nullable metadata;

/**
 *
 */
@property (nonatomic, readonly) CMTime duration;

/**
 *
 */
- (NSError * _Nullable)open;

/**
 *
 */
- (NSError * _Nullable)close;

/**
 *
 */
- (NSError * _Nullable)seekable;

/**
 *
 */
- (NSError * _Nullable)seekToTime:(CMTime)time;

/**
 *
 */
- (NSError * _Nullable)nextPacket:(SGPacket **)packet;

@end

@protocol SGDemuxableDelegate <NSObject>

/**
 *
 */
- (BOOL)demuxableShouldAbortBlockingFunctions:(id<SGDemuxable>)demuxable;

@end

NS_ASSUME_NONNULL_END
