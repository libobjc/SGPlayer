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
#import "SGFFOutputRender.h"
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

- (AVRational)timebase;
- (long long)duration;
- (long long)size;

- (BOOL)open;
- (void)close;
- (void)putPacket:(AVPacket)packet;
- (id <SGFFOutputRender>)getOutputRender;

@end


@protocol SGFFCodecProcessingDelegate <NSObject>

- (id <SGFFFrame>)codec:(id <SGFFCodec>)codec processingFrame:(id <SGFFFrame>)frame;
- (id <SGFFOutputRender>)codec:(id <SGFFCodec>)codec processingOutputRender:(id <SGFFFrame>)frame;

@end


#endif /* SGFFCodec_h */
