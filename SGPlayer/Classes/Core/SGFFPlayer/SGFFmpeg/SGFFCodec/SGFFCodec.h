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
#import <AVFoundation/AVFoundation.h>
#import "SGDefines.h"
#import "SGFFFrame.h"
#import "SGFFPacket.h"

@protocol SGFFCodec;
@protocol SGFFCodecDelegate;


typedef NS_ENUM(NSUInteger, SGFFCodecState)
{
    SGFFCodecStateIdle,
    SGFFCodecStateOpening,
    SGFFCodecStateOpened,
    SGFFCodecStateDecoding,
    SGFFCodecStatePaused,
    SGFFCodecStateClosed,
    SGFFCodecStateFailed,
};


@protocol SGFFCodec <NSObject>

- (SGMediaType)mediaType;

@property (nonatomic, assign) int index;
@property (nonatomic, assign) CMTime timebase;
@property (nonatomic, assign) AVCodecParameters * codecpar;

@property (nonatomic, weak) id <SGFFCodecDelegate> delegate;

- (SGFFCodecState)state;

- (NSUInteger)count;
- (CMTime)duration;
- (long long)size;

- (BOOL)open;
- (void)pause;
- (void)resume;
- (void)flush;
- (void)close;

- (BOOL)putPacket:(SGFFPacket *)packet;

@end


@protocol SGFFCodecDelegate <NSObject>

- (void)codecDidChangeCapacity:(id <SGFFCodec>)codec;
- (void)codec:(id <SGFFCodec>)codec hasNewFrame:(id <SGFFFrame>)frame;

@end


#endif /* SGFFCodec_h */
