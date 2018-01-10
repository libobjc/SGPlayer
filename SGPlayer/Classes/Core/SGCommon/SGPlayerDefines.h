//
//  SGPlayerDefines.h
//  SGPlayer
//
//  Created by Single on 2018/1/9.
//  Copyright © 2018年 single. All rights reserved.
//

#ifndef SGPlayerDefines_h
#define SGPlayerDefines_h


#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, SGPlayerPlaybackState)
{
    SGPlayerPlaybackStateIdle,
    SGPlayerPlaybackStatePlaying,
    SGPlayerPlaybackStateSeeking,
    SGPlayerPlaybackStatePaused,
    SGPlayerPlaybackStateInterrupted,
    SGPlayerPlaybackStateStopped,
    SGPlayerPlaybackStateFinished,
    SGPlayerPlaybackStateFailed,
};

typedef NS_ENUM(NSUInteger, SGPlayerLoadState)
{
    SGPlayerLoadStateIdle,
    SGPlayerLoadStateLoading,
    SGPlayerLoadStatePlayable,
};

typedef NS_ENUM(NSUInteger, SGPlayerBackgroundMode)
{
    SGPlayerBackgroundModeNothing,
    SGPlayerBackgroundModeAutoPlayAndPause,     // default
    SGPlayerBackgroundModeContinue,
};


#endif /* SGPlayerDefines_h */
