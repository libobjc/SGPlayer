//
//  SGPlayerItem.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGAsset.h"
#import "SGStream.h"

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

@class SGPlayerItem;

@protocol SGPlayerItemDelegate <NSObject>

- (void)sessionDidChangeState:(SGPlayerItem *)session;

@end

@interface SGPlayerItem : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithAsset:(SGAsset *)asset;

@property (nonatomic, weak) id <SGPlayerItemDelegate> delegate;

- (SGPlayerItemState)state;
- (CMTime)duration;
- (NSError *)error;
- (NSDictionary *)metadata;
- (NSArray <SGStream *> *)streams;
- (NSArray <SGStream *> *)audioStreams;
- (NSArray <SGStream *> *)videoStreams;
- (NSArray <SGStream *> *)otherStreams;
- (NSArray <SGStream *> *)selectedStreams;
- (BOOL)setSelectedStreams:(NSArray <SGStream *> *)selectedStreams;
- (SGStream *)selectedAudioStream;
- (SGStream *)selectedVideoStream;

- (BOOL)open;
- (BOOL)close;
- (BOOL)seeking;
- (BOOL)seekable;
- (BOOL)seekToTime:(CMTime)time completionHandler:(void(^)(CMTime time, NSError * error))completionHandler;

@end
