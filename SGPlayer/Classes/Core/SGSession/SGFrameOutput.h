//
//  SGFrameOutput.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/22.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGCapacity.h"
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

NS_ASSUME_NONNULL_BEGIN

@interface SGFrameOutput : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithAsset:(SGAsset *)asset NS_DESIGNATED_INITIALIZER;

/**
 *
 */
@property (nonatomic, weak) id<SGFrameOutputDelegate> _Nullable delegate;

/**
 *
 */
@property (nonatomic, readonly) SGFrameOutputState state;

/**
 *
 */
@property (nonatomic, copy, readonly) NSError * _Nullable error;

/**
 *
 */
@property (nonatomic, copy, readonly) NSArray<SGTrack *> * _Nullable tracks;

/**
 *
 */
@property (nonatomic, copy, readonly) NSDictionary * _Nullable metadata;

/**
 *
 */
@property (nonatomic, readonly) CMTime duration;

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
- (BOOL)pause:(SGMediaType)type;

/**
 *
 */
- (BOOL)resume:(SGMediaType)type;

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
- (BOOL)selectTracks:(NSArray<SGTrack *> *)tracks;

/**
 *
 */
- (SGCapacity *)capacityWithType:(SGMediaType)type;

@end

@protocol SGFrameOutputDelegate <NSObject>

/**
 *
 */
- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeState:(SGFrameOutputState)state;

/**
 *
 */
- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeCapacity:(SGCapacity *)capacity type:(SGMediaType)type;

/**
 *
 */
- (void)frameOutput:(SGFrameOutput *)frameOutput didOutputFrame:(__kindof SGFrame *)frame;

@end

NS_ASSUME_NONNULL_END
