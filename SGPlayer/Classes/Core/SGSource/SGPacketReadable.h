//
//  SGPacketReadable.h
//  SGPlayer iOS
//
//  Created by Single on 2018/9/25.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPacket.h"

@protocol SGPacketReadableDelegate;

@protocol SGPacketReadable <NSObject>

@property (nonatomic, weak) id object;
@property (nonatomic, weak) id <SGPacketReadableDelegate> delegate;

- (CMTime)duration;
- (NSDictionary *)metadata;
- (NSArray <SGTrack *> *)tracks;
- (NSArray <SGTrack *> *)audioTracks;
- (NSArray <SGTrack *> *)videoTracks;
- (NSArray <SGTrack *> *)otherTracks;

- (NSError *)open;
- (NSError *)close;
- (NSError *)seekable;
- (NSError *)seekToTime:(CMTime)time;
- (NSError *)nextPacket:(SGPacket *)packet;

@end

@protocol SGPacketReadableDelegate <NSObject>

- (BOOL)packetReadableShouldAbortBlockingFunctions:(id <SGPacketReadable>)packetReadable;

@end
