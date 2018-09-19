//
//  SGFormatContext.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/13.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPacket.h"

@class SGFormatContext;

@protocol SGFormatContextDelegate <NSObject>

- (BOOL)formatContextShouldAbortBlockingFunctions:(SGFormatContext *)formatContext;

@end

@interface SGFormatContext : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithURL:(NSURL *)URL;

@property (nonatomic, strong) id object;

@property (nonatomic, weak) id <SGFormatContextDelegate> delegate;
@property (nonatomic, copy) NSDictionary * options;

@property (nonatomic, copy, readonly) NSError * error;

- (BOOL)open;
- (BOOL)close;

- (BOOL)seekable;
- (BOOL)seekableToTime:(CMTime)time;
- (NSError *)seekToTime:(CMTime)time;

- (NSError *)nextPacket:(SGPacket *)packet;

@end
