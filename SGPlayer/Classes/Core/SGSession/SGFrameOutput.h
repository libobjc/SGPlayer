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

typedef NS_ENUM(uint32_t, SGFrameOutputState) {
    SGFrameOutputStateNone,
    SGFrameOutputStateOpening,
    SGFrameOutputStateOpened,
    SGFrameOutputStateReading,
    SGFrameOutputStateSeeking,
    SGFrameOutputStateFinished,
    SGFrameOutputStateClosed,
    SGFrameOutputStateFailed,
};

@protocol SGFrameOutputDelegate;

@interface SGFrameOutput : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithAsset:(SGAsset *)asset;

@property (nonatomic, weak) id<SGFrameOutputDelegate> delegate;

- (NSError *)error;
- (SGFrameOutputState)state;

- (CMTime)duration;
- (NSDictionary *)metadata;
- (NSArray<SGTrack *> *)tracks;

- (BOOL)open;
- (BOOL)start;
- (BOOL)close;
- (BOOL)pause:(NSArray<SGTrack *> *)tracks;
- (BOOL)resume:(NSArray<SGTrack *> *)tracks;
- (BOOL)seekable;
- (BOOL)seekToTime:(CMTime)time result:(SGSeekResult)result;

@property (nonatomic, copy, readonly) NSArray<SGTrack *> * finishedTracks;
@property (nonatomic, copy, readonly) NSArray<SGTrack *> * selectedTracks;

- (BOOL)selectTracks:(NSArray<SGTrack *> *)tracks;

- (NSArray<SGCapacity *> *)capacityWithTrack:(NSArray<SGTrack *> *)tracks;

@end

@protocol SGFrameOutputDelegate <NSObject>

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeState:(SGFrameOutputState)state;
- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeCapacity:(SGCapacity *)capacity track:(SGTrack *)track;
- (void)frameOutput:(SGFrameOutput *)frameOutput didOutputFrame:(__kindof SGFrame *)frame;

@end
