//
//  SGDefines.h
//  SGPlayer
//
//  Created by Single on 2018/6/25.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

#if defined(__cplusplus)
#define SGPLAYER_EXTERN extern "C"
#else
#define SGPLAYER_EXTERN extern
#endif

typedef NS_ENUM(NSUInteger, SGMediaType) {
    SGMediaTypeUnknown  = 0,
    SGMediaTypeAudio    = 1,
    SGMediaTypeVideo    = 2,
    SGMediaTypeSubtitle = 3,
};

typedef NS_ENUM(NSUInteger, SGPlayerState) {
    SGPlayerStateNone      = 0,
    SGPlayerStatePreparing = 1,
    SGPlayerStateReady     = 2,
    SGPlayerStateFailed    = 3,
};

typedef NS_OPTIONS(NSUInteger, SGPlaybackState) {
    SGPlaybackStateNone     = 0,
    SGPlaybackStatePlaying  = 1 << 0,
    SGPlaybackStateSeeking  = 1 << 1,
    SGPlaybackStateFinished = 1 << 2,
};

typedef NS_ENUM(NSUInteger, SGLoadingState) {
    SGLoadingStateNone     = 0,
    SGLoadingStatePlaybale = 1,
    SGLoadingStateStalled  = 2,
    SGLoadingStateFinished = 3,
};

typedef NS_OPTIONS(NSUInteger, SGInfoAction) {
    SGInfoActionNone          = 0,
    SGInfoActionTimeCached    = 1 << 1,
    SGInfoActionTimePlayback  = 1 << 2,
    SGInfoActionTimeDuration  = 1 << 3,
    SGInfoActionTime          = SGInfoActionTimeCached | SGInfoActionTimePlayback | SGInfoActionTimeDuration,
    SGInfoActionStatePlayer   = 1 << 4,
    SGInfoActionStateLoading  = 1 << 5,
    SGInfoActionStatePlayback = 1 << 6,
    SGInfoActionState         = SGInfoActionStatePlayer | SGInfoActionStateLoading | SGInfoActionStatePlayback,
};

typedef struct {
    int num;
    int den;
} SGRational;

typedef struct {
    CMTime cached;
    CMTime playback;
    CMTime duration;
} SGTimeInfo;

typedef struct {
    SGPlayerState player;
    SGLoadingState loading;
    SGPlaybackState playback;
} SGStateInfo;

@class SGPlayer;

typedef void (^SGBlock)(void);
typedef void (^SGHandler)(SGPlayer *player);
typedef BOOL (^SGTimeReader)(CMTime *desire, BOOL *drop);
typedef void (^SGSeekResult)(CMTime time, NSError *error);
