//
//  SGDefines.h
//  SGPlayer
//
//  Created by Single on 2018/6/25.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

typedef NS_ENUM(uint32_t, SGPlayerStatus) {
    SGPlayerStatusNone,
    SGPlayerStatusPreparing,
    SGPlayerStatusReady,
    SGPlayerStatusFailed,
};

typedef NS_OPTIONS(uint32_t, SGPlaybackState) {
    SGPlaybackStatePlaying  = 1 << 0,
    SGPlaybackStateSeeking  = 1 << 1,
    SGPlaybackStateFinished = 1 << 2,
};

typedef NS_ENUM(uint32_t, SGLoadingState) {
    SGLoadingStateNone,
    SGLoadingStatePlaybale,
    SGLoadingStateStalled,
    SGLoadingStateFinished,
};

typedef NS_ENUM(uint32_t, SGMediaType) {
    SGMediaTypeUnknown,
    SGMediaTypeAudio,
    SGMediaTypeVideo,
    SGMediaTypeSubtitle,
};

typedef NS_ENUM(uint32_t, SGDisplayMode) {
    SGDisplayModePlane,
    SGDisplayModeVR,
    SGDisplayModeVRBox,
};

typedef NS_ENUM(uint32_t, SGScalingMode) {
    SGScalingModeResize,
    SGScalingModeResizeAspect,
    SGScalingModeResizeAspectFill,
};

typedef void (^SGBlock)(void);
typedef void (^SGSeekResult)(CMTime time, NSError *error);
typedef BOOL (^SGTimeReader)(CMTime *desire, BOOL *drop);
