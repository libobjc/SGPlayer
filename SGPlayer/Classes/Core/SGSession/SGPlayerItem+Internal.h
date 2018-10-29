//
//  SGPlayerItem+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/25.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPlayerItem.h"
#import "SGRenderable.h"

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

- (void)playerItemDidChangeState:(SGPlayerItem *)session;
- (void)playerItemDidChangeCapacity:(SGPlayerItem *)session;

@end

@interface SGPlayerItem (Internal)

@property (nonatomic, weak) id <SGPlayerItemDelegate> delegate;
@property (nonatomic, strong) id <SGRenderable> audioRenderable;
@property (nonatomic, strong) id <SGRenderable> videoRenderable;

- (SGPlayerItemState)state;

- (SGCapacity *)capacity;
- (NSArray <SGCapacity *> *)capacityWithTracks:(NSArray <SGTrack *> *)tracks renderables:(NSArray <id <SGRenderable>> *)renderables;

- (BOOL)open;
- (BOOL)start;
- (BOOL)close;

- (BOOL)seeking;
- (BOOL)seekable;
- (BOOL)seekToTime:(CMTime)time completionHandler:(void(^)(CMTime time, NSError * error))completionHandler;

@end
