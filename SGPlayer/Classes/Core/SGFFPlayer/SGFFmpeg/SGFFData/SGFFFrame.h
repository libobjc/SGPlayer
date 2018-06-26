//
//  SGFFFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/18.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDefines.h"
#import "SGFFPacket.h"
#import "SGFFObjectPool.h"
#import "SGFFObjectQueue.h"

@class SGFFAudioFrame;
@class SGFFVideoFrame;

@interface SGFFFrame : NSObject <SGFFObjectPoolItem, SGFFObjectQueueItem>

- (SGMediaType)mediaType;

@property (nonatomic, assign) CMTime position;
@property (nonatomic, assign) CMTime duration;
@property (nonatomic, assign) long long size;

- (SGFFAudioFrame *)audioFrame;
- (SGFFVideoFrame *)videoFrame;
- (AVFrame *)coreFrame;

- (void)fillWithTimebase:(CMTime)timebase;
- (void)fillWithTimebase:(CMTime)timebase packet:(SGFFPacket *)packet;

@end
