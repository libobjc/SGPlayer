//
//  SGFFAsyncCodec.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFCodec.h"
#import "SGFFObjectQueue.h"

@interface SGFFAsyncCodec : NSObject <SGFFCodec>

@property (nonatomic, strong, readonly) SGFFObjectQueue * packetQueue;
@property (nonatomic, strong, readonly) SGFFObjectQueue * outputRenderQueue;
@property (nonatomic, assign) NSInteger outputRenderQueueMaxCount;               // Default is 5.

- (void)doFlushCodec;
- (NSArray <id <SGFFFrame>> *)doDecode:(SGFFPacket *)packet error:(NSError **)error;

@end
