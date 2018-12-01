//
//  SGFFmpeg.h
//  SGPlayer
//
//  Created by Single on 2018/8/2.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#import "avformat.h"
#import "imgutils.h"
#import "swresample.h"
#import "swscale.h"
#pragma clang diagnostic pop

void SGFFmpegSetupIfNeeded(void);
