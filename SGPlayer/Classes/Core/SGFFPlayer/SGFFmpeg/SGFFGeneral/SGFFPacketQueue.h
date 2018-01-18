//
//  SGFFPacketQueue.h
//  SGPlayer
//
//  Created by Single on 2018/1/18.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "avformat.h"

@interface SGFFPacketQueue : NSObject

- (NSInteger)count;
- (long long)duration;
- (long long)size;

- (void)putPacket:(AVPacket)packet;
- (AVPacket)getPacketSync;
- (AVPacket)getPacketAsync;

- (void)flush;
- (void)destroy;

@end
