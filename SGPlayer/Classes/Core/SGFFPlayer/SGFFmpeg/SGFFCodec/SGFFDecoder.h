//
//  SGFFDecoder.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#ifndef SGFFDecoder_h
#define SGFFDecoder_h


#import <Foundation/Foundation.h>
#import "SGFFFrame.h"
#import "SGFFPacket.h"

@protocol SGFFDecoder;
@protocol SGFFDecoderDelegate;

typedef NS_ENUM(NSUInteger, SGFFDecoderState)
{
    SGFFDecoderStateIdle,
    SGFFDecoderStateOpening,
    SGFFDecoderStateOpened,
    SGFFDecoderStateDecoding,
    SGFFDecoderStatePaused,
    SGFFDecoderStateClosed,
    SGFFDecoderStateFailed,
};

@protocol SGFFDecoder <NSObject>

- (SGMediaType)mediaType;

@property (nonatomic, weak) id <SGFFDecoderDelegate> delegate;

@property (nonatomic, assign) int index;
@property (nonatomic, assign) CMTime timebase;
@property (nonatomic, assign) AVCodecParameters * codecpar;

- (SGFFDecoderState)state;
- (CMTime)duration;
- (long long)size;
- (NSUInteger)count;

- (BOOL)open;
- (void)pause;
- (void)resume;
- (void)flush;
- (void)close;

- (BOOL)putPacket:(SGFFPacket *)packet;

@end

@protocol SGFFDecoderDelegate <NSObject>

- (void)decoderDidChangeCapacity:(id <SGFFDecoder>)decoder;
- (void)decoder:(id <SGFFDecoder>)decoder hasNewFrame:(id <SGFFFrame>)frame;

@end

#endif /* SGFFDecoder_h */
