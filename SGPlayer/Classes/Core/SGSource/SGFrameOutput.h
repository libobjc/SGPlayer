//
//  SGFrameOutput.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/22.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGAsset.h"
#import "SGFrame.h"

@protocol SGFrameOutputDelegate;

typedef NS_ENUM(NSUInteger, SGFrameOutputState)
{
    SGFrameOutputStateNone,
    SGFrameOutputStateOpening,
    SGFrameOutputStateOpened,
    SGFrameOutputStateReading,
    SGFrameOutputStatePaused,
    SGFrameOutputStateSeeking,
    SGFrameOutputStateFinished,
    SGFrameOutputStateClosed,
    SGFrameOutputStateFailed,
};

@interface SGFrameOutput : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithAsset:(SGAsset *)asset;

@property (nonatomic, weak) id <SGFrameOutputDelegate> delegate;

- (SGFrameOutputState)state;
- (NSError *)error;
- (CMTime)duration;
- (NSDictionary *)metadata;
- (NSArray <SGStream *> *)streams;
- (NSArray <SGStream *> *)audioStreams;
- (NSArray <SGStream *> *)videoStreams;
- (NSArray <SGStream *> *)otherStreams;
- (NSArray <SGStream *> *)selectedStreams;
- (BOOL)setSelectedStreams:(NSArray <SGStream *> *)selectedStreams;
- (BOOL)duration:(CMTime *)duration size:(int64_t *)size count:(NSUInteger *)count stream:(SGStream *)stream;

- (NSError *)open;
- (NSError *)start;
- (NSError *)close;
- (NSError *)pause:(NSArray <SGStream *> *)streams;
- (NSError *)resume:(NSArray <SGStream *> *)streams;
- (NSError *)seekable;
- (NSError *)seekToTime:(CMTime)time completionHandler:(void(^)(CMTime time, NSError * error))completionHandler;

@end

@protocol SGFrameOutputDelegate <NSObject>

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeState:(SGFrameOutputState)state;
- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeDuration:(CMTime)duration size:(int64_t)size count:(NSUInteger)count stream:(SGStream *)stream;
- (void)frameOutput:(SGFrameOutput *)frameOutput didOutputFrame:(SGFrame *)frame;

@end
