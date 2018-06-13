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
#import "SGFFFrame.h"
#import "SGFFPacket.h"
#import "SGFFOutputRender.h"

@protocol SGFFCodec;
@protocol SGFFCodecCapacityDelegate;
@protocol SGFFCodecProcessingDelegate;


typedef NS_ENUM(NSUInteger, SGFFCodecType)
{
    SGFFCodecTypeUnknown,
    SGFFCodecTypeVideo,
    SGFFCodecTypeAudio,
    SGFFCodecTypeSubtitle,
};


typedef NS_ENUM(NSUInteger, SGFFCodecState)
{
    SGFFCodecStateIdle,
    SGFFCodecStateOpening,
    SGFFCodecStateOpened,
    SGFFCodecStateDecoding,
    SGFFCodecStateClosed,
    SGFFCodecStateFailed,
};


@protocol SGFFCodec <NSObject>

- (SGFFCodecType)type;

@property (nonatomic, assign) CMTime timebase;
@property (nonatomic, assign) AVCodecParameters * codecpar;

@property (nonatomic, weak) id <SGFFCodecCapacityDelegate> capacityDelegate;
@property (nonatomic, weak) id <SGFFCodecProcessingDelegate> processingDelegate;

- (SGFFCodecState)state;

- (CMTime)duration;
- (long long)size;

- (BOOL)open;
- (void)flush;
- (void)close;

- (BOOL)putPacket:(SGFFPacket *)packet;
- (id <SGFFOutputRender>)getOutputRender;
- (id <SGFFOutputRender>)getOutputRenderWithPositionHandler:(BOOL (^)(CMTime * current, CMTime * expect))positionHandler;

@end


@protocol SGFFCodecCapacityDelegate <NSObject>

- (void)codecDidChangeCapacity:(id <SGFFCodec>)codec;

@end


@protocol SGFFCodecProcessingDelegate <NSObject>

- (id <SGFFFrame>)codec:(id <SGFFCodec>)codec processingFrame:(id <SGFFFrame>)frame;
- (id <SGFFOutputRender>)codec:(id <SGFFCodec>)codec processingOutputRender:(id <SGFFFrame>)frame;

@end


#endif /* SGFFCodec_h */
