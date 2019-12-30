//
//  SGFrameOutput.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/22.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDemuxerOptions.h"
#import "SGDecoderOptions.h"
#import "SGCapacity.h"
#import "SGAsset.h"
#import "SGFrame.h"

@protocol SGFrameOutputDelegate;

/**
 *
 */
typedef NS_ENUM(NSUInteger, SGFrameOutputState) {
    SGFrameOutputStateNone     = 0,
    SGFrameOutputStateOpening  = 1,
    SGFrameOutputStateOpened   = 2,
    SGFrameOutputStateReading  = 3,
    SGFrameOutputStateSeeking  = 4,
    SGFrameOutputStateFinished = 5,
    SGFrameOutputStateClosed   = 6,
    SGFrameOutputStateFailed   = 7,
};

@interface SGFrameOutput : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithAsset:(SGAsset *)asset;

/**
 *
 */
@property (nonatomic, copy) SGDemuxerOptions *demuxerOptions;

/**
 *
 */
@property (nonatomic, copy) SGDecoderOptions *decoderOptions;

/**
 *
 */
@property (nonatomic, weak) id<SGFrameOutputDelegate> delegate;

/**
 *
 */
@property (nonatomic, readonly) SGFrameOutputState state;

/**
 *
 */
@property (nonatomic, copy, readonly) NSError *error;

/**
 *
 */
@property (nonatomic, copy, readonly) NSArray<SGTrack *> *tracks;

/**
 *
 */
@property (nonatomic, copy, readonly) NSArray<SGTrack *> *selectedTracks;

/**
 *
 */
@property (nonatomic, copy, readonly) NSDictionary *metadata;

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
- (BOOL)seekToTime:(CMTime)time;

/**
 *
 */
- (BOOL)seekToTime:(CMTime)time result:(SGSeekResult)result;

/**
 *
 */
- (BOOL)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter result:(SGSeekResult)result;

/**
 *
 */
- (BOOL)selectTracks:(NSArray<SGTrack *> *)tracks;

/**
 *
 */
- (SGCapacity)capacityWithType:(SGMediaType)type;

@end

@protocol SGFrameOutputDelegate <NSObject>

/**
 *
 */
- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeState:(SGFrameOutputState)state;

/**
 *
 */
- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeCapacity:(SGCapacity)capacity type:(SGMediaType)type;

/**
 *
 */
- (void)frameOutput:(SGFrameOutput *)frameOutput didOutputFrames:(NSArray<__kindof SGFrame *> *)frames needsDrop:(BOOL(^)(void))needsDrop;

@end
