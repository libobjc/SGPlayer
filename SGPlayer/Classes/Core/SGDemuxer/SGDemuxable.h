//
//  SGDemuxable.h
//  SGPlayer iOS
//
//  Created by Single on 2018/9/25.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDemuxerOptions.h"
#import "SGPacket.h"

@protocol SGDemuxableDelegate;

@protocol SGDemuxable <NSObject>

/**
 *
 */
@property (nonatomic, strong) SGDemuxerOptions *options;

/**
 *
 */
@property (nonatomic, weak) id<SGDemuxableDelegate> delegate;

/**
 *
 */
@property (nonatomic, copy, readonly) NSArray<SGTrack *> *tracks;

/**
 *
 */
@property (nonatomic, copy, readonly) NSDictionary *metadata;

/**
 *
 */
@property (nonatomic, readonly) CMTime duration;

/**
 *
 */
- (NSError *)open;

/**
 *
 */
- (NSError *)close;

/**
 *
 */
- (NSError *)seekable;

/**
 *
 */
- (NSError *)seekToTime:(CMTime)time;

/**
 *
 */
- (NSError *)nextPacket:(SGPacket **)packet;

@end

@protocol SGDemuxableDelegate <NSObject>

/**
 *
 */
- (BOOL)demuxableShouldAbortBlockingFunctions:(id<SGDemuxable>)demuxable;

@end
