//
//  SGFFPacket.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFObjectPool.h"
#import "SGFFObjectQueue.h"
#import "SGFFTime.h"
#import "avformat.h"

@interface SGFFPacket : NSObject <SGFFObjectPoolItem, SGFFObjectQueueItem>

@property (nonatomic, assign, readonly) AVPacket * corePacket;

@property (nonatomic, assign, readonly) int index;
@property (nonatomic, assign, readonly) CMTime position;
@property (nonatomic, assign, readonly) CMTime duration;
@property (nonatomic, assign, readonly) long long size;

- (void)fillWithTimebase:(CMTime)timebase;

@end
