//
//  SGDemuxable.h
//  SGPlayer iOS
//
//  Created by Single on 2018/9/25.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPacket.h"
#import "SGTrack.h"

@protocol SGDemuxableDelegate;

@protocol SGDemuxable <NSObject>

@property (nonatomic, weak) id <SGDemuxableDelegate> delegate;
@property (nonatomic, copy) NSDictionary * options;

- (CMTime)duration;
- (NSDictionary *)metadata;
- (NSArray <SGTrack *> *)tracks;

- (NSError *)open;
- (NSError *)close;
- (NSError *)seekable;
- (NSError *)seekToTime:(CMTime)time;
- (NSError *)nextPacket:(SGPacket **)packet;

@end

@protocol SGDemuxableDelegate <NSObject>

- (BOOL)demuxableShouldAbortBlockingFunctions:(id <SGDemuxable>)demuxable;

@end
