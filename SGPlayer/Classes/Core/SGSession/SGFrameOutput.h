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

/**
 *
 */
typedef NS_ENUM(int, SGFrameOutputState) {
    SGFrameOutputStateNone,
    SGFrameOutputStateOpening,
    SGFrameOutputStateOpened,
    SGFrameOutputStateReading,
    SGFrameOutputStateSeeking,
    SGFrameOutputStateFinished,
    SGFrameOutputStateClosed,
    SGFrameOutputStateFailed,
};

@interface SGFrameOutput : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithAsset:(SGAsset * _Nonnull)asset NS_DESIGNATED_INITIALIZER;

/**
 *
 */
@property (nonatomic, weak) id<SGFrameOutputDelegate> _Nullable delegate;

/**
 *
 */
- (NSError * _Nullable)error;

/**
 *
 */
- (SGFrameOutputState)state;

/**
 *
 */
- (CMTime)duration;

/**
 *
 */
- (NSDictionary * _Nullable)metadata;

/**
 *
 */
- (NSArray<SGTrack *> * _Nullable)tracks;

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (BOOL)start;

/**
 *
 */
- (BOOL)close;

/**
 *
 */
- (BOOL)pause:(NSArray<SGTrack *> * _Nonnull)tracks;

/**
 *
 */
- (BOOL)resume:(NSArray<SGTrack *> * _Nonnull)tracks;

/**
 *
 */
- (BOOL)seekable;

/**
 *
 */
- (BOOL)seekToTime:(CMTime)time result:(SGSeekResult _Nullable)result;

/**
 *
 */
- (NSArray<SGTrack *> * _Nullable)selectedTracks;

/**
 *
 */
- (BOOL)selectTracks:(NSArray<SGTrack *> * _Nonnull)tracks;

/**
 *
 */
- (NSArray<SGTrack *> * _Nullable)finishedTracks;

/**
 *
 */
- (NSArray<SGCapacity *> * _Nonnull)capacityWithTrack:(NSArray<SGTrack *> * _Nonnull)tracks;

@end

@protocol SGFrameOutputDelegate <NSObject>

/**
 *
 */
- (void)frameOutput:(SGFrameOutput * _Nonnull)frameOutput didChangeState:(SGFrameOutputState)state;

/**
 *
 */
- (void)frameOutput:(SGFrameOutput * _Nonnull)frameOutput didChangeCapacity:(SGCapacity * _Nonnull)capacity track:(SGTrack * _Nonnull)track;

/**
 *
 */
- (void)frameOutput:(SGFrameOutput * _Nonnull)frameOutput didOutputFrame:(__kindof SGFrame * _Nonnull)frame;

@end
