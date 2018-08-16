//
//  SGDefines.h
//  SGPlayer
//
//  Created by Single on 2018/6/25.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SGPlaybackState)
{
    SGPlaybackStateNone,
    SGPlaybackStatePlaying,
    SGPlaybackStateSeeking,
    SGPlaybackStatePaused,
    SGPlaybackStateFinished,
    SGPlaybackStateFailed,
};

typedef NS_ENUM(NSUInteger, SGLoadingState)
{
    SGLoadingStateNone,
    SGLoadingStateLoading,
    SGLoadingStatePaused,
    SGLoadingStateFinished,
    SGLoadingStateFailed,
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
