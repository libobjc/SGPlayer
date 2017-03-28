//
//  SGFFVideoToolBox.h
//  SGPlayer
//
//  Created by Single on 2017/2/21.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import "avformat.h"

@interface SGFFVideoToolBox : NSObject

+ (instancetype)videoToolBoxWithCodecContext:(AVCodecContext *)codecContext;

- (BOOL)sendPacket:(AVPacket)packet needFlush:(BOOL *)needFlush;
- (CVImageBufferRef)imageBuffer;

- (BOOL)trySetupVTSession;
- (void)flush;

@end
