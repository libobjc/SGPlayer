//
//  SGGLView.m
//  SGPlayer
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGGLView.h"
#import "SGPlayerMacro.h"
#import "SGPlayerImp.h"
#import "SGGLNormalModel.h"
#import "SGGLVRModel.h"
#import "SGMatrix.h"
#import "SGDistortionRenderer.h"

@interface SGGLView () <SGPLFGLViewDelegate>

@property (nonatomic, assign) BOOL setupToken;
@property (nonatomic, weak) SGDisplayView * displayView;

@property (nonatomic, strong) SGGLNormalModel * normalModel;
@property (nonatomic, strong) SGGLVRModel * vrModel;
@property (nonatomic, strong) SGMatrix * matrix;

@property (nonatomic, assign) BOOL clearToken;
@property (nonatomic, assign) CGFloat aspect;
@property (nonatomic, assign) CGRect viewport;

#if SGPLATFORM_TARGET_OS_IPHONE
@property (nonatomic, strong) SGDistortionRenderer * distorionRenderer;
#endif

@end

@implementation SGGLView

+ (instancetype)viewWithDisplayView:(SGDisplayView *)displayView
{
    return [[self alloc] initWithDisplayView:displayView];
}

- (instancetype)initWithDisplayView:(SGDisplayView *)displayView
{
    if (self = [super initWithFrame:CGRectZero]) {
        self.displayView = displayView;
        self.aspect = 16.0 / 9.0;
    }
    return self;
}

#if SGPLATFORM_TARGET_OS_MAC

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    [self trySetupAndResize];
}

#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self trySetupAndResize];
}

#endif

- (void)trySetupAndResize
{
    if (!self.setupToken) {
        [self setup];
        self.setupToken = YES;
    }
#if SGPLATFORM_TARGET_OS_IPHONE
    self.distorionRenderer.viewportSize = [self pixelSize];
#endif
}

- (CGSize)pixelSize
{
    CGFloat scale = SGPLFScreenGetScale();
    CGSize size = CGSizeMake(CGRectGetWidth(self.bounds) * scale, CGRectGetHeight(self.bounds) * scale);
    return size;
}

#pragma mark - setup

- (void)setup
{
    SGPLFViewSetBackgroundColor(self, [SGPLFColor blackColor]);
    [self setupGLKView];
    [self setupProgram];
    [self setupModel];
    [self setupSubClass];
}

- (void)setupGLKView
{
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    self.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    self.contentScaleFactor = [UIScreen mainScreen].scale;
#endif
    SGPLFGLViewSetDrawDelegate(self, self);
    SGPLFGLContext * context = SGPLFGLContextAllocInit();
    SGPLFGLViewSetContext(self, context);
    SGPLGLContextSetCurrentContext(context);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
}

- (void)setupModel
{
    self.normalModel = [SGGLNormalModel model];
    self.vrModel = [SGGLVRModel model];
}

- (void)displayAsyncOnMainThread
{
    if ([NSThread isMainThread]) {
        [self displayIfApplicationActive];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self displayIfApplicationActive];
        });
    }
}

- (void)displayIfApplicationActive
{
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) return;
#endif
    if (!self.displayView.abstractPlayer.contentURL) return;
    [self displayAndClear:NO];
}

- (void)displayAndClear:(BOOL)clear
{
    self.clearToken = clear;
    SGPLFGLViewDisplay(self);
}

- (void)glkView:(SGPLFGLView *)view drawInRect:(CGRect)rect
{
    if (self.clearToken) {
        glClearColor(0, 0, 0, 1);
        glClear(GL_COLOR_BUFFER_BIT);
    } else {
        self.viewport = self.bounds;
        [self drawOpenGL];
    }
}

- (void)cleanEmptyBuffer
{
    [self cleanTexture];
    
    if ([NSThread isMainThread]) {
        [self displayAndClear:YES];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self displayAndClear:YES];
        });
    }
}

- (SGPLFImage *)customSnapshot
{
    if (self.displayView.abstractPlayer.videoType == SGVideoTypeVR) {
        return SGPLFGLViewGetCurrentSnapshot(self);
    }
    return [self imageFromPixelBuffer];
}

- (void)reloadViewport
{
    CGRect superviewFrame = self.superview.bounds;
    CGFloat superviewAspect = superviewFrame.size.width / superviewFrame.size.height;
    
    if (self.aspect <= 0) {
        self.frame = superviewFrame;
        return;
    }
    
    SGGravityMode gravityMode = self.displayView.abstractPlayer.viewGravityMode;
    switch (gravityMode) {
        case SGGravityModeResize:
            self.frame = superviewFrame;
            break;
        case SGGravityModeResizeAspect:
            if (superviewAspect < self.aspect) {
                CGFloat height = superviewFrame.size.width / self.aspect;
                self.frame = CGRectMake(0, (superviewFrame.size.height - height) / 2, superviewFrame.size.width, height);
            } else if (superviewAspect > self.aspect) {
                CGFloat width = superviewFrame.size.height * self.aspect;
                self.frame = CGRectMake((superviewFrame.size.width - width) / 2, 0, width, superviewFrame.size.height);
            } else {
                self.frame = superviewFrame;
            }
            break;
        case SGGravityModeResizeAspectFill:
            if (superviewAspect < self.aspect) {
                CGFloat width = superviewFrame.size.height * self.aspect;
                self.frame = CGRectMake(-(width - superviewFrame.size.width) / 2, 0, width, superviewFrame.size.height);
            } else if (superviewAspect > self.aspect) {
                CGFloat height = superviewFrame.size.width / self.aspect;
                self.frame = CGRectMake(0, -(height - superviewFrame.size.height) / 2, superviewFrame.size.width, height);
            } else {
                self.frame = superviewFrame;
            }
            break;
        default:
            self.frame = superviewFrame;
            break;
    }
}

- (void)setAspect:(CGFloat)aspect
{
    if (_aspect != aspect) {
        _aspect = aspect;
        [self reloadViewport];
    }
}

- (void)setFrame:(CGRect)frame
{
    if (!CGRectEqualToRect(self.frame, frame)) {
        [super setFrame:frame];
    }
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

    CGFloat aspect;
    BOOL success = [self updateTextureAspect:&aspect];
    if (!success) return;
    
    [self.program use];
    [self.program bindVariable];
    
    // update frame
    if (videoType == SGVideoTypeVR) {
        self.aspect = 16.0 / 9.0;
    } else {
        self.aspect = aspect;
    }
    
    CGFloat scale = SGPLFScreenGetScale();
    CGRect rect = CGRectMake(0, 0, self.viewport.size.width * scale, self.viewport.size.height * scale);
    switch (videoType) {
        case SGVideoTypeNormal:
        {
            [self.normalModel bindPositionLocation:self.program.position_location textureCoordLocation:self.program.texture_coord_location];
            glViewport(rect.origin.x, rect.origin.y, CGRectGetWidth(rect), CGRectGetHeight(rect));
            [self.program updateMatrix:GLKMatrix4Identity];
            glDrawElements(GL_TRIANGLES, self.normalModel.index_count, GL_UNSIGNED_SHORT, 0);
        }
            break;
        case SGVideoTypeVR:
        {
            [self.vrModel bindPositionLocation:self.program.position_location textureCoordLocation:self.program.texture_coord_location];
            switch (displayMode) {
                case SGDisplayModeNormal:
                {
                    GLKMatrix4 matrix;
                    BOOL success = [self.matrix singleMatrixWithSize:rect.size matrix:&matrix fingerRotation:self.displayView.fingerRotation];
                    if (success) {
                        glViewport(rect.origin.x, rect.origin.y, CGRectGetWidth(rect), CGRectGetHeight(rect));
                        [self.program updateMatrix:matrix];
                        glDrawElements(GL_TRIANGLES, self.vrModel.index_count, GL_UNSIGNED_SHORT, 0);
                    }
                }
                    break;
                case SGDisplayModeBox:
                {
                    GLKMatrix4 leftMatrix;
                    GLKMatrix4 rightMatrix;
                    BOOL success = [self.matrix doubleMatrixWithSize:rect.size leftMatrix:&leftMatrix rightMatrix:&rightMatrix];
                    if (success) {
                        glViewport(rect.origin.x, rect.origin.y, CGRectGetWidth(rect)/2, CGRectGetHeight(rect));
                        [self.program updateMatrix:leftMatrix];
                        glDrawElements(GL_TRIANGLES, self.vrModel.index_count, GL_UNSIGNED_SHORT, 0);
                        
                        glViewport(CGRectGetWidth(rect)/2 + rect.origin.x, rect.origin.y, CGRectGetWidth(rect)/2, CGRectGetHeight(rect));
                        [self.program updateMatrix:rightMatrix];
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
        SGPLFGLViewBindFrameBuffer(self);
        [self.distorionRenderer afterDrawFrame];
    }
#endif
}

- (SGMatrix *)matrix
{
    if (!_matrix) {
        _matrix = [[SGMatrix alloc] init];
    }
    return _matrix;
}

#if SGPLATFORM_TARGET_OS_IPHONE
- (SGDistortionRenderer *)distorionRenderer
{
    if (!_distorionRenderer) {
        _distorionRenderer = [SGDistortionRenderer distortionRenderer];
    }
    return _distorionRenderer;
}
#endif

- (void)dealloc
{
    SGPLGLContextSetCurrentContext(nil);
    SGPlayerLog(@"%@ release", self.class);
}

- (SGGLProgram *)program {return nil;}

- (void)setupProgram {}
- (void)setupSubClass {}
- (BOOL)updateTextureAspect:(CGFloat *)aspect {return NO;}
- (void)cleanTexture {}
- (SGPLFImage *)imageFromPixelBuffer {return nil;}

@end
