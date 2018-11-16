//
//  SGPlayerItem+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/25.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPlayerItem.h"
#import "SGRenderable.h"
#import "SGFrameFilter.h"

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

@protocol SGPlayerItemDelegate <NSObject>

- (void)playerItem:(SGPlayerItem *)playerItem didChangeState:(SGPlayerItemState)state;
- (void)playerItem:(SGPlayerItem *)playerItem didChangeCapacity:(SGCapacity *)capacity type:(SGMediaType)type;

@end

@interface SGPlayerItem (Internal)

@property (nonatomic, weak) id <SGPlayerItemDelegate> delegate;

- (SGPlayerItemState)state;

- (BOOL)open;
- (BOOL)start;
- (BOOL)close;
- (BOOL)seekable;
- (BOOL)seekToTime:(CMTime)time result:(SGSeekResultBlock)result;

- (SGCapacity *)capacity;
- (SGCapacity *)capacityWithType:(SGMediaType)type;

- (BOOL)isAudioFinished;
- (BOOL)isVideoFinished;
- (BOOL)isAudioAvailable;
- (BOOL)isVideoAvailable;

@property (nonatomic, strong) SGFrameFilter * audioFilter;
@property (nonatomic, strong) SGFrameFilter * videoFilter;

- (__kindof SGFrame *)copyAudioFrame:(SGTimeReaderBlock)timeReader;
- (__kindof SGFrame *)copyVideoFrame:(SGTimeReaderBlock)timeReader;

@end
