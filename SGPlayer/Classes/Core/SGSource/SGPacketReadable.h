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

@property (nonatomic, strong) id object;

@property (nonatomic, weak) id <SGPacketReadableDelegate> delegate;
@property (nonatomic, copy) NSDictionary * options;

- (NSError *)error;
- (CMTime)duration;
- (NSDictionary *)metadata;
- (NSArray <SGStream *> *)streams;
- (NSArray <SGStream *> *)audioStreams;
- (NSArray <SGStream *> *)videoStreams;
- (NSArray <SGStream *> *)otherStreams;

- (NSError *)open;
- (NSError *)close;
- (NSError *)seekable;
- (NSError *)seekToTime:(CMTime)time;
- (NSError *)nextPacket:(SGPacket *)packet;

@end

@protocol SGPacketReadableDelegate <NSObject>

- (BOOL)packetReadableShouldAbortBlockingFunctions:(id <SGPacketReadable>)packetReadable;

@end
