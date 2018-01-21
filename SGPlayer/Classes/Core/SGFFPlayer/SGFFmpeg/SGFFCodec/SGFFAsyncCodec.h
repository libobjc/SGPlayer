//
//  SGFFAsyncCodec.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFCodec.h"
#import "SGFFPacketQueue.h"
#import "SGFFOutputRenderQueue.h"

@interface SGFFAsyncCodec : NSObject <SGFFCodec>

@property (nonatomic, assign) SGFFTimebase timebase;

@property (nonatomic, strong, readonly) SGFFPacketQueue * packetQueue;
@property (nonatomic, strong, readonly) SGFFOutputRenderQueue * outputRenderQueue;

@property (nonatomic, strong, readonly) NSOperationQueue * operationQueue;
@property (nonatomic, strong, readonly) NSInvocationOperation * decodeOperation;

- (void)decodeThread;
- (void)doFlushCodec;
- (id <SGFFFrame>)doDecode:(AVPacket)packet;
- (NSInteger)outputRenderQueueMaxCount;        // Default is 5.

@end
