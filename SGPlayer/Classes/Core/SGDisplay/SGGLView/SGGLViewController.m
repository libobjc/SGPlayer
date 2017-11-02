//
//  SGGLViewController.m
//  SGPlayer
//
//  Created by Single on 2017/3/27.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGGLViewController.h"
#import "SGPlayerMacro.h"
#import "SGGLFrame.h"
#import "SGGLProgramNV12.h"
#import "SGGLProgramYUV420.h"
#import "SGGLTextureNV12.h"
#import "SGGLTextureYUV420.h"
#import "SGGLNormalModel.h"
#import "SGGLVRModel.h"
#import "SGMatrix.h"
#import "SGDistortionRenderer.h"
#import "SGPlayerBuildConfig.h"

@interface SGGLViewController ()

@property (nonatomic, strong) SGGLFrame * currentFrame;

@property (nonatomic, strong) SGGLTextureNV12 * textureNV12;
@property (nonatomic, strong) SGGLTextureYUV420 * textureYUV420;

@property (nonatomic, strong) SGGLProgramNV12 * programNV12;
@property (nonatomic, strong) SGGLProgramYUV420 * programYUV420;

@property (nonatomic, strong) SGGLNormalModel * normalModel;
@property (nonatomic, strong) SGGLVRModel * vrModel;

@property (nonatomic, strong) SGMatrix * vrMatrix;

@property (nonatomic, strong) NSLock * openGLLock;
@property (nonatomic, assign) BOOL clearToken;
@property (nonatomic, assign) BOOL drawToekn;
@property (nonatomic, assign) CGFloat aspect;
@property (nonatomic, assign) CGRect viewport;

#if SGPLATFORM_TARGET_OS_IPHONE
@property (nonatomic, strong) SGDistortionRenderer * distorionRenderer;
#endif

@end

@implementation SGGLViewController

+ (instancetype)viewControllerWithDisplayView:(SGDisplayView *)displayView
{
    return [[self alloc] initWithDisplayView:displayView];
}

- (instancetype)initWithDisplayView:(SGDisplayView *)displayView
{
    if (self = [super init]) {
        self->_displayView = displayView;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupOpenGL];
}

#if SGPLATFORM_TARGET_OS_IPHONE
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGFloat scale = SGPLFScreenGetScale();
    SGPLFGLView * glView = SGPLFGLViewControllerGetGLView(self);
    self.distorionRenderer.viewportSize = CGSizeMake(CGRectGetWidth(glView.bounds) * scale, CGRectGetHeight(glView.bounds) * scale);
}
#endif

- (void)setupOpenGL
{
    self.openGLLock = [[NSLock alloc] init];
    SGPLFGLView * glView = SGPLFGLViewControllerGetGLView(self);
    SGPLFViewSetBackgroundColor(glView, [SGPLFColor blackColor]);
    
    SGPLFGLContext * context = SGPLFGLContextAllocInit();
    SGPLFGLViewSetContext(glView, context);
    SGPLGLContextSetCurrentContext(context);
    
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    glView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    glView.contentScaleFactor = [UIScreen mainScreen].scale;
    self.pauseOnWillResignActive = NO;
    self.resumeOnDidBecomeActive = YES;
#endif
#if SGPLATFORM_TARGET_OS_IPHONE
    self.distorionRenderer = [SGDistortionRenderer distortionRenderer];
#endif
    
    self.textureNV12 = [[SGGLTextureNV12 alloc] initWithContext:context];
    self.textureYUV420 = [[SGGLTextureYUV420 alloc] init];
    
    self.programNV12 = [SGGLProgramNV12 program];
    self.programYUV420 = [SGGLProgramYUV420 program];
    
    self.normalModel = [SGGLNormalModel model];
    self.vrModel = [SGGLVRModel model];
    
    self.vrMatrix = [[SGMatrix alloc] init];
    self.currentFrame = [SGGLFrame frame];
    self.aspect = 16.0 / 9.0;
    
    SGVideoType videoType = self.displayView.abstractPlayer.videoType;
    switch (videoType) {
        case SGVideoTypeNormal:
            self.preferredFramesPerSecond = 35;
            break;
        case SGVideoTypeVR:
            self.preferredFramesPerSecond = 60;
            break;
    }
}

- (void)flushClearColor
{
    NSLog(@"flush .....");
    [self.openGLLock lock];
    self.clearToken = YES;
    self.drawToekn = NO;
    [self.currentFrame flush];
    [self.textureNV12 flush];
    [self.textureYUV420 flush];
    [self.openGLLock unlock];
}

- (void)glkView:(SGPLFGLView *)view drawInRect:(CGRect)rect
{
    [self.openGLLock lock];
    SGPLFGLViewPrepareOpenGL(view);
    
    if (self.clearToken) {
        glClearColor(0, 0, 0, 1);
        glClear(GL_COLOR_BUFFER_BIT);
        self.clearToken = NO;
        SGPLFGLViewFlushBuffer(view);
    } else if ([self needDrawOpenGL]) {
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
            [self.openGLLock unlock];
            return;
        }
#endif
        SGPLFGLView * glView = SGPLFGLViewControllerGetGLView(self);
        self.viewport = glView.bounds;
        [self drawOpenGL];
        [self.currentFrame didDraw];
        self.drawToekn = YES;
        SGPLFGLViewFlushBuffer(view);
    }
    [self.openGLLock unlock];
}

- (SGGLProgram *)chooseProgram
{
    switch (self.currentFrame.type) {
        case SGGLFrameTypeNV12:
            return self.programNV12;
        case SGGLFrameTypeYUV420:
            return self.programYUV420;
    }
}

- (SGGLTexture *)chooseTexture
{
    switch (self.currentFrame.type) {
        case SGGLFrameTypeNV12:
            return self.textureNV12;
        case SGGLFrameTypeYUV420:
            return self.textureYUV420;
    }
}

- (SGGLModelTextureRotateType)chooseModelTextureRotateType
{
#if SGPlayerBuildConfig_FFmpeg_Enable
    switch (self.currentFrame.rotateType) {
        case SGFFVideoFrameRotateType0:
            return SGGLModelTextureRotateType0;
        case SGFFVideoFrameRotateType90:
            return SGGLModelTextureRotateType90;
        case SGFFVideoFrameRotateType180:
            return SGGLModelTextureRotateType180;
        case SGFFVideoFrameRotateType270:
            return SGGLModelTextureRotateType270;
    }
#endif
    return SGGLModelTextureRotateType0;
}

- (BOOL)needDrawOpenGL
{
    [self.displayView reloadVideoFrameForGLFrame:self.currentFrame];
    if (!self.currentFrame.hasData) {
        return NO;
    }
    if (self.displayView.abstractPlayer.videoType != SGVideoTypeVR && !self.currentFrame.hasUpate && self.drawToekn) {
        return NO;
    }
    
    SGGLTexture * texture = [self chooseTexture];
    CGFloat aspect = 16.0 / 9.0;
    if (![texture updateTextureWithGLFrame:self.currentFrame aspect:&aspect]) {
        return NO;
    }
    
    if (self.displayView.abstractPlayer.videoType == SGVideoTypeVR) {
        self.aspect = 16.0 / 9.0;
    } else {
        self.aspect = aspect;
    }
    if (self.currentFrame.hasUpdateRotateType) {
        [self reloadViewport];
    }
    return YES;
}

- (void)drawOpenGL
{
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    SGVideoType videoType = self.displayView.abstractPlayer.videoType;
    SGDisplayMode displayMode = self.displayView.abstractPlayer.displayMode;
    
#if SGPLATFORM_TARGET_OS_IPHONE
    if (videoType == SGVideoTypeVR && displayMode == SGDisplayModeBox) {
        [self.distorionRenderer beforDrawFrame];
    }
#endif
    
    SGGLProgram * program = [self chooseProgram];
    [program use];
    [program bindVariable];
    
    CGFloat scale = SGPLFScreenGetScale();
    CGRect rect = CGRectMake(0, 0, self.viewport.size.width * scale, self.viewport.size.height * scale);
    switch (videoType) {
        case SGVideoTypeNormal:
        {
            [self.normalModel bindPositionLocation:program.position_location textureCoordLocation:program.texture_coord_location textureRotateType:[self chooseModelTextureRotateType]];
            glViewport(rect.origin.x, rect.origin.y, CGRectGetWidth(rect), CGRectGetHeight(rect));
            [program updateMatrix:GLKMatrix4Identity];
            glDrawElements(GL_TRIANGLES, self.normalModel.index_count, GL_UNSIGNED_SHORT, 0);
        }
            break;
        case SGVideoTypeVR:
        {
            [self.vrModel bindPositionLocation:program.position_location textureCoordLocation:program.texture_coord_location];
            switch (displayMode) {
                case SGDisplayModeNormal:
                {
                    GLKMatrix4 matrix;
                    BOOL success = [self.vrMatrix singleMatrixWithSize:rect.size matrix:&matrix fingerRotation:self.displayView.fingerRotation];
                    if (success) {
                        glViewport(rect.origin.x, rect.origin.y, CGRectGetWidth(rect), CGRectGetHeight(rect));
                        [program updateMatrix:matrix];
                        glDrawElements(GL_TRIANGLES, self.vrModel.index_count, GL_UNSIGNED_SHORT, 0);
                    }
                }
                    break;
                case SGDisplayModeBox:
                {
                    GLKMatrix4 leftMatrix;
                    GLKMatrix4 rightMatrix;
                    BOOL success = [self.vrMatrix doubleMatrixWithSize:rect.size leftMatrix:&leftMatrix rightMatrix:&rightMatrix];
                    if (success) {
                        glViewport(rect.origin.x, rect.origin.y, CGRectGetWidth(rect)/2, CGRectGetHeight(rect));
                        [program updateMatrix:leftMatrix];
                        glDrawElements(GL_TRIANGLES, self.vrModel.index_count, GL_UNSIGNED_SHORT, 0);
                        
                        glViewport(CGRectGetWidth(rect)/2 + rect.origin.x, rect.origin.y, CGRectGetWidth(rect)/2, CGRectGetHeight(rect));
                        [program updateMatrix:rightMatrix];
                        glDrawElements(GL_TRIANGLES, self.vrModel.index_count, GL_UNSIGNED_SHORT, 0);
                    }
                }
                    break;
            }
        }
            break;
    }
    
#if SGPLATFORM_TARGET_OS_IPHONE
    if (videoType == SGVideoTypeVR && displayMode == SGDisplayModeBox) {
        SGPLFGLView * glView = SGPLFGLViewControllerGetGLView(self);
        SGPLFGLViewBindFrameBuffer(glView);
        [self.distorionRenderer afterDrawFrame];
    }
#endif
}

- (void)reloadViewport
{
    SGPLFGLView * glView = SGPLFGLViewControllerGetGLView(self);
    CGRect superviewFrame = glView.superview.bounds;
    CGFloat superviewAspect = superviewFrame.size.width / superviewFrame.size.height;
    
    if (self.aspect <= 0) {
        glView.frame = superviewFrame;
        return;
    }
    
    CGFloat resultAspect = self.aspect;
#if SGPlayerBuildConfig_FFmpeg_Enable
    switch (self.currentFrame.rotateType) {
        case SGFFVideoFrameRotateType90:
        case SGFFVideoFrameRotateType270:
            resultAspect = 1 / self.aspect;
            break;
        case SGFFVideoFrameRotateType0:
        case SGFFVideoFrameRotateType180:
            break;
    }
#endif
    
    SGGravityMode gravityMode = self.displayView.abstractPlayer.viewGravityMode;
    switch (gravityMode) {
        case SGGravityModeResize:
            glView.frame = superviewFrame;
            break;
        case SGGravityModeResizeAspect:
            if (superviewAspect < resultAspect) {
                CGFloat height = superviewFrame.size.width / resultAspect;
                glView.frame = CGRectMake(0, (superviewFrame.size.height - height) / 2, superviewFrame.size.width, height);
            } else if (superviewAspect > resultAspect) {
                CGFloat width = superviewFrame.size.height * resultAspect;
                glView.frame = CGRectMake((superviewFrame.size.width - width) / 2, 0, width, superviewFrame.size.height);
            } else {
                glView.frame = superviewFrame;
            }
            break;
        case SGGravityModeResizeAspectFill:
            if (superviewAspect < resultAspect) {
                CGFloat width = superviewFrame.size.height * resultAspect;
                glView.frame = CGRectMake(-(width - superviewFrame.size.width) / 2, 0, width, superviewFrame.size.height);
            } else if (superviewAspect > resultAspect) {
                CGFloat height = superviewFrame.size.width / resultAspect;
                glView.frame = CGRectMake(0, -(height - superviewFrame.size.height) / 2, superviewFrame.size.width, height);
            } else {
                glView.frame = superviewFrame;
            }
            break;
        default:
            glView.frame = superviewFrame;
            break;
    }
    self.drawToekn = NO;
    [self.currentFrame didUpdateRotateType];
}

- (void)setAspect:(CGFloat)aspect
{
    if (_aspect != aspect) {
        _aspect = aspect;
        [self reloadViewport];
    }
}

- (SGPLFImage *)snapshot
{
    if (self.displayView.abstractPlayer.videoType == SGVideoTypeVR) {
        SGPLFGLView * glView = SGPLFGLViewControllerGetGLView(self);
        return SGPLFGLViewGetCurrentSnapshot(glView);
    } else {
        SGPLFImage * image = [self.currentFrame imageFromVideoFrame];
        if (image) {
            return image;
        }
    }
    SGPLFGLView * glView = SGPLFGLViewControllerGetGLView(self);
    return SGPLFGLViewGetCurrentSnapshot(glView);
}

- (void)dealloc
{
    SGPLGLContextSetCurrentContext(nil);
    SGPlayerLog(@"%@ release", self.class);
}

@end
