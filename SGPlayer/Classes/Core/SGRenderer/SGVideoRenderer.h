//
//  SGVideoRenderer.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGVideoFrame.h"
#import "SGVRViewport.h"
#import "SGPlatform.h"

@interface SGVideoRenderer : NSObject

@property (nonatomic, strong) SGPLFView * view;             // Main thread only.
@property (nonatomic, strong) SGVRViewport * viewport;      // Main thread only.
@property (nonatomic, assign) SGScalingMode scalingMode;    // Main thread only.
@property (nonatomic, assign) SGDisplayMode displayMode;    // Main thread only.
@property (nonatomic, assign) CMTime displayInterval;       // Main thread only.

- (UIImage *)originalImage;     // Main thread only.
- (UIImage *)snapshot;          // Main thread only.

@end
