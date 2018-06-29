//
//  SGFFVideoPlaybackOutput.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFOutput.h"
#import "SGPlatform.h"

@interface SGFFVideoPlaybackOutput : NSObject <SGFFOutput>

@property (nonatomic, strong, readonly) SGPLFView * view;

@property (nonatomic, assign) SGDisplayMode mode;       // Default is SGDisplayModePlane.

@end
