//
//  SGPlayerItem+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/25.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPlayerItem.h"
#import "SGFrameFilter.h"

@protocol SGPlayerItemDelegate;

/**
 *
 */
typedef NS_ENUM(uint32_t, SGPlayerItemState) {
    SGPlayerItemStateNone,
    SGPlayerItemStateOpening,
    SGPlayerItemStateOpened,
    SGPlayerItemStateReading,
    SGPlayerItemStateSeeking,
    SGPlayerItemStateFinished,
    SGPlayerItemStateClosed,
    SGPlayerItemStateFailed,
};

@interface SGPlayerItem (Internal)

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
@property (nonatomic, strong) SGFrameFilter * _Nullable audioFilter;
@property (nonatomic, strong) SGFrameFilter * _Nullable videoFilter;

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
