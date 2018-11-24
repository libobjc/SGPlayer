//
//  SGURLSource.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDemuxable.h"

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

@protocol SGPacketOutputDelegate;

@interface SGPacketOutput : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDemuxable:(id<SGDemuxable>)demuxable;

@property (nonatomic, weak) id<SGPacketOutputDelegate> delegate;

- (NSError *)error;
- (SGPacketOutputState)state;

- (CMTime)duration;
- (NSDictionary *)metadata;
- (NSArray<SGTrack *> *)tracks;

- (BOOL)open;
- (BOOL)close;
- (BOOL)pause;
- (BOOL)resume;
- (BOOL)seekable;
- (BOOL)seekToTime:(CMTime)time result:(SGSeekResult)result;

@end

@protocol SGPacketOutputDelegate <NSObject>

- (void)packetOutput:(SGPacketOutput *)packetOutput didChangeState:(SGPacketOutputState)state;
- (void)packetOutput:(SGPacketOutput *)packetOutput didOutputPacket:(SGPacket *)packet;

@end
