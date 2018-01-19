//
//  SGFFAsyncCodec.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFCodec.h"
#import "SGFFFrameQueue.h"
#import "SGFFPacketQueue.h"

@interface SGFFAsyncCodec : NSObject <SGFFCodec>

@property (nonatomic, strong, readonly) SGFFFrameQueue * frameQueue;
@property (nonatomic, strong, readonly) SGFFPacketQueue * packetQueue;

@property (nonatomic, strong, readonly) NSOperationQueue * operationQueue;
@property (nonatomic, strong, readonly) NSInvocationOperation * decodeOperation;

+ (AVRational)defaultTimebase;
- (void)decodeThread;

@end
