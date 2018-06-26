//
//  SGFFAsyncDecoder.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFDecoder.h"
#import "SGFFObjectQueue.h"

@interface SGFFAsyncDecoder : NSObject <SGFFDecoder>

@property (nonatomic, strong, readonly) SGFFObjectQueue * packetQueue;

- (void)doFlushCodec;
- (NSArray <id <SGFFFrame>> *)doDecode:(SGFFPacket *)packet error:(NSError **)error;

@end
