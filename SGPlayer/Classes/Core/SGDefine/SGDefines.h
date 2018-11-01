//
//  SGDefines.h
//  SGPlayer
//
//  Created by Single on 2018/6/25.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, SGPlayerStatus)
{
    SGPlayerStatusNone,
    SGPlayerStatusPreparing,
    SGPlayerStatusReady,
    SGPlayerStatusFailed,
};

typedef NS_OPTIONS(NSUInteger, SGPlaybackState)
{
    SGPlaybackStatePlaying = 1 << 0,
    SGPlaybackStateSeeking = 1 << 1,
    SGPlaybackStateFinished = 1 << 2,
};

typedef NS_ENUM(NSUInteger, SGLoadingState)
{
    SGLoadingStateNone,
    SGLoadingStatePlaybale,
    SGLoadingStateStalled,
    SGLoadingStateFinished,
};

typedef NS_ENUM(NSUInteger, SGMediaType)
{
    SGMediaTypeUnknown,
    SGMediaTypeAudio,
    SGMediaTypeVideo,
    SGMediaTypeSubtitle,
};

typedef NS_ENUM(NSUInteger, SGDisplayMode)
{
    SGDisplayModePlane,
    SGDisplayModeVR,
    SGDisplayModeVRBox,
};

typedef NS_ENUM(NSUInteger, SGScalingMode)
{
    SGScalingModeResize,
    SGScalingModeResizeAspect,
    SGScalingModeResizeAspectFill,
};

typedef NS_OPTIONS(NSUInteger, SGStateOption)
{
    SGStateOptionPrepare = 1 << 0,
    SGStateOptionPlayback = 1 << 1,
    SGStateOptionLoading = 1 << 2,
};

typedef NS_OPTIONS(NSUInteger, SGTimeOption)
{
    SGTimeOptionPlayback = 1 << 0,
    SGTimeOptionLoaded = 1 << 1,
    SGTimeOptionDuration = 1 << 2,
};

typedef void (^SGBlock)(void);
typedef void (^SGSeekResultBlock)(CMTime time, NSError * error);
typedef BOOL (^SGTimeReaderBlock)(CMTime * current, CMTime * desire, BOOL * drop);
