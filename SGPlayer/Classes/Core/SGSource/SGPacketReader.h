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

@property (nonatomic, weak) id <SGPacketReaderDelegate> delegate;
@property (nonatomic, copy) NSDictionary * options;

@property (nonatomic, copy, readonly) NSError * error;

- (BOOL)open;
- (BOOL)close;

- (BOOL)seekable;
- (BOOL)seekableToTime:(CMTime)time;

- (BOOL)seekToTime:(CMTime)time;
- (BOOL)seekToTime:(CMTime)time completionHandler:(void(^)(CMTime time, NSError * error))completionHandler;

- (NSError *)nextPacket:(SGPacket *)packet;

@end
