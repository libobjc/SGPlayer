//
//  SGDisplayView.m
//  SGPlayer
//
//  Created by Single on 12/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGDisplayView.h"
#import "SGPlayerMacro.h"
#import "SGGLViewController.h"
#import "SGGLFrame.h"
#import "SGFingerRotation.h"

@interface SGDisplayView ()

@property (nonatomic, weak) SGPlayer * abstractPlayer;

@property (nonatomic, assign) BOOL avplayerLayerToken;
@property (nonatomic, strong) AVPlayerLayer * avplayerLayer;
@property (nonatomic, strong) SGGLViewController * glViewController;

@end

@implementation SGDisplayView

+ (instancetype)displayViewWithAbstractPlayer:(SGPlayer *)abstractPlayer
{
    return [[self alloc] initWithAbstractPlayer:abstractPlayer];
}

- (instancetype)initWithAbstractPlayer:(SGPlayer *)abstractPlayer
{
    if (self = [super initWithFrame:CGRectZero]) {
        self.abstractPlayer = abstractPlayer;
        self->_fingerRotation = [SGFingerRotation fingerRotation];
        SGPLFViewSetBackgroundColor(self, [SGPLFColor blackColor]);
        [self setupEventHandler];
    }
    return self;
}

- (void)playerOutputTypeEmpty
{
    self->_playerOutputType = SGDisplayPlayerOutputTypeEmpty;
}

- (void)playerOutputTypeFF
{
    self->_playerOutputType = SGDisplayPlayerOutputTypeFF;
}

- (void)playerOutputTypeAV
{
    self->_playerOutputType = SGDisplayPlayerOutputTypeAV;
}

- (void)rendererTypeEmpty
{
    if (self.rendererType != SGDisplayRendererTypeEmpty) {
        self->_rendererType = SGDisplayRendererTypeEmpty;
        [self reloadView];
    }
}

- (void)rendererTypeAVPlayerLayer
{
    if (self.rendererType != SGDisplayRendererTypeAVPlayerLayer) {
        self->_rendererType = SGDisplayRendererTypeAVPlayerLayer;
        [self reloadView];
    }
}

- (void)rendererTypeOpenGL
{
    if (self.rendererType != SGDisplayRendererTypeOpenGL) {
        self->_rendererType = SGDisplayRendererTypeOpenGL;
        [self reloadView];
    }
}

- (void)reloadView
{
    [self cleanView];
    switch (self.rendererType) {
        case SGDisplayRendererTypeEmpty:
            break;
        case SGDisplayRendererTypeAVPlayerLayer:
        {
            self.avplayerLayer = [AVPlayerLayer playerLayerWithPlayer:nil];
            [self reloadPlayerConfig];
            self.avplayerLayerToken = NO;
            [self.layer insertSublayer:self.avplayerLayer atIndex:0];
            [self reloadGravityMode];
        }
            break;
        case SGDisplayRendererTypeOpenGL:
        {
            self.glViewController = [SGGLViewController viewControllerWithDisplayView:self];
            dispatch_async(dispatch_get_main_queue(), ^{
                SGPLFGLView * glView = SGPLFGLViewControllerGetGLView(self.glViewController);
                SGPLFViewInsertSubview(self, glView, 0);
            });
        }
            break;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateDisplayViewLayout:self.bounds];
    });
}

- (void)reloadGravityMode
{
    if (self.avplayerLayer) {
        switch (self.abstractPlayer.viewGravityMode) {
            case SGGravityModeResize:
                self.avplayerLayer.videoGravity = AVLayerVideoGravityResize;
                break;
            case SGGravityModeResizeAspect:
                self.avplayerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
                break;
            case SGGravityModeResizeAspectFill:
                self.avplayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                break;
        }
    }
}

- (void)reloadPlayerConfig
{
    if (self.avplayerLayer && self.playerOutputType == SGDisplayPlayerOutputTypeAV) {
#if SGPLATFORM_TARGET_OS_MAC
        self.avplayerLayer.player = [self.playerOutputAV playerOutputGetAVPlayer];
#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV
        if ([self.playerOutputAV playerOutputGetAVPlayer] && [UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
            self.avplayerLayer.player = [self.playerOutputAV playerOutputGetAVPlayer];
        } else {
            self.avplayerLayer.player = nil;
        }
#endif
    }
}

- (void)reloadVideoFrameForGLFrame:(SGGLFrame *)glFrame
{
    switch (self.playerOutputType) {
        case SGDisplayPlayerOutputTypeEmpty:
            break;
        case SGDisplayPlayerOutputTypeAV:
        {
            CVPixelBufferRef pixelBuffer = [self.playerOutputAV playerOutputGetPixelBufferAtCurrentTime];
            if (pixelBuffer) {
                [glFrame updateWithCVPixelBuffer:pixelBuffer];
            }
        }
            break;
        case SGDisplayPlayerOutputTypeFF:
        {
#if SGPlayerBuildConfig_FFmpeg_Enable
            SGFFVideoFrame * videoFrame = [self.playerOutputFF playerOutputGetVideoFrameWithCurrentPostion:glFrame.currentPosition
                                                                                           currentDuration:glFrame.currentDuration];
            if (videoFrame) {
                [glFrame updateWithSGFFVideoFrame:videoFrame];
                glFrame.rotateType = videoFrame.rotateType;
            }
#endif
        }
            break;
    }
}

- (SGPLFImage *)snapshot
{
    switch (self.rendererType) {
        case SGDisplayRendererTypeEmpty:
            return nil;
        case SGDisplayRendererTypeAVPlayerLayer:
            return [self.playerOutputAV playerOutputGetSnapshotAtCurrentTime];
        case SGDisplayRendererTypeOpenGL:
            return [self.glViewController snapshot];
    }
}

- (void)cleanView
{
    if (self.avplayerLayer) {
        [self.avplayerLayer removeFromSuperlayer];
        self.avplayerLayer.player = nil;
        self.avplayerLayer = nil;
    }
    if (self.glViewController) {
        SGPLFGLView * glView = SGPLFGLViewControllerGetGLView(self.glViewController);
        [glView removeFromSuperview];
        self.glViewController = nil;
    }
    self.avplayerLayerToken = NO;
    [self.fingerRotation clean];
}

- (void)updateDisplayViewLayout:(CGRect)frame
{
    if (self.avplayerLayer) {
        self.avplayerLayer.frame = frame;
        if (self.abstractPlayer.viewAnimationHidden || !self.avplayerLayerToken) {
            [self.avplayerLayer removeAllAnimations];
            self.avplayerLayerToken = YES;
        }
    }
    if (self.glViewController) {
        [self.glViewController reloadViewport];
    }
}

#pragma mark - Event Handler

- (void)setupEventHandler
{
#if SGPLATFORM_TARGET_OS_MAC
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(macOS_updateFrameAction:) name:NSViewFrameDidChangeNotification object:self];
    
#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iOS_applicationDidEnterBackgroundAction:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iOS_applicationWillEnterForegroundAction:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    UITapGestureRecognizer * tapGestureRecigbuzer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(iOS_tapGestureRecigbuzerAction:)];
    [self addGestureRecognizer:tapGestureRecigbuzer];
    
#endif
}

#if SGPLATFORM_TARGET_OS_MAC

static BOOL mouse_dragged = NO;

- (void)mouseDragged:(NSEvent *)event
{
    mouse_dragged = YES;
    switch (self.rendererType) {
        case SGDisplayRendererTypeEmpty:
        case SGDisplayRendererTypeAVPlayerLayer:
            return;
        default:
        {
            float m = 0.005;
            if (self.bounds.size.width > 700) {
                m = 0.003;
            }
            float distanceX = event.deltaX;
            float distanceY = event.deltaY;
            distanceX *= m;
            distanceY *= m;
            self.fingerRotation.x += distanceY *  [SGFingerRotation degress] / 100;
            self.fingerRotation.y -= distanceX *  [SGFingerRotation degress] / 100;
        }
            break;
    }
}

- (void)mouseUp:(NSEvent *)event
{
    if (!mouse_dragged && self.abstractPlayer.viewTapAction) {
        self.abstractPlayer.viewTapAction(self.abstractPlayer, self.abstractPlayer.view);
    }
    mouse_dragged = NO;
}

- (void)mouseDown:(NSEvent *)event
{
    mouse_dragged = NO;
}

- (void)macOS_updateFrameAction:(NSNotification *)notification
{
    [self updateDisplayViewLayout:self.bounds];
}

#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV

- (void)iOS_applicationDidEnterBackgroundAction:(NSNotification *)notification
{
    if (_avplayerLayer) {
        _avplayerLayer.player = nil;
    }
}

- (void)iOS_applicationWillEnterForegroundAction:(NSNotification *)notification
{
    if (_avplayerLayer) {
        _avplayerLayer.player = [self.playerOutputAV playerOutputGetAVPlayer];
    }
}

- (void)iOS_tapGestureRecigbuzerAction:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (self.abstractPlayer.viewTapAction) {
        self.abstractPlayer.viewTapAction(self.abstractPlayer, self.abstractPlayer.view);
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.abstractPlayer.displayMode == SGDisplayModeBox) return;
    switch (self.rendererType) {
        case SGDisplayRendererTypeEmpty:
        case SGDisplayRendererTypeAVPlayerLayer:
            return;
        default:
        {
            UITouch * touch = [touches anyObject];
            float distanceX = [touch locationInView:touch.view].x - [touch previousLocationInView:touch.view].x;
            float distanceY = [touch locationInView:touch.view].y - [touch previousLocationInView:touch.view].y;
            distanceX *= 0.005;
            distanceY *= 0.005;
            self.fingerRotation.x += distanceY *  [SGFingerRotation degress] / 100;
            self.fingerRotation.y -= distanceX *  [SGFingerRotation degress] / 100;
        }
            break;
    }
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    [super layoutSublayersOfLayer:layer];
    [self updateDisplayViewLayout:layer.bounds];
}

#endif

-(void)dealloc
{
    [self cleanView];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SGPlayerLog(@"SGDisplayView release");
}

@end
