//
//  SGDisplayView.h
//  SGPlayer
//
//  Created by Single on 12/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "SGPlayerBuildConfig.h"
#import "SGPlayerImp.h"
#import "SGAVPlayer.h"
#import "SGFFPlayer.h"

@class SGFingerRotation;
@class SGGLFrame;

typedef NS_ENUM(NSUInteger, SGDisplayRendererType) {
    SGDisplayRendererTypeEmpty,
    SGDisplayRendererTypeAVPlayerLayer,
    SGDisplayRendererTypeOpenGL,
};

typedef NS_ENUM(NSUInteger, SGDisplayPlayerOutputType) {
    SGDisplayPlayerOutputTypeEmpty,
    SGDisplayPlayerOutputTypeFF,
    SGDisplayPlayerOutputTypeAV,
};

@interface SGDisplayView : SGPLFView


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

+ (instancetype)displayViewWithAbstractPlayer:(SGPlayer *)abstractPlayer;


@property (nonatomic, weak, readonly) SGPlayer * abstractPlayer;
@property (nonatomic, strong, readonly) SGFingerRotation * fingerRotation;


// player output type
@property (nonatomic, assign, readonly) SGDisplayPlayerOutputType playerOutputType;
@property (nonatomic, weak) id <SGAVPlayerOutput> playerOutputAV;
- (void)playerOutputTypeAV;
- (void)playerOutputTypeEmpty;

#if SGPlayerBuildConfig_FFmpeg_Enable
@property (nonatomic, weak) id <SGFFPlayerOutput> playerOutputFF;
- (void)playerOutputTypeFF;
#endif


// renderer type
@property (nonatomic, assign, readonly) SGDisplayRendererType rendererType;
- (void)rendererTypeEmpty;
- (void)rendererTypeAVPlayerLayer;
- (void)rendererTypeOpenGL;


// reload
- (void)reloadGravityMode;
- (void)reloadPlayerConfig;
- (void)reloadVideoFrameForGLFrame:(SGGLFrame *)glFrame;

- (SGPLFImage *)snapshot;

@end
