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
    SGDecoderStateNone,
    SGDecoderStateDecoding,
    SGDecoderStatePaused,
    SGDecoderStateClosed,
};

@protocol SGDecoder <NSObject>

- (SGMediaType)mediaType;

@property (nonatomic, weak) id <SGDecoderDelegate> delegate;
@property (nonatomic, assign) CMTime timebase;

- (SGDecoderState)state;
- (BOOL)empty;
- (CMTime)duration;
- (long long)size;
- (NSUInteger)count;

- (BOOL)open;
- (BOOL)pause;
- (BOOL)resume;
- (BOOL)close;

- (BOOL)putPacket:(SGPacket *)packet;
- (BOOL)flush;

@end

@protocol SGDecoderDelegate <NSObject>

- (void)decoderDidChangeState:(id <SGDecoder>)decoder;
- (void)decoderDidChangeCapacity:(id <SGDecoder>)decoder;
- (void)decoder:(id <SGDecoder>)decoder hasNewFrame:(__kindof SGFrame *)frame;

@end

#endif /* SGDecoder_h */
