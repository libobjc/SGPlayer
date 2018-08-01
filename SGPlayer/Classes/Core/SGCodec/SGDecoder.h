//
//  SGDecoder.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#ifndef SGDecoder_h
#define SGDecoder_h


#import <Foundation/Foundation.h>
#import "SGFrame.h"
#import "SGPacket.h"

@protocol SGDecoder;
@protocol SGDecoderDelegate;

typedef NS_ENUM(NSUInteger, SGDecoderState)
{
    SGDecoderStateIdle,
    SGDecoderStateDecoding,
    SGDecoderStatePaused,
    SGDecoderStateStoped,
};

@protocol SGDecoder <NSObject>

- (SGMediaType)mediaType;

@property (nonatomic, weak) id <SGDecoderDelegate> delegate;
@property (nonatomic, assign) int index;
@property (nonatomic, assign) CMTime timebase;
@property (nonatomic, assign) AVCodecParameters * codecpar;

- (SGDecoderState)state;

- (CMTime)duration;
- (long long)size;
- (NSUInteger)count;

- (BOOL)startDecoding;
- (void)pauseDecoding;
- (void)resumeDecoding;
- (void)stopDecoding;

- (BOOL)putPacket:(SGPacket *)packet;
- (void)flush;

@end

@protocol SGDecoderDelegate <NSObject>

- (void)decoderDidChangeCapacity:(id <SGDecoder>)decoder;
- (void)decoder:(id <SGDecoder>)decoder hasNewFrame:(__kindof SGFrame *)frame;

@end

#endif /* SGDecoder_h */
