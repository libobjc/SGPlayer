//
//  SGFFAudioDecoder.h
//  SGPlayer
//
//  Created by Single on 2017/2/17.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFAudioFrame.h"
#import "avformat.h"

@class SGFFAudioDecoder;

@protocol SGFFAudioDecoderDelegate <NSObject>

- (void)audioDecoder:(SGFFAudioDecoder *)audioDecoder samplingRate:(Float64 *)samplingRate;
- (void)audioDecoder:(SGFFAudioDecoder *)audioDecoder channelCount:(UInt32 *)channelCount;

@end

@interface SGFFAudioDecoder : NSObject

+ (instancetype)decoderWithCodecContext:(AVCodecContext *)codec_context timebase:(NSTimeInterval)timebase delegate:(id <SGFFAudioDecoderDelegate>)delegate;

@property (nonatomic, weak) id <SGFFAudioDecoderDelegate> delegate;

- (int)size;
- (BOOL)empty;
- (NSTimeInterval)duration;

- (SGFFAudioFrame *)getFrameSync;
- (int)putPacket:(AVPacket)packet;

- (void)flush;
- (void)destroy;

@end
