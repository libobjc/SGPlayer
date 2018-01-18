//
//  SGFFCodec.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#ifndef SGFFCodec_h
#define SGFFCodec_h


#import <Foundation/Foundation.h>
#import "avformat.h"


@protocol SGFFCodec <NSObject>

- (void)open;
- (void)close;
- (void)putPacket:(AVPacket)packet;

- (void)setTimebase:(AVRational)timebase;
- (AVRational)timebase;

- (long long)duration;
- (long long)packetDuration;
- (long long)frameDuration;
- (long long)size;
- (long long)packetSize;
- (long long)frameSize;

@end


#endif /* SGFFCodec_h */
