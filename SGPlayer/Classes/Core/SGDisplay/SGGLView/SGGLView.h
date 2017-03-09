//
//  SGGLView.h
//  SGPlayer
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <SGPlatform/SGPlatform.h>
#import "SGGLProgram.h"
#import "SGDisplayView.h"

@interface SGGLView : SGPLFGLView

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

+ (instancetype)viewWithDisplayView:(SGDisplayView *)displayView;

@property (nonatomic, weak, readonly) SGDisplayView * displayView;

- (void)reloadViewport;

- (void)displayAsyncOnMainThread;
- (void)cleanEmptyBuffer;

- (SGPLFImage *)customSnapshot;

#pragma mark - subclass override

- (SGGLProgram *)program;

- (void)setupProgram;
- (void)setupSubClass;
- (BOOL)updateTextureAspect:(CGFloat *)aspect;
- (void)cleanTexture;
- (SGPLFImage *)imageFromPixelBuffer;

@end
