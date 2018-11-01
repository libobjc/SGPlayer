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

@property (nonatomic, strong) SGPLFView * view;
@property (nonatomic, assign) SGScalingMode scalingMode;
@property (nonatomic, assign) SGDisplayMode displayMode;
@property (nonatomic, strong) SGVRViewport * viewport;
@property (nonatomic, assign) CMTime displayInterval;
@property (nonatomic, copy) BOOL (^discardFilter)(CMSampleTimingInfo timingInfo, NSUInteger index);
@property (nonatomic, copy) void (^renderCallback)(SGVideoFrame * frame);

- (UIImage *)originalImage;
- (UIImage *)snapshot;

@end
