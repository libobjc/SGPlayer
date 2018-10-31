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

typedef NS_ENUM(NSUInteger, SGPlayerItemState)
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
@property (nonatomic, assign) BOOL audioFinished;
@property (nonatomic, assign) BOOL videoFinished;

- (SGPlayerItemState)state;

- (SGCapacity *)capacity;
- (SGCapacity *)capacityWithTrack:(SGTrack *)track;

- (BOOL)open;
- (BOOL)start;
- (BOOL)close;

- (BOOL)seeking;
- (BOOL)seekable;
- (BOOL)seekToTime:(CMTime)time completionHandler:(void(^)(CMTime time, NSError * error))completionHandler;

- (__kindof SGFrame *)nextAudioFrame;
- (__kindof SGFrame *)nextVideoFrameWithPTSHandler:(BOOL (^)(CMTime *, CMTime *))ptsHandler drop:(BOOL)drop;

@end
