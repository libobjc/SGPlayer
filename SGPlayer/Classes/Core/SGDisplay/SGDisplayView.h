//
//  SGDisplayView.h
//  SGPlayer
//
//  Created by Single on 12/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "SGPlayerImp.h"
#import "SGFFDecoder.h"
#import "SGFingerRotation.h"

@class SGAVPlayer;
@class SGDisplayView;
@class SGGLFrame;

typedef NS_ENUM(NSUInteger, SGDisplayRendererType) {
    SGDisplayRendererTypeEmpty,
    SGDisplayRendererTypeAVPlayerLayer,
    SGDisplayRendererTypeAVPlayerPixelBufferVR,
    SGDisplayRendererTypeFFmpegPexelBuffer,
    SGDisplayRendererTypeFFmpegPexelBufferVR,
};

@interface SGDisplayView : SGPLFView <SGFFDecoderVideoOutputConfig>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

+ (instancetype)displayViewWithAbstractPlayer:(SGPlayer *)abstractPlayer;

@property (nonatomic, weak, readonly) SGPlayer * abstractPlayer;

@property (nonatomic, weak) SGFFDecoder * sgffdecoder;
@property (nonatomic, weak) SGAVPlayer * sgavplayer;
- (void)reloadSGAVPlayer;

@property (nonatomic, assign) NSInteger preferredFramesPerSecond;
@property (nonatomic, assign) SGDisplayRendererType rendererType;
@property (nonatomic, strong) SGFingerRotation * fingerRotation;

- (void)reloadGravityMode;
- (void)cleanEmptyBuffer;
- (void)resetRendererType;

- (SGPLFImage *)snapshot;


- (void)updateGLFrame:(SGGLFrame *)glFrame;

@end
