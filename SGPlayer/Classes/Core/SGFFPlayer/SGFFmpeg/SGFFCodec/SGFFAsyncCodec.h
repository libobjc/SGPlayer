//
//  SGFFAsyncCodec.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFCodec.h"
#import "SGFFObjectQueue.h"

@interface SGFFAsyncCodec : NSObject <SGFFCodec>

@property (nonatomic, strong, readonly) SGFFObjectQueue * packetQueue;

- (void)doFlushCodec;
- (NSArray <id <SGFFFrame>> *)doDecode:(SGFFPacket *)packet error:(NSError **)error;

@end
