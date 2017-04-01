//
//  PlayerViewController.h
//  demo-macos
//
//  Created by Single on 2017/3/15.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSUInteger, DemoType) {
    DemoType_AVPlayer_Normal = 0,
    DemoType_AVPlayer_VR,
    DemoType_FFmpeg_Normal,
    DemoType_FFmpeg_VR,
};

@interface PlayerViewController : NSViewController

@property (nonatomic, assign) DemoType demoType;

- (void)setup;

@end
