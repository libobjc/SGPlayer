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

- (BOOL)open;
- (BOOL)close;
- (BOOL)seeking;
- (BOOL)seekable;
- (BOOL)seekToTime:(CMTime)time completionHandler:(void(^)(CMTime time, NSError * error))completionHandler;


- (BOOL)empty;
- (BOOL)emptyWithMainMediaType:(SGMediaType)mainMediaType;
- (CMTime)loadedDuration;
- (CMTime)loadedDurationWithMainMediaType:(SGMediaType)mainMediaType;
- (long long)loadedSize;
- (long long)loadedSizeWithMainMediaType:(SGMediaType)mainMediaType;
@property (nonatomic, assign, readonly) BOOL audioEnable;
@property (nonatomic, assign, readonly) BOOL audioEmpty;
@property (nonatomic, assign, readonly) CMTime audioLoadedDuration;
@property (nonatomic, assign, readonly) long long audioLoadedSize;
@property (nonatomic, assign, readonly) BOOL videoEnable;
@property (nonatomic, assign, readonly) BOOL videoEmpty;
@property (nonatomic, assign, readonly) CMTime videoLoadedDuration;
@property (nonatomic, assign, readonly) long long videoLoadedSize;

@end
