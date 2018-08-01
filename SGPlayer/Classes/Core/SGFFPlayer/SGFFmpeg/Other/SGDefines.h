//
//  SGDefines.h
//  SGPlayer
//
//  Created by Single on 2018/6/25.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

#if defined(__cplusplus)
#define SGPLAYER_EXTERN extern "C"
#else
#define SGPLAYER_EXTERN extern
#endif

typedef NS_ENUM(NSUInteger, SGPlayerPlaybackState)
{
    SGPlayerPlaybackStateNone,
    SGPlayerPlaybackStatePlaying,
    SGPlayerPlaybackStateSeeking,
    SGPlayerPlaybackStatePaused,
    SGPlayerPlaybackStateStopped,
    SGPlayerPlaybackStateFinished,
    SGPlayerPlaybackStateFailed,
};

typedef NS_ENUM(NSUInteger, SGPlayerLoadingState)
{
    SGPlayerLoadingStateNone,
    SGPlayerLoadingStateLoading,
    SGPlayerLoadingStatePaused,
    SGPlayerLoadingStateStoped,
    SGPlayerLoadingStateFinished,
    SGPlayerLoadingStateFailed,
};

typedef NS_ENUM(NSUInteger, SGPlayerBackgroundMode)
{
    SGPlayerBackgroundModeAutoPlayAndPause,
    SGPlayerBackgroundModeContinue,
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
