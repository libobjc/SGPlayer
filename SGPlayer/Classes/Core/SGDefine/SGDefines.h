//
//  SGDefines.h
//  SGPlayer
//
//  Created by Single on 2018/6/25.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

typedef NS_ENUM(int, SGPlayerStatus) {
    SGPlayerStatusNone,
    SGPlayerStatusPreparing,
    SGPlayerStatusReady,
    SGPlayerStatusFailed,
};

typedef NS_OPTIONS(int, SGPlaybackState) {
    SGPlaybackStatePlaying  = 1 << 0,
    SGPlaybackStateSeeking  = 1 << 1,
    SGPlaybackStateFinished = 1 << 2,
};

typedef NS_ENUM(int, SGLoadingState) {
    SGLoadingStateNone,
    SGLoadingStatePlaybale,
    SGLoadingStateStalled,
    SGLoadingStateFinished,
};

typedef NS_ENUM(int, SGMediaType) {
    SGMediaTypeUnknown,
    SGMediaTypeAudio,
    SGMediaTypeVideo,
    SGMediaTypeSubtitle,
};

typedef NS_ENUM(int, SGDisplayMode) {
    SGDisplayModePlane,
    SGDisplayModeVR,
    SGDisplayModeVRBox,
};

typedef NS_ENUM(int, SGScalingMode) {
    SGScalingModeResize,
    SGScalingModeResizeAspect,
    SGScalingModeResizeAspectFill,
};

typedef void (^SGBlock)(void);
typedef void (^SGSeekResult)(CMTime time, NSError *error);
typedef BOOL (^SGTimeReader)(CMTime *desire, BOOL *drop);
