//
//  SGPlayerItem+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/25.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPlayerItem.h"
#import "SGAudioDescription.h"
#import "SGFrame.h"

@protocol SGPlayerItemDelegate;

/**
 *
 */
typedef NS_ENUM(int, SGPlayerItemState) {
    SGPlayerItemStateNone,
    SGPlayerItemStateOpening,
    SGPlayerItemStateOpened,
    SGPlayerItemStateReading,
    SGPlayerItemStateSeeking,
    SGPlayerItemStateFinished,
    SGPlayerItemStateClosed,
    SGPlayerItemStateFailed,
};

@interface SGPlayerItem ()

/**
 *
 */
@property (nonatomic, weak) id<SGPlayerItemDelegate> _Nullable delegate;

/**
 *
 */
- (SGPlayerItemState)state;

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (BOOL)start;

/**
 *
 */
- (BOOL)close;

/**
 *
 */
- (BOOL)seekable;

/**
 *
 */
- (BOOL)seekToTime:(CMTime)time result:(SGSeekResult _Nullable)result;

/**
 *
 */
- (SGCapacity * _Nonnull)capacityWithType:(SGMediaType)type;

/**
 *
 */
- (BOOL)isAvailable:(SGMediaType)type;

/**
 *
 */
- (BOOL)isFinished:(SGMediaType)type;

/**
 *
 */
@property (nonatomic, copy) SGAudioDescription * _Nullable audioDescription;

/**
 *
 */
- (__kindof SGFrame * _Nullable)copyAudioFrame:(SGTimeReader _Nullable)timeReader;
- (__kindof SGFrame * _Nullable)copyVideoFrame:(SGTimeReader _Nullable)timeReader;

@end

@protocol SGPlayerItemDelegate <NSObject>

/**
 *
 */
- (void)playerItem:(SGPlayerItem * _Nonnull)playerItem didChangeState:(SGPlayerItemState)state;

/**
 *
 */
- (void)playerItem:(SGPlayerItem * _Nonnull)playerItem didChangeCapacity:(SGCapacity * _Nonnull)capacity type:(SGMediaType)type;

@end
