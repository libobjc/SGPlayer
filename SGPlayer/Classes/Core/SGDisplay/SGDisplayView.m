//
//  SGDisplayView.m
//  SGPlayer
//
//  Created by Single on 12/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGDisplayView.h"
#import "SGPlayerMacro.h"
#import "SGPlayerImp.h"
#import "SGAVPlayer.h"
#import "SGGLViewController.h"
#import "SGGLFrame.h"

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
        SGPLFViewSetBackgroundColor(self, [SGPLFColor blackColor]);
        [self setupEventHandler];
    }
    return self;
}

- (BOOL)videoOutputPaused
{
    if (self.glViewController) {
        return self.glViewController.isPaused;
    }
    return YES;
}

- (void)videoOutputUpdateMaxPreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond
{
    [self.glViewController setVideoDecoderMaxPreferredFramesPerSecond:preferredFramesPerSecond];
}

- (void)updateGLFrame:(SGGLFrame *)glFrame
{
    if (self.rendererType == SGDisplayRendererTypeAVPlayerPixelBufferVR) {
        CVPixelBufferRef pixelBuffer = [self.sgavplayer pixelBufferAtCurrentTime];
        if (pixelBuffer) {
            [glFrame updateWithCVPixelBuffer:pixelBuffer];
        }
    } else {
        SGFFVideoFrame * videoFrame = [self.sgffdecoder fetchVideoFrameWithCurrentPostion:glFrame.currentPosition currentDuration:glFrame.currentDuration];
        if (videoFrame) {
            [glFrame updateWithSGFFVideoFrame:videoFrame];
        }
    }
}

- (void)setRendererType:(SGDisplayRendererType)rendererType
{
    if (_rendererType != rendererType) {
        _rendererType = rendererType;
        [self reloadView];
    }
}

- (void)reloadView
{
    [self cleanViewIgnore];
    switch (self.rendererType) {
        case SGDisplayRendererTypeEmpty:
            break;
        case SGDisplayRendererTypeAVPlayerLayer:
            if (!self.avplayerLayer) {
                self.avplayerLayer = [AVPlayerLayer playerLayerWithPlayer:nil];
                [self reloadSGAVPlayer];
                self.avplayerLayerToken = NO;
                [self.layer insertSublayer:self.avplayerLayer atIndex:0];
                [self reloadGravityMode];
            }
            break;
        case SGDisplayRendererTypeAVPlayerPixelBufferVR:
        case SGDisplayRendererTypeFFmpegPexelBuffer:
        case SGDisplayRendererTypeFFmpegPexelBufferVR:
            if (!self.glViewController) {
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

- (void)reloadSGAVPlayer
{
#if SGPLATFORM_TARGET_OS_MAC
    self.avplayerLayer.player = self.sgavplayer.avPlayer;
#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    if (self.sgavplayer.avPlayer && [UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
        self.avplayerLayer.player = self.sgavplayer.avPlayer;
    } else {
        self.avplayerLayer.player = nil;
    }
#endif
}

- (void)cleanView
{
    [self cleanViewCleanAVPlayerLayer:YES cleanGLViewController:YES];
}

- (void)cleanViewIgnore
{
    switch (self.rendererType) {
        case SGDisplayRendererTypeEmpty:
            [self cleanView];
            break;
        case SGDisplayRendererTypeAVPlayerLayer:
            [self cleanViewCleanAVPlayerLayer:NO cleanGLViewController:YES];
            break;
        case SGDisplayRendererTypeAVPlayerPixelBufferVR:
        case SGDisplayRendererTypeFFmpegPexelBuffer:
        case SGDisplayRendererTypeFFmpegPexelBufferVR:
            [self cleanViewCleanAVPlayerLayer:YES cleanGLViewController:NO];
            break;
    }
}

- (void)cleanViewCleanAVPlayerLayer:(BOOL)cleanAVPlayerLayer cleanGLViewController:(BOOL)cleanGLViewController
{
    [self cleanEmptyBuffer];
    if (cleanAVPlayerLayer && self.avplayerLayer) {
        [self.avplayerLayer removeFromSuperlayer];
        self.avplayerLayer = nil;
    }
    if (cleanGLViewController && self.glViewController) {
        SGPLFGLView * glView = SGPLFGLViewControllerGetGLView(self.glViewController);
        [glView removeFromSuperview];
        self.glViewController = nil;
    }
    self.avplayerLayerToken = NO;
}

- (void)cleanEmptyBuffer
{
    [self.fingerRotation clean];
    if (self.glViewController) {
        [self.glViewController flushClearColor];
    }
}

- (SGFingerRotation *)fingerRotation
{
    if (!_fingerRotation) {
        _fingerRotation = [SGFingerRotation fingerRotation];
    }
    return _fingerRotation;
}

- (SGPLFImage *)snapshot
{
    switch (self.rendererType) {
        case SGDisplayRendererTypeEmpty:
            return nil;
        case SGDisplayRendererTypeAVPlayerLayer:
            return self.sgavplayer.snapshotAtCurrentTime;
        case SGDisplayRendererTypeAVPlayerPixelBufferVR:
        case SGDisplayRendererTypeFFmpegPexelBuffer:
        case SGDisplayRendererTypeFFmpegPexelBufferVR:
            return [self.glViewController snapshot];
    }
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
        _avplayerLayer.player = self.sgavplayer.avPlayer;
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
