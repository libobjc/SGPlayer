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
    SGFFDecoderStateDecoding,
    SGFFDecoderStatePaused,
    SGFFDecoderStateStoped,
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

- (BOOL)startDecoding;
- (void)pauseDecoding;
- (void)resumeDecoding;
- (void)stopDecoding;

- (BOOL)putPacket:(SGFFPacket *)packet;
- (void)flush;

@end

@protocol SGFFDecoderDelegate <NSObject>

- (void)decoderDidChangeCapacity:(id <SGFFDecoder>)decoder;
- (void)decoder:(id <SGFFDecoder>)decoder hasNewFrame:(id <SGFFFrame>)frame;

@end

#endif /* SGFFDecoder_h */
