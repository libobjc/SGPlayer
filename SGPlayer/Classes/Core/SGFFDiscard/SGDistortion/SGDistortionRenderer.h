//
//  SGDistortionRenderer.h
//  SGTextureTest
//
//  Created by Single on 26/12/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface SGDistortionRenderer : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)distortionRenderer;
- (instancetype)initWithViewportSize:(CGSize)viewportSize;

@property (nonatomic, assign) CGSize viewportSize;

- (void)beforDrawFrame;
- (void)afterDrawFrame;

@end
