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

typedef NS_ENUM(uint32_t, SGPlayerItemState)
{
    SGPlayerItemStateNone,
    SGPlayerItemStateOpening,
    SGPlayerItemStateOpened,
    SGPlayerItemStateReading,
    SGPlayerItemStateClosed,
    SGPlayerItemStateFinished,
    SGPlayerItemStateFailed,
};

@protocol SGPlayerItemDelegate <NSObject>

- (void)playerItem:(SGPlayerItem *)playerItem didChangeState:(SGPlayerItemState)state;
- (void)playerItem:(SGPlayerItem *)playerItem didChangeCapacity:(SGCapacity *)capacity track:(SGTrack *)track;

@end

@interface SGPlayerItem (Internal)

@property (nonatomic, weak) id <SGPlayerItemDelegate> delegate;

@property (nonatomic, strong) SGFrameFilter * audioFilter;
@property (nonatomic, strong) SGFrameFilter * videoFilter;

- (SGPlayerItemState)state;

- (BOOL)audioFinished;
- (BOOL)videoFinished;

- (SGCapacity *)capacity;
- (SGCapacity *)capacityWithTrack:(SGTrack *)track;

- (BOOL)open;
- (BOOL)start;
- (BOOL)close;

- (BOOL)seeking;
- (BOOL)seekable;
- (BOOL)seekToTime:(CMTime)time result:(SGSeekResultBlock)result;

- (__kindof SGFrame *)copyAudioFrame:(SGTimeReaderBlock)timeReader;
- (__kindof SGFrame *)copyVideoFrame:(SGTimeReaderBlock)timeReader;

@end
