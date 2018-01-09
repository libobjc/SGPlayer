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


typedef NS_ENUM(NSUInteger, SGPlayerState)
{
    SGPlayerStateNone = 0,
    SGPlayerStateBuffering = 1,
    SGPlayerStateReadyToPlay = 2,
    SGPlayerStatePlaying = 3,
    SGPlayerStateSuspend = 4,
    SGPlayerStateFinished = 5,
    SGPlayerStateFailed = 6,
};

typedef NS_ENUM(NSUInteger, SGPlayerBackgroundMode)
{
    SGPlayerBackgroundModeNothing,
    SGPlayerBackgroundModeAutoPlayAndPause,     // default
    SGPlayerBackgroundModeContinue,
};


#endif /* SGPlayerDefines_h */
