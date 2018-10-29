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

- (void)sessionDidChangeState:(SGPlayerItem *)session;
- (void)sessionDidChangeCapacity:(SGPlayerItem *)session;

@end

@interface SGPlayerItem (Internal)

@property (nonatomic, weak) id <SGPlayerItemDelegate> delegate;
@property (nonatomic, strong) id <SGRenderable> audioRenderable;
@property (nonatomic, strong) id <SGRenderable> videoRenderable;

- (SGPlayerItemState)state;

- (SGCapacity *)bestCapacity;
- (NSArray <SGCapacity *> *)capacityWithTracks:(NSArray <SGTrack *> *)tracks renderables:(NSArray <id <SGRenderable>> *)renderables;

- (BOOL)open;
- (BOOL)start;
- (BOOL)close;

@end
