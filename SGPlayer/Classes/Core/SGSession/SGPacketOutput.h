//
//  SGURLSource.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDemuxable.h"

@protocol SGPacketOutputDelegate;

/**
 *
 */
typedef NS_ENUM(uint32_t, SGPacketOutputState) {
    SGPacketOutputStateNone,
    SGPacketOutputStateOpening,
    SGPacketOutputStateOpened,
    SGPacketOutputStateReading,
    SGPacketOutputStatePaused,
    SGPacketOutputStateSeeking,
    SGPacketOutputStateFinished,
    SGPacketOutputStateClosed,
    SGPacketOutputStateFailed,
};

@interface SGPacketOutput : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithDemuxable:(id<SGDemuxable> _Nonnull)demuxable NS_DESIGNATED_INITIALIZER;

/**
 *
 */
@property (nonatomic, weak) id<SGPacketOutputDelegate> _Nullable delegate;

/**
 *
 */
- (NSError * _Nullable)error;

/**
 *
 */
- (SGPacketOutputState)state;

/**
 *
 */
- (CMTime)duration;

/**
 *
 */
- (NSDictionary * _Nullable)metadata;

/**
 *
 */
- (NSArray<SGTrack *> * _Nullable)tracks;

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (BOOL)close;

/**
 *
 */
- (BOOL)pause;

/**
 *
 */
- (BOOL)resume;

/**
 *
 */
- (BOOL)seekable;

/**
 *
 */
- (BOOL)seekToTime:(CMTime)time result:(SGSeekResult _Nullable)result;

@end

@protocol SGPacketOutputDelegate <NSObject>

/**
 *
 */
- (void)packetOutput:(SGPacketOutput * _Nonnull)packetOutput didChangeState:(SGPacketOutputState)state;

/**
 *
 */
- (void)packetOutput:(SGPacketOutput * _Nonnull)packetOutput didOutputPacket:(SGPacket * _Nonnull)packet;

@end
