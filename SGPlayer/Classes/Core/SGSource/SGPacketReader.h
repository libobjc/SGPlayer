//
//  SGPacketReader.h
//  SGPlayer iOS
//
//  Created by Single on 2018/9/19.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPacket.h"

@class SGPacketReader;

@protocol SGPacketReaderDelegate <NSObject>

- (BOOL)packetReaderShouldAbortBlockingFunctions:(SGPacketReader *)packetReader;

@end

@interface SGPacketReader : NSObject

@property (nonatomic, strong) id object;

@property (nonatomic, weak) id <SGPacketReaderDelegate> delegate;
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
- (NSError *)seekableToTime:(CMTime)time;
- (NSError *)seekToTime:(CMTime)time;
- (NSError *)nextPacket:(SGPacket *)packet;

@end
