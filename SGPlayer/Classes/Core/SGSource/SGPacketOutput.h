//
//  SGURLSource.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPacket.h"
#import "SGAsset.h"

@protocol SGPacketOutputDelegate;

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

- (instancetype)initWithAsset:(SGAsset *)asset;

@property (nonatomic, weak) id <SGPacketOutputDelegate> delegate;

- (SGPacketOutputState)state;
- (NSError *)error;

- (CMTime)duration;
- (NSDictionary *)metadata;
- (NSArray <SGTrack *> *)tracks;
- (NSArray <SGTrack *> *)audioTracks;
- (NSArray <SGTrack *> *)videoTracks;
- (NSArray <SGTrack *> *)otherTracks;

- (BOOL)open;
- (BOOL)close;
- (BOOL)pause;
- (BOOL)resume;
- (BOOL)seekable;
- (BOOL)seekToTime:(CMTime)time result:(SGSeekResultBlock)result;

@end

@protocol SGPacketOutputDelegate <NSObject>

- (void)packetOutput:(SGPacketOutput *)packetOutput didChangeState:(SGPacketOutputState)state;
- (void)packetOutput:(SGPacketOutput *)packetOutput didOutputPacket:(SGPacket *)packet;

@end
