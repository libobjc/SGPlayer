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
#import "SGFFFrame.h"
#import "SGFFOutput.h"
#import "avformat.h"

@protocol SGFFCodec;
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
    SGFFCodecStateOpened,
    SGFFCodecStateClosed,
    SGFFCodecStateFailed,
};


@protocol SGFFCodec <NSObject, SGFFOutputRenderSource>

+ (SGFFCodecType)type;

@property (nonatomic, weak) id <SGFFCodecProcessingDelegate> processingDelegate;
- (SGFFCodecState)state;

- (SGFFTimebase)timebase;
- (long long)duration;
- (long long)size;
- (double)durationForSeconds;

- (BOOL)open;
- (void)close;
- (BOOL)putPacket:(AVPacket)packet;

@end


@protocol SGFFCodecProcessingDelegate <NSObject>

- (id <SGFFFrame>)codec:(id <SGFFCodec>)codec processingFrame:(id <SGFFFrame>)frame;
- (id <SGFFOutputRender>)codec:(id <SGFFCodec>)codec processingOutputRender:(id <SGFFFrame>)frame;

@end


#endif /* SGFFCodec_h */
