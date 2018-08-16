//
//  SGAsyncDecoder.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGDecoder.h"
#import "SGObjectQueue.h"

@interface SGAsyncDecoder : NSObject <SGDecoder>

@property (nonatomic, strong, readonly) SGObjectQueue * packetQueue;
@property (nonatomic, assign) AVCodecParameters * codecpar;

- (void)doSetup;
- (void)doDestory;
- (void)doFlush;
- (NSArray <__kindof SGFrame *> *)doDecode:(SGPacket *)packet;

@end
