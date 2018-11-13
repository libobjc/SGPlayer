//
//  SGFormatContext.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/13.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPacket.h"

@protocol SGFormatContextDelegate;

@interface SGFormatContext : NSObject

- (instancetype)initWithURL:(NSURL *)URL;

@property (nonatomic, weak) id <SGFormatContextDelegate> delegate;
@property (nonatomic, copy) NSDictionary * options;

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

@protocol SGFormatContextDelegate <NSObject>

- (BOOL)formatContextShouldAbortBlockingFunctions:(SGFormatContext *)formatContext;

@end
