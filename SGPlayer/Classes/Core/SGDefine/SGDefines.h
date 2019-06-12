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

typedef NS_ENUM(int, SGMediaType) {
    SGMediaTypeUnknown  = 0,
    SGMediaTypeAudio    = 1,
    SGMediaTypeVideo    = 2,
    SGMediaTypeSubtitle = 3,
};

typedef NS_ENUM(int, SGPlayerState) {
    SGPlayerStateNone      = 0,
    SGPlayerStatePreparing = 1,
    SGPlayerStateReady     = 2,
    SGPlayerStateFailed    = 3,
};

typedef NS_OPTIONS(int, SGPlaybackState) {
    SGPlaybackStateNone     = 0,
    SGPlaybackStatePlaying  = 1 << 0,
    SGPlaybackStateSeeking  = 1 << 1,
    SGPlaybackStateFinished = 1 << 2,
};

typedef NS_ENUM(int, SGLoadingState) {
    SGLoadingStateNone     = 0,
    SGLoadingStatePlaybale = 1,
    SGLoadingStateStalled  = 2,
    SGLoadingStateFinished = 3,
};

typedef struct {
    SGPlayerState player;
    SGLoadingState loading;
    SGPlaybackState playback;
} SGStateInfo;

typedef struct {
    CMTime playback;
    CMTime duration;
    CMTime cached;
} SGTimingInfo;

typedef void (^SGBlock)(void);
typedef void (^SGSeekResult)(CMTime time, NSError *error);
typedef BOOL (^SGTimeReader)(CMTime *desire, BOOL *drop);
