//
//  SGFFAsyncDecoder.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFDecoder.h"
#import "SGObjectQueue.h"

@interface SGFFAsyncDecoder : NSObject <SGFFDecoder>

@property (nonatomic, strong, readonly) SGObjectQueue * packetQueue;

- (void)doFlush;
- (NSArray <__kindof SGFrame *> *)doDecode:(SGPacket *)packet;

@end
