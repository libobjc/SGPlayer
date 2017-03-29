//
//  SGFFVideoDecoder.h
//  SGPlayer
//
//  Created by Single on 2017/2/17.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFVideoFrame.h"
#import "avformat.h"

@class SGFFVideoDecoder;

@protocol SGFFVideoDecoderDlegate <NSObject>

- (void)videoDecoder:(SGFFVideoDecoder *)videoDecoder didError:(NSError *)error;
- (void)videoDecoder:(SGFFVideoDecoder *)videoDecoder didChangePreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond;
- (void)videoDecoderNeedUpdateBufferedDuration:(SGFFVideoDecoder *)videoDecoder;
- (void)videoDecoderNeedCheckBufferingStatus:(SGFFVideoDecoder *)videoDecoder;

@end

@interface SGFFVideoDecoder : NSObject

+ (instancetype)decoderWithCodecContext:(AVCodecContext *)codec_context
                               timebase:(NSTimeInterval)timebase
                                    fps:(NSTimeInterval)fps
                               delegate:(id <SGFFVideoDecoderDlegate>)delegate;

@property (nonatomic, weak) id <SGFFVideoDecoderDlegate> delegate;

@property (nonatomic, assign) BOOL videoToolBoxEnable;      // default is YES;
@property (nonatomic, assign) NSTimeInterval maxDecodeDuration;     // default is 2s;

@property (nonatomic, assign) NSTimeInterval timebase;
@property (nonatomic, assign) NSTimeInterval fps;

@property (nonatomic, strong, readonly) NSError * error;
@property (nonatomic, assign, readonly) BOOL decoding;

@property (nonatomic, assign) BOOL paused;
@property (nonatomic, assign) BOOL endOfFile;

- (int)packetSize;

- (BOOL)empty;
- (BOOL)packetEmpty;
- (BOOL)frameEmpty;

- (NSTimeInterval)duration;
- (NSTimeInterval)packetDuration;
- (NSTimeInterval)frameDuration;

- (SGFFVideoFrame *)getFrameSync;
- (SGFFVideoFrame *)getFrameAsync;
- (SGFFVideoFrame *)getFrameAsyncPosistion:(NSTimeInterval)position;
- (NSTimeInterval)getFirstFramePositionAsync;
- (void)discardFrameBeforPosition:(NSTimeInterval)position;

- (void)putPacket:(AVPacket)packet;

- (void)flush;
- (void)destroy;

- (void)decodeFrameThread;

@end
