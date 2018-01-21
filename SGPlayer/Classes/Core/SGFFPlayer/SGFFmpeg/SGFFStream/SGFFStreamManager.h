//
//  SGFFStreamManager.h
//  SGPlayer
//
//  Created by Single on 2018/1/18.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFStream.h"
#import "SGFFFrame.h"

@class SGFFStreamManager;

@protocol SGFFStreamManagerDelegate <NSObject>

- (void)streamManagerDidOpened:(SGFFStreamManager *)streamManager;
- (void)streamManagerDidFailed:(SGFFStreamManager *)streamManager;
- (id <SGFFCodec>)streamManager:(SGFFStreamManager *)streamManager codecForStream:(SGFFStream *)stream;

@end

@interface SGFFStreamManager : NSObject

- (instancetype)initWithStreams:(NSArray <SGFFStream *> *)streams delegate:(id <SGFFStreamManagerDelegate>)delegate;

@property (nonatomic, strong, readonly) NSArray <SGFFStream *> * streams;
@property (nonatomic, strong, readonly) NSArray <SGFFStream *> * videoStreams;
@property (nonatomic, strong, readonly) NSArray <SGFFStream *> * audioStreams;
@property (nonatomic, strong, readonly) NSArray <SGFFStream *> * subtitleStreams;
@property (nonatomic, strong, readonly) SGFFStream * currentVideoStream;
@property (nonatomic, strong, readonly) SGFFStream * currentAudioStream;
@property (nonatomic, strong, readonly) SGFFStream * currentSubtitleStream;

@property (nonatomic, copy, readonly) NSError * error;

- (void)open;
- (void)close;
- (BOOL)putPacket:(AVPacket)packet;

- (long long)size;

@end
