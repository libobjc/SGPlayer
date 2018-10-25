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

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithURL:(NSURL *)URL;

@property (nonatomic, strong) id object;

@property (nonatomic, weak) id <SGFormatContextDelegate> delegate;
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

@protocol SGFormatContextDelegate <NSObject>

- (BOOL)formatContextShouldAbortBlockingFunctions:(SGFormatContext *)formatContext;

@end
