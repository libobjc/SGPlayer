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


@protocol SGFFCodec <NSObject>

+ (SGFFCodecType)type;

@property (nonatomic, weak) id <SGFFCodecProcessingDelegate> processingDelegate;
@property (nonatomic, assign) AVRational timebase;

- (long long)duration;
- (long long)packetDuration;
- (long long)frameDuration;
- (long long)size;
- (long long)packetSize;
- (long long)frameSize;

- (void)open;
- (void)close;
- (void)putPacket:(AVPacket)packet;

@end


@protocol SGFFCodecProcessingDelegate <NSObject>

- (id <SGFFFrame>)codec:(id <SGFFCodec>)codec processingDecodedFrame:(AVFrame *)decodedFrame;

@end


#endif /* SGFFCodec_h */
