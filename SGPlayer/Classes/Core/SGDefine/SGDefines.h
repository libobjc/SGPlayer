//
//  SGDefines.h
//  SGPlayer
//
//  Created by Single on 2018/6/25.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SGPrepareState)
{
    SGPrepareStateNone,
    SGPrepareStatePreparing,
    SGPrepareStateFinished,
};

typedef NS_ENUM(NSUInteger, SGPlaybackState)
{
    SGPlaybackStateNone,
    SGPlaybackStatePlaying,
    SGPlaybackStatePaused,
    SGPlaybackStateFinished,
};

typedef NS_ENUM(NSUInteger, SGLoadingState)
{
    SGLoadingStateNone,
    SGLoadingStateLoading,
    SGLoadingStatePaused,
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
