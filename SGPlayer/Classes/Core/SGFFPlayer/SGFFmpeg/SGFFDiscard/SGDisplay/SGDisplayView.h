//
//  SGDisplayView.h
//  SGPlayer
//
//  Created by Single on 12/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "SGPlayerImp.h"
#import "SGFFPlayer.h"

@class SGFingerRotation;
@class SGGLFrame;

@interface SGDisplayView : SGPLFView


//+ (instancetype)new NS_UNAVAILABLE;
//- (instancetype)init NS_UNAVAILABLE;
//- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
//
//+ (instancetype)displayViewWithAbstractPlayer:(SGPlayer *)abstractPlayer;
//
//
@property (nonatomic, weak, readonly) SGPlayer * abstractPlayer;
@property (nonatomic, strong, readonly) SGFingerRotation * fingerRotation;
//
//- (void)playerOutputTypeFF;
//
//
//// reload
//- (void)reloadGravityMode;
//- (void)reloadPlayerConfig;
- (void)reloadVideoFrameForGLFrame:(SGGLFrame *)glFrame;
//
//- (SGPLFImage *)snapshot;

@end
