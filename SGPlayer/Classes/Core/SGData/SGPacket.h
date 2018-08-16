//
//  SGPacket.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGObjectQueue.h"
#import "SGObjectPool.h"
#import "SGStream.h"

@interface SGPacket : NSObject <SGObjectPoolItem, SGObjectQueueItem>

@property (nonatomic, assign, readonly) AVPacket * corePacket;
@property (nonatomic, assign, readonly) AVCodecParameters * codecpar;
@property (nonatomic, assign, readonly) SGMediaType mediaType;

@property (nonatomic, assign, readonly) CMTime timebase;
@property (nonatomic, assign, readonly) CMTime offset;
@property (nonatomic, assign, readonly) CMTime scale;
@property (nonatomic, assign, readonly) CMTime timeStamp;
@property (nonatomic, assign, readonly) CMTime duration;
@property (nonatomic, assign, readonly) CMTime originalTimeStamp;
@property (nonatomic, assign, readonly) CMTime originalDuration;
@property (nonatomic, assign, readonly) CMTime decodeTimeStamp;
@property (nonatomic, assign, readonly) long long size;

- (void)fillWithStream:(SGStream *)stream;
- (void)fillWithStream:(SGStream *)stream offset:(CMTime)offset scale:(CMTime)scale;

@end
