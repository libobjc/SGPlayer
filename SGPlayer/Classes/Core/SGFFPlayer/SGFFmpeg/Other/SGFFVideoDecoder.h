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

@end

@interface SGFFVideoDecoder : NSObject

+ (instancetype)decoderWithCodecContext:(AVCodecContext *)codec_context
                               timebase:(NSTimeInterval)timebase
                                    fps:(NSTimeInterval)fps
                      codecContextAsync:(BOOL)codecContextAsync
                     videoToolBoxEnable:(BOOL)videoToolBoxEnable
                             rotateType:(SGFFVideoFrameRotateType)rotateType
                               delegate:(id <SGFFVideoDecoderDlegate>)delegate;

@property (nonatomic, weak) id <SGFFVideoDecoderDlegate> delegate;
@property (nonatomic, strong, readonly) NSError * error;

@property (nonatomic, assign, readonly) NSTimeInterval timebase;
@property (nonatomic, assign, readonly) NSTimeInterval fps;

@property (nonatomic, assign, readonly) SGFFVideoFrameRotateType rotateType;

@property (nonatomic, assign, readonly) BOOL videoToolBoxEnable;
@property (nonatomic, assign, readonly) BOOL videoToolBoxDidOpen;
@property (nonatomic, assign) NSInteger videoToolBoxMaxDecodeFrameCount;     // default is 20.

@property (nonatomic, assign, readonly) BOOL codecContextAsync;
@property (nonatomic, assign) NSInteger codecContextMaxDecodeFrameCount;     // default is 3.

@property (nonatomic, assign, readonly) BOOL decodeSync;
@property (nonatomic, assign, readonly) BOOL decodeAsync;
@property (nonatomic, assign, readonly) BOOL decodeOnMainThread;

@property (nonatomic, assign, readonly) int size;
@property (nonatomic, assign, readonly) BOOL empty;
@property (nonatomic, assign, readonly) NSTimeInterval duration;

@property (nonatomic, assign) BOOL paused;
@property (nonatomic, assign) BOOL endOfFile;

- (SGFFVideoFrame *)getFrameAsync;
- (SGFFVideoFrame *)getFrameAsyncPosistion:(NSTimeInterval)position;
- (void)discardFrameBeforPosition:(NSTimeInterval)position;

- (void)putPacket:(AVPacket)packet;

- (void)flush;
- (void)destroy;

- (void)startDecodeThread;

@end
